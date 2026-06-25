#!/bin/bash
# Validate Dell TOSCA blueprint and changelog files before commit.
#
# Supports the multi-blueprint Dell layout: a top-level orchestrator
# blueprint, helm-based component blueprints, and utility blueprints
# (input validator, stack verifier).  Each blueprint type has different
# expected node templates, so the helm-chain check only applies to
# blueprints whose blueprint_labels.obj-type is "helm".

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d ./blueprints ]]; then
  echo "No blueprints/ directory found."
  exit 0
fi

python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except Exception:
    print("ERROR: Missing dependency: PyYAML (pip install pyyaml)")
    sys.exit(1)

root = Path('.').resolve()
bp_dir = root / 'blueprints'

blueprint_files = sorted(bp_dir.rglob('blueprint.yaml')) if bp_dir.is_dir() else []
changelogs = sorted(bp_dir.rglob('CHANGELOG.yaml')) if bp_dir.is_dir() else []

errors = []
warnings = []


def check_ascii(path: Path):
    """DAP rejects any character outside ASCII when uploading
    blueprints ('illegal characters / Only valid ascii chars are
    supported').  Surface the offending file + line so authors do not
    discover it only at upload time.
    """
    try:
        raw = path.read_bytes()
    except OSError as e:
        errors.append(f"{rel(path)}: cannot read file: {e}")
        return
    try:
        raw.decode('ascii')
        return
    except UnicodeDecodeError:
        pass
    text = raw.decode('utf-8', errors='replace')
    for ln, line in enumerate(text.splitlines(), 1):
        for col, ch in enumerate(line, 1):
            if ord(ch) > 127:
                errors.append(
                    f"{rel(path)}:{ln}:{col}: non-ASCII char "
                    f"U+{ord(ch):04X} ({ch!r}) - DAP rejects "
                    f"non-ASCII characters in blueprint sources"
                )
                return


for path in bp_dir.rglob('*'):
    if path.is_file() and path.suffix in ('.yaml', '.yml', '.py'):
        check_ascii(path)

semver_re = re.compile(r'^\d+\.\d+\.\d+$')
snake_case_re = re.compile(r'^[a-z][a-z0-9_]*$')


def rel(p: Path) -> str:
    return str(p.relative_to(root))


def load_yaml(path: Path):
    try:
        with path.open() as f:
            return yaml.safe_load(f)
    except Exception as e:
        errors.append(f"{rel(path)}: YAML parse error: {e}")
        return None


def deep_merge(base: dict, overlay: dict) -> dict:
    for key, val in overlay.items():
        if key in base and isinstance(base[key], dict) and isinstance(val, dict):
            deep_merge(base[key], val)
        elif key in base and isinstance(base[key], list) and isinstance(val, list):
            base[key].extend(val)
        else:
            base[key] = val
    return base


def resolve_imports(bp_path: Path, data: dict) -> dict:
    imports = data.get('imports', [])
    if not isinstance(imports, list):
        return data
    for imp in imports:
        if not isinstance(imp, str):
            continue
        if imp.startswith('dell/') or imp.startswith('plugin:'):
            continue
        imp_path = bp_path.parent / imp
        if imp_path.is_file():
            imp_data = load_yaml(imp_path)
            if isinstance(imp_data, dict):
                deep_merge(data, imp_data)
    return data


def expect(condition, msg):
    if not condition:
        errors.append(msg)


def get_blueprint_kind(data: dict) -> str:
    """Return 'helm', 'kubernetes', or 'environment' (top-level / utility)."""
    bp_labels = data.get('blueprint_labels', {}) or {}
    obj_type = bp_labels.get('obj-type', {}) or {}
    values = obj_type.get('values') if isinstance(obj_type, dict) else None
    if isinstance(values, list) and values:
        return str(values[0])
    return 'unknown'


def is_orchestrator(data: dict) -> bool:
    """A blueprint is an orchestrator iff it composes other blueprints via
    dell.nodes.ServiceComponent.  Only orchestrator inputs back a DAP UI
    form; child blueprints receive their values via get_input from the
    parent and DAP forbids constraints on those (you get: 'Input value
    {"get_input": "..."} cannot contain an intrinsic function and also
    have constraints.' at create_deployment_environment time).
    """
    nodes = data.get('node_templates', {}) or {}
    if not isinstance(nodes, dict):
        return False
    for tmpl in nodes.values():
        if isinstance(tmpl, dict) and tmpl.get('type') == 'dell.nodes.ServiceComponent':
            return True
    return False


