#!/bin/bash
# Validate Dell TOSCA blueprint and changelog files before commit.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BLUEPRINT_FILES=()
while IFS= read -r -d '' f; do BLUEPRINT_FILES+=("$f"); done < <(find ./blueprints -type f -name "blueprint.yaml" -print0 2>/dev/null | sort -z)
CHANGELOG_FILES=()
while IFS= read -r -d '' f; do CHANGELOG_FILES+=("$f"); done < <(find ./blueprints -type f -name "CHANGELOG.yaml" -print0 2>/dev/null | sort -z)

if [[ ${#BLUEPRINT_FILES[@]} -eq 0 ]]; then
  echo "No blueprint.yaml files found."
  exit 0
fi

if [[ ${#CHANGELOG_FILES[@]} -eq 0 ]]; then
  echo "No CHANGELOG.yaml files found."
  exit 1
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
blueprints = sorted(bp_dir.rglob('blueprint.yaml')) if bp_dir.is_dir() else []
changelogs = sorted(bp_dir.rglob('CHANGELOG.yaml')) if bp_dir.is_dir() else []

errors = []
warnings = []

semver_re = re.compile(r'^\d+\.\d+\.\d+$')
snake_case_re = re.compile(r'^[a-z][a-z0-9_]*$')
namespace_re = re.compile(r'^[a-z0-9][a-z0-9\-]{0,62}$')
k8s_name_re = re.compile(r'^[a-z0-9][a-z0-9\-]*$')
secret_data_key_re = re.compile(r'^[a-zA-Z0-9._\-]+$')

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
    """Merge overlay into base, combining dicts and extending lists."""
    for key, val in overlay.items():
        if key in base and isinstance(base[key], dict) and isinstance(val, dict):
            deep_merge(base[key], val)
        elif key in base and isinstance(base[key], list) and isinstance(val, list):
            base[key].extend(val)
        else:
            base[key] = val
    return base


def resolve_imports(bp_path: Path, data: dict) -> dict:
    """Follow local YAML imports and merge them into the blueprint data."""
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


for bp in blueprints:
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
            if input_type not in ('dict', 'list') and (not isinstance(constraints, list) or len(constraints) == 0):
                errors.append(f"{rel(bp)}: input '{name}' must have at least one constraint")
            else:
                has_validation_rule = False
                for c in constraints:
                    if isinstance(c, dict) and ('pattern' in c or 'valid_values' in c or 'type' in c):
                        has_validation_rule = True
                        if 'error_message' not in c:
                            errors.append(f"{rel(bp)}: input '{name}' constraint missing error_message")
                if not has_validation_rule:
                    warnings.append(f"{rel(bp)}: input '{name}' has constraints but no pattern/valid_values/type validation rule")

            if name == 'chart_version':
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == '^\\d+\\.\\d+\\.\\d+$':
                        ok = True
                if not ok:
                    errors.append(f"{rel(bp)}: chart_version must enforce semver pattern ^\\d+\\.\\d+\\.\\d+$")

            if name == 'namespace':
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == '^[a-z0-9][a-z0-9\\-]{0,62}$':
                        ok = True
                if not ok:
                    errors.append(f"{rel(bp)}: namespace should use pattern ^[a-z0-9][a-z0-9\\-]{0,62}$")

            if name.endswith('_secret_name'):
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == '^[a-z0-9][a-z0-9\\-]*$':
                        ok = True
                if not ok:
                    warnings.append(f"{rel(bp)}: {name} should use k8s secret name pattern ^[a-z0-9][a-z0-9\\-]*$")

            if name.endswith('_secret_data_key'):
                ok = False
                for c in constraints:
                    if isinstance(c, dict) and c.get('pattern') == '^[a-zA-Z0-9._\\-]+$':
                        ok = True
                if not ok:
                    errors.append(f"{rel(bp)}: {name} should use secret data key pattern ^[a-zA-Z0-9._\\-]+$")

    groups = data.get('input_groups', {})
    expect(isinstance(groups, dict), f"{rel(bp)}: input_groups must be a map")
    if isinstance(groups, dict) and isinstance(inputs, dict):
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

        missing = sorted(set(inputs.keys()) - set(grouped))
        unknown = sorted(set(grouped) - set(inputs.keys()))
        duplicates = sorted({i for i in grouped if grouped.count(i) > 1})
        if missing:
            errors.append(f"{rel(bp)}: inputs missing from input_groups: {', '.join(missing)}")
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
        errors.append(f"{rel(bp)}: node_templates must be a map")
    else:
        has_binary = False
        has_repo = False
        has_release = False
        for _, nmeta in node_templates.items():
            if not isinstance(nmeta, dict):
                continue
            ntype = nmeta.get('type')
            if ntype == 'dell.nodes.helm.Binary':
                has_binary = True
            if ntype == 'dell.nodes.helm.Repo':
                has_repo = True
            if ntype == 'dell.nodes.helm.Release':
                has_release = True
                props = nmeta.get('properties', {})
                client = props.get('client_config', {})
                if not (isinstance(client, dict) and 'get_secret' in client):
                    errors.append(f"{rel(bp)}: helm release client_config must use get_secret")
                rcfg = props.get('resource_config', {})
                flags = rcfg.get('flags', []) if isinstance(rcfg, dict) else []
                flag_names = [f.get('name') for f in flags if isinstance(f, dict)]
                if 'namespace' not in flag_names:
                    errors.append(f"{rel(bp)}: helm release flags must include namespace")
                if 'create-namespace' not in flag_names:
                    errors.append(f"{rel(bp)}: helm release flags must include create-namespace")
                if 'version' not in flag_names:
                    errors.append(f"{rel(bp)}: helm release flags must include version")

        if not has_binary:
            errors.append(f"{rel(bp)}: missing dell.nodes.helm.Binary node")
        if not has_repo:
            errors.append(f"{rel(bp)}: missing dell.nodes.helm.Repo node")
        if not has_release:
            errors.append(f"{rel(bp)}: missing dell.nodes.helm.Release node")

    labels = data.get('labels', {})
    blueprint_labels = data.get('blueprint_labels', {})
    if 'csys-obj-type' not in labels:
        errors.append(f"{rel(bp)}: labels must include csys-obj-type")
    if 'obj-type' not in blueprint_labels or 'csys-obj-type' not in blueprint_labels:
        errors.append(f"{rel(bp)}: blueprint_labels must include obj-type and csys-obj-type")

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
                for key in ('ticket', 'developer', 'description'):
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