for bp in blueprint_files:
    data = load_yaml(bp)
    if not isinstance(data, dict):
        continue

    data = resolve_imports(bp, data)

    expect(data.get('tosca_definitions_version') == 'dell_1_1',
           f"{rel(bp)}: tosca_definitions_version must be dell_1_1")

    imports = data.get('imports')
    expect(isinstance(imports, list), f"{rel(bp)}: imports must be a list")
    if isinstance(imports, list):
        expect('dell/types/types.yaml' in imports,
               f"{rel(bp)}: imports must include dell/types/types.yaml")

    kind = get_blueprint_kind(data)
    orchestrator = is_orchestrator(data)

    inputs = data.get('inputs', {})
    expect(isinstance(inputs, dict), f"{rel(bp)}: inputs must be a map")
    if isinstance(inputs, dict):
        for name, meta in inputs.items():
            if not snake_case_re.match(name):
                errors.append(f"{rel(bp)}: input '{name}' must be snake_case")
            if not isinstance(meta, dict):
                errors.append(f"{rel(bp)}: input '{name}' must be a map")
                continue
            for key in ('type', 'hidden', 'allow_update', 'display_label', 'description'):
                if key not in meta:
                    errors.append(f"{rel(bp)}: input '{name}' missing '{key}'")

            constraints = meta.get('constraints', [])
            input_type = meta.get('type', '')
            # Only require constraints on the orchestrator's user-facing
            # inputs.  Child blueprints receive values via get_input from
            # the parent ServiceComponent; DAP rejects child inputs that
            # have BOTH an intrinsic-function value AND constraints.
            if (
                orchestrator
                and input_type not in ('dict', 'list', 'deployment_id')
                and (not isinstance(constraints, list) or len(constraints) == 0)
            ):
                errors.append(f"{rel(bp)}: input '{name}' must have at least one constraint")
            elif not orchestrator and isinstance(constraints, list) and constraints:
                errors.append(
                    f"{rel(bp)}: input '{name}' must NOT have constraints "
                    f"(child blueprints receive values via get_input; "
                    f"DAP forbids constraints on intrinsic-function values)"
                )

            # Child blueprints must not declare type: secret_key because
            # the orchestrator passes values via get_input, and at child
            # deployment-plan creation time DAP validates the value
            # against the declared type before resolving the intrinsic.
            # The literal {'get_input': '...'} dict fails the secret_key
            # type check.  Keep secret_key only on the orchestrator's
            # user-facing form; children take type: string (the secret
            # key name) and resolve via get_secret themselves.
            if not orchestrator and input_type == 'secret_key':
                errors.append(
                    f"{rel(bp)}: input '{name}' must NOT be type "
                    f"'secret_key' in a child blueprint (use 'string'; "
                    f"DAP rejects get_input values against secret_key "
                    f"type at create_deployment_environment time)"
                )

            # Child blueprints must not use 'only_with' for the same
            # reason: the orchestrator always passes the input via
            # get_input (resolving to the orchestrator-side default if
            # the user did not touch the field), and DAP's
            # _check_inputs_onlywith evaluates the gate against the
            # resolved value, raising OnlyWithInputError when the gate
            # condition is not met.  Form-level conditional visibility
            # belongs on the orchestrator's user-facing inputs only.
            if not orchestrator and 'only_with' in meta:
                errors.append(
                    f"{rel(bp)}: input '{name}' must NOT use 'only_with' "
                    f"in a child blueprint (form-level gating belongs on "
                    f"the orchestrator; DAP raises OnlyWithInputError at "
                    f"create_deployment_environment time when the parent "
                    f"passes a get_input value that does not satisfy the "
                    f"gate)"
                )
            else:
                if isinstance(constraints, list) and constraints:
                    has_validation_rule = False
                    for c in constraints:
                        if isinstance(c, dict) and (
                            'pattern' in c
                            or 'valid_values' in c
                            or 'in_range' in c
                            or 'type' in c
                        ):
                            has_validation_rule = True
                            if 'error_message' not in c:
                                errors.append(
                                    f"{rel(bp)}: input '{name}' constraint missing error_message"
                                )
                    if input_type not in ('dict', 'list', 'deployment_id') and not has_validation_rule:
                        warnings.append(
                            f"{rel(bp)}: input '{name}' has constraints but no "
                            f"pattern/valid_values/in_range/type validation rule"
                        )
                    # Dell IN-007: integer inputs should use in_range, not valid_values.
                    if input_type == 'integer':
                        for c in constraints:
                            if isinstance(c, dict) and 'valid_values' in c:
                                warnings.append(
                                    f"{rel(bp)}: integer input '{name}' should use "
                                    f"'in_range' instead of 'valid_values' (Dell IN-007)"
                                )

            if orchestrator and name == 'chart_version':
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == r'^\d+\.\d+\.\d+$':
                        ok = True
                if not ok:
                    errors.append(
                        f"{rel(bp)}: chart_version must enforce semver pattern ^\\d+\\.\\d+\\.\\d+$"
                    )

            if orchestrator and name == 'namespace':
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == r'^[a-z0-9][a-z0-9\-]{0,62}$':
                        ok = True
                if not ok:
                    errors.append(
                        f"{rel(bp)}: namespace should use pattern ^[a-z0-9][a-z0-9\\-]{{0,62}}$"
                    )

    groups = data.get('input_groups', {})
    if isinstance(groups, dict) and isinstance(inputs, dict) and groups:
        grouped = []
        group_indexes = []
        for gname, gmeta in groups.items():
            if not isinstance(gmeta, dict):
                errors.append(f"{rel(bp)}: input_groups.{gname} must be a map")
                continue
            for req in ('display_label', 'collapsible', 'index', 'inputs'):
                if req not in gmeta:
                    errors.append(f"{rel(bp)}: input_groups.{gname} missing '{req}'")
            if 'index' in gmeta and isinstance(gmeta['index'], int):
                group_indexes.append(gmeta['index'])
            ilist = gmeta.get('inputs', [])
            if isinstance(ilist, list):
                grouped.extend(ilist)

        # Visible inputs (not hidden) should be grouped.  Hidden inputs
        # never need to appear in input_groups.
        visible_inputs = {
            name for name, meta in inputs.items()
            if isinstance(meta, dict) and not meta.get('hidden', False)
        }
        missing = sorted(visible_inputs - set(grouped))
        unknown = sorted(set(grouped) - set(inputs.keys()))
        duplicates = sorted({i for i in grouped if grouped.count(i) > 1})
        if missing:
            errors.append(f"{rel(bp)}: visible inputs missing from input_groups: {', '.join(missing)}")
        if unknown:
            errors.append(f"{rel(bp)}: input_groups contains unknown inputs: {', '.join(unknown)}")
        if duplicates:
            errors.append(f"{rel(bp)}: inputs repeated across groups: {', '.join(duplicates)}")

        if group_indexes:
            expected = list(range(min(group_indexes), min(group_indexes) + len(group_indexes)))
            if sorted(group_indexes) != expected:
                warnings.append(f"{rel(bp)}: input group indexes are not contiguous")

    node_templates = data.get('node_templates', {})
    if not isinstance(node_templates, dict):
        if kind != 'environment':
            errors.append(f"{rel(bp)}: node_templates must be a map")
    else:
        # Helm chain check only applies to helm-typed blueprints.
        if kind == 'helm':
            has_binary = False
            has_repo = False
            has_release = False
            has_namespace_node = False
            for _, nmeta in node_templates.items():
                if not isinstance(nmeta, dict):
                    continue
                ntype = nmeta.get('type')
                if ntype == 'dell.nodes.helm.Binary':
                    has_binary = True
                if ntype == 'dell.nodes.helm.Repo':
                    has_repo = True
                if ntype == 'dell.nodes.kubernetes.resources.Namespace':
                    has_namespace_node = True
                if ntype == 'dell.nodes.helm.Release':
                    has_release = True
                    props = nmeta.get('properties', {})
                    client = props.get('client_config', {})
                    # client_config must come from an intrinsic so the
                    # cluster connection is not hardcoded. Accept either
                    # get_secret (legacy direct fetch) or get_attribute
                    # (current pattern: a precreate parse_k8s_secret node
                    # normalises the secret and exposes k8s_client_config).
                    if not (isinstance(client, dict) and (
                        'get_secret' in client or 'get_attribute' in client
                    )):
                        errors.append(
                            f"{rel(bp)}: helm release client_config must "
                            f"use get_secret or get_attribute (e.g. "
                            f"{{get_attribute: [fetch_k8s_config_secret, "
                            f"k8s_client_config]}})"
                        )
                    if props.get('rollback') is not False:
                        warnings.append(
                            f"{rel(bp)}: helm release should set 'rollback: false' for easier debugging"
                        )
                    rcfg = props.get('resource_config', {})
                    flags = rcfg.get('flags', []) if isinstance(rcfg, dict) else []
                    flag_names = [f.get('name') for f in flags if isinstance(f, dict)]
                    if 'namespace' not in flag_names:
                        errors.append(f"{rel(bp)}: helm release flags must include namespace")
                    # The 'create-namespace' helm flag must NOT be used: the
                    # helm plugin reuses install flags for 'helm uninstall',
                    # which rejects --create-namespace ("unknown flag") and
                    # breaks teardown. Create the namespace via a dedicated
                    # dell.nodes.kubernetes.resources.Namespace node instead.
                    if 'create-namespace' in flag_names:
                        errors.append(
                            f"{rel(bp)}: helm release flags must NOT include "
                            f"create-namespace (helm uninstall rejects it); "
                            f"use a dell.nodes.kubernetes.resources.Namespace "
                            f"node instead"
                        )
                    if 'version' not in flag_names:
                        errors.append(f"{rel(bp)}: helm release flags must include version")
            if not has_binary:
                errors.append(f"{rel(bp)}: missing dell.nodes.helm.Binary node")
            if not has_repo:
                errors.append(f"{rel(bp)}: missing dell.nodes.helm.Repo node")
            if not has_release:
                errors.append(f"{rel(bp)}: missing dell.nodes.helm.Release node")
            if not has_namespace_node:
                errors.append(
                    f"{rel(bp)}: missing dell.nodes.kubernetes.resources.Namespace "
                    f"node (helm blueprints must create the namespace via a "
                    f"dedicated node so 'helm uninstall' works without the "
                    f"create-namespace flag)"
                )

        # Top-level orchestrators must have at least one ServiceComponent.
        if kind == 'environment' and 'top_level' in str(bp):
            has_sc = any(
                isinstance(n, dict) and n.get('type') == 'dell.nodes.ServiceComponent'
                for n in node_templates.values()
            )
            if not has_sc:
                errors.append(f"{rel(bp)}: top-level orchestrator must declare at least one dell.nodes.ServiceComponent")

        # Every ServiceComponent must use a stable deterministic
        # deployment id (concat of {get_sys: [deployment, id]} + suffix)
        # and must NOT set auto_inc_suffix.  Without a stable id, a
        # failed install leaves a fresh orphan child deployment on every
        # retry because the suffix counter increments and DAP cleanup
        # only runs from a successful uninstall.
        for nname, nmeta in node_templates.items():
            if not isinstance(nmeta, dict):
                continue
            if nmeta.get('type') != 'dell.nodes.ServiceComponent':
                continue
            rc = nmeta.get('properties', {}).get('resource_config', {})
            dep = rc.get('deployment', {}) if isinstance(rc, dict) else {}
            if not isinstance(dep, dict):
                continue
            if dep.get('auto_inc_suffix'):
                errors.append(
                    f"{rel(bp)}: ServiceComponent '{nname}' must NOT set "
                    f"auto_inc_suffix: true (use a stable deterministic "
                    f"deployment id instead so retries reuse the same "
                    f"child deployment row rather than minting orphans)"
                )
            if 'id' not in dep:
                errors.append(
                    f"{rel(bp)}: ServiceComponent '{nname}' must declare "
                    f"resource_config.deployment.id as concat of "
                    f"{{get_sys: [deployment, id]}} + a static suffix"
                )

    labels = data.get('labels', {})
    blueprint_labels = data.get('blueprint_labels', {})
    if 'csys-obj-type' not in labels:
        errors.append(f"{rel(bp)}: labels must include csys-obj-type")
    if 'env' not in blueprint_labels:
        errors.append(f"{rel(bp)}: blueprint_labels must include env")
    # Non-orchestrator (utility) blueprints carry csys-blueprint-type so the
    # catalog can distinguish them from the top-level solution/orchestrator
    # blueprint (which only sets env).
    if not orchestrator and 'csys-blueprint-type' not in blueprint_labels:
        errors.append(
            f"{rel(bp)}: blueprint_labels must include csys-blueprint-type "
            f"(e.g. 'utility') for non-orchestrator blueprints"
        )

for ch in changelogs:
    data = load_yaml(ch)
    if not isinstance(data, dict):
        continue

    expect(data.get('tosca_definitions_version') == 'dell_1_1',
           f"{rel(ch)}: tosca_definitions_version must be dell_1_1")

    imports = data.get('imports')
    expect(isinstance(imports, list), f"{rel(ch)}: imports must be a list")
    if isinstance(imports, list):
        expect('dell/types/types.yaml' in imports,
               f"{rel(ch)}: imports must include dell/types/types.yaml")

    changelog = data.get('dsl_definitions', {}).get('changelog', {})
    if not isinstance(changelog, dict) or not changelog:
        errors.append(f"{rel(ch)}: dsl_definitions.changelog must be a non-empty map")
    else:
        for version, entries in changelog.items():
            if not semver_re.match(str(version)):
                errors.append(f"{rel(ch)}: changelog version '{version}' is not semver")
            if not isinstance(entries, list) or not entries:
                errors.append(f"{rel(ch)}: changelog {version} must be a non-empty list")
                continue
            for idx, item in enumerate(entries):
                if not isinstance(item, dict):
                    errors.append(f"{rel(ch)}: changelog {version}[{idx}] must be a map")
                    continue
                for key in ('description',):
                    if key not in item:
                        errors.append(f"{rel(ch)}: changelog {version}[{idx}] missing '{key}'")

if errors:
    print('Validation FAILED')
    for e in errors:
        print(f'- {e}')
    if warnings:
        print('Warnings:')
        for w in warnings:
            print(f'- {w}')
    sys.exit(1)

print('Validation PASSED')
if warnings:
    print('Warnings:')
    for w in warnings:
        print(f'- {w}')
PY
