---
name: dap
description: >-
  Use when the user says "write a blueprint", "fix my blueprint", "create a deployment",
  "what node type", "how do I deploy", "blueprint won't validate", "lint this", "review this yaml",
  "add an input", "which plugin", "help me with TOSCA", "add update support", "support deployment update",
  "support drift", "add check_drift", "add reinstall", "make this updatable", "day 2", "babysit",
  "monitor", "did it pass", "did it fail", "last run", "any failures", "check status",
  "how to", "tutorial", "guide", "help me get started", "walk me through", "what are plugins",
  "how do I delete", "how do I create secret",
  or any request to write, review, debug, test, or get step-by-step help with blueprint YAML or DAP workflows.
  Also known as "Blueprint Assist" — triggers on "blueprint assist", "blueprint-assist", or "Blueprint Assist".
---

# Blueprint Assist — Dell Automation Platform

This skill provides a blueprint authoring reference distilled from the official Blueprint Developer's Guide (Feb 2026, Rev A01), plus CLI access to the Dell Automation Platform via the `dap-bpa` command.

## Reference Files

Detailed reference material is in the `references/` directory:

| File | Content |
|---|---|
| `rules/blueprint-rules.md` (Windsurf Rule) | **God-level rules** — mandatory best practices, loaded automatically via `activation: model_decision` |
| `references/input-reference.md` | Detailed input, constraint, secret_key, input_groups, and data type reference with examples |
| `references/blueprint-examples.md` | Complete blueprint template, multi-file patterns (basic split, layered split), decision guide |
| `references/migration-guide.md` | Cloudify / NativeEdge → DAP migration tables and post-migration checklist |
| `references/troubleshooting.md` | Failed deployment diagnosis, upload error reference, common runtime errors |
| `references/guides.md` | Step-by-step workflow guides — write blueprint, create deployment, manage secrets, plugins, delete resources |
| `references/isv-onboarding-workflow.md` | Post-generation ISV onboarding — guided path from blueprint to upload, secrets, deploy, and monitor |

## Routing — how-to / tutorial / workflow guide requests

If the user asks "how to", "walk me through", "guide me", "help me get started", or requests a step-by-step tutorial for any DAP workflow (writing blueprints, creating deployments, managing secrets, using plugins, deleting resources), **load `references/guides.md`** and follow its response guidelines.

---

## Routing — update / Day-2 / drift requests

If the user asks to add or support **update**, **Day-2 operations**, **drift checking**, or **reinstall** on a blueprint (e.g. *"add update support"*, *"make this updatable"*, *"add check_drift"*, *"support deployment update"*), **first load `packages/skills/dap-deployment-update/SKILL.md`** and follow its ND-009 authoring checklist before emitting YAML. A blueprint with `update` declared but no `check_drift` is incomplete — see ND-009 in `blueprint-rules.md`.

---

## Routing — post-generation ISV onboarding

After blueprint lint passes, if the user has not yet uploaded or deployed the blueprint, **load `references/isv-onboarding-workflow.md`** and ask: "Would you like me to guide you through uploading and testing this blueprint in DAP?"

---

## Runtime Mode

You are running in IDE mode with shell access.
Use the `dap-bpa` CLI for BPA operations.
Do not use the function interface unless explicitly instructed by the host.

### Runtime-Specific References

| File | Content |
|---|---|
| `references/cli-commands.md` | Full CLI reference — all commands, flags, fields |

### Invocation Reference

Full CLI reference: `references/cli-commands.md`.

### Invocation Examples

```bash
dap-bpa knowledge blueprints find "<query>"
dap-bpa blueprint lint --file blueprint.yaml --verify
dap-bpa blueprint validate-all --file blueprint.yaml
```

### Plugin Lookup

When the user asks about a specific plugin (e.g. AWS, Kubernetes, Helm), retrieve plugin details on-demand via the CLI — no separate skill needed:

```bash
dap-bpa knowledge plugins list <plugin>        # List all node types for a plugin
dap-bpa knowledge plugins get <plugin> <type>  # Get node type properties
dap-bpa knowledge plugins docs <plugin>        # Plugin overview, auth, patterns
dap-bpa knowledge docs search "<query>" --plugin <name>  # Search plugin docs
```

Available plugins: ansible, aws, azure, docker, fabric, helm, hzp-edge, kubernetes, libvirt, openstack, redfish, storage, terraform, terragrunt, utilities, vcloud, vsphere.

---

## Routing — DSL migration / conversion requests

If the user asks to **migrate**, **convert**, **translate**, or **change the DSL version** of a blueprint (e.g. *"convert this from nativeedge_1_0 to dell_1_1"*, *"migrate this blueprint to Dell DSL"*, *"generate a new blueprint based on dell_1_1 dsl with the same structure"*, *"change DSL version"*), **load `references/migration-guide.md`** instead of the standard `blueprint-rules.md`.

**Key indicators for migration:**
- User mentions both a source DSL (nativeedge, cloudify, dell_1_0) and a target DSL (dell_1_1)
- User asks to "keep the same structure" or "preserve the structure"
- User uses verbs: migrate, convert, translate, change DSL, port, upgrade
- User says "generate based on X dsl" or "built on X dsl"

**These are NOT migration requests (use standard workflow):**
- User asks to generate a new blueprint from scratch
- User asks to improve or refactor an existing blueprint without DSL version change
- User asks to add features or functionality to an existing blueprint
- User asks to "change" or "update" a blueprint without mentioning DSL version
- User asks to "upgrade" dependencies or plugins without DSL version change

**Migration workflow:**
1. Load `references/migration-guide.md`
2. Read the original blueprint
3. Apply the migration rules first (DSL version, prefix replacement, NE-only property removal, import rename)
4. Preserve the original input structure, file structure, and node organization
5. After migration is complete, run the standard lint step (Step 7) — ND-003, IN-007, and other blueprint-rules.md compliance checks still apply to the migrated output
6. Inform the user the migration and lint are complete

---

## Blueprint Generation Process

Follow these 8 steps in order. All blueprints must comply with the mandatory rules in `blueprint-rules.md`.

Skip steps 3 and 4 only when the user explicitly says "skip planning" or "just do it".

### 1. Combined search

Start with a broad search to find relevant docs, plugins, and examples:

```bash
dap-bpa knowledge search "<query>"
```

If `dap-bpa knowledge search` is not available, fan out manually:

```bash
dap-bpa knowledge docs search "<query>"
dap-bpa knowledge blueprints find "<query>"
```

### 2. Targeted research

Drill into specifics with focused commands. Do NOT write YAML until all lookups are complete.

```bash
dap-bpa knowledge docs search "<query>"
dap-bpa knowledge plugins docs <plugin>
dap-bpa knowledge plugins get <plugin> <node_type>
dap-bpa knowledge blueprints find "<description>"
dap-bpa knowledge blueprints get <id> --include-files
```

### 3. Propose

Before doing ANY work, present a plan describing:
- Single-file or multi-file structure
- Plugins required and node types to use
- Number of files and key design decisions

### 4. Get user approval

Wait for explicit user confirmation. Ask for target directory. Do NOT proceed without confirmation.

### 5. Look up node types

Run `dap-bpa knowledge plugins get <plugin> <node_type>` for **every** node type in the approved plan. This retrieves the exact properties, required fields, and defaults.

### 6. Build the blueprint

Write YAML using the looked-up properties. Comply with all mandatory rules from `blueprint-rules.md`:

- **Always multi-file**: blueprint.yaml, inputs.yaml, capabilities.yaml (BS-010)
- **Use `dell.*` prefix**, NOT `cloudify.*` or `nativeedge.*` (TD-002)
- **Use `capabilities:`**, NOT `outputs:` (CP-001)
- **Secrets**: Use `type: secret_key`, never literal passwords (SC-001, SC-002)
- **CHANGELOG.yaml** is mandatory (BS-009)
- **No inline code** (ND-005). For custom Python operations, load the dap-scripts skill.

### 7. Lint

**CRITICAL:** Run the linter BEFORE validation. Do NOT run validation commands until linting passes.

```bash
dap-bpa blueprint lint --file blueprint.yaml --verify
```

After generating the blueprint, run the linter. Fix all errors and re-lint until errorsFound: false. Then review warnings — fix what you can, skip only if you have a clear technical reason.

Do NOT confuse this with `dap-bpa blueprint validate` — that checks plugin schemas, not `blueprint-rules.md` compliance.

### 8. Validate

After lint passes, validate node properties against plugin schemas:

```bash
dap-bpa blueprint validate-all --file blueprint.yaml
```

Fix any schema errors and re-validate until clean.

---

## Blueprint Authoring Reference

### TOSCA Structure

Every blueprint starts with:

```yaml
tosca_definitions_version: dell_1_1

imports:
  - dell/types/types.yaml
  - plugin:<plugin-name>?version= >=<major>.<minor>

description: >
  Purpose of this blueprint.
```

### Inputs (Summary)

Inputs define deployment-time parameters:

```yaml
inputs:
  vm_name:
    type: string
    display_label: VM Name
    description: Name for the virtual machine
    default: my-vm
    hidden: false
    allow_update: true
    display:
      group: vm_settings
    constraints:
      - pattern: '^[a-zA-Z][a-zA-Z0-9-]*$'
        error_message: Must start with a letter, alphanumeric and hyphens only.
```

#### Input Properties Reference

| Property | Type | Required | Description |
|---|---|---|---|
| `type` | string | Yes | `string`, `integer`, `float`, `boolean`, `list`, `dict`, `textarea`, `secret_key` (reference a DAP secret), `deployment_id` (reference another deployment by ID) |
| `display_label` | string | Yes | UI label (IN-004) |
| `description` | string | Yes | Tooltip text (IN-001) |
| `default` | varies | Rec. | Default value — empty string OK, `null` discouraged |
| `hidden` | bool | No | Hide from UI (default: `false`) |
| `allow_update` | bool | No | Allow change via deployment update (default: `true`) |
| `constraints` | list | No | Validation constraints |
| `only_with` | string | No | Show only when referenced boolean input is true |
| `display` | dict | Yes* | `group: <group-name>` — required for all non-hidden inputs; links the input to an `input_groups` entry. |
| `input_group` | — | — | Assigned via top-level `input_groups` section, not per-input |

#### Constraint Types

| Constraint | Example | Applies to |
|---|---|---|
| `valid_values: [a, b, c]` | Dropdown | All types |
| `pattern: '<regex>'` | Regex match | `string` |
| `min_length` / `max_length` | Length bounds | `string` |
| `in_range: [min, max]` | Numeric range | `integer`, `float` |
| `greater_than` / `less_than` | Numeric bounds | `integer`, `float` |

#### input_groups Structure

```yaml
input_groups:
  vm_settings:
    display_label: VM Settings
    index: 1
    collapsible: true
    inputs:
      - vm_name
      - vm_size
```

Valid keys: `display_label`, `index`, `collapsible`, `inputs`. The `inputs` list must exactly match names defined in `inputs:` — no extras, no typos. Every non-hidden input must appear in exactly one group.

### Node Templates

```yaml
node_templates:
  my_node:
    type: dell.nodes.<plugin>.<Type>
    properties:
      <property>: <value>
    interfaces:
      dell.interfaces.lifecycle:
        create:
          implementation: <plugin>.<module>.<function>
          inputs:
            <input>: <value>
    relationships:
      - type: dell.relationships.depends_on
        target: other_node
```

Lifecycle completeness (ND-003): Every node with `create` MUST define `delete`. Every node with `start` MUST define `stop`. Before writing lifecycle operations, load the full reference: `dap-bpa knowledge docs get general/lifecycle-operations`

Never invent node types. Only use types returned by `dap-bpa knowledge types get <type>` or `dap-bpa knowledge plugins list <plugin>`. If the type is not in the result, it does not exist.

### Relationships

| Relationship | Purpose |
|---|---|
| `dell.relationships.depends_on` | Ordering dependency (target created first) |
| `dell.relationships.connected_to` | Network/logical connection |
| `dell.relationships.contained_in` | Parent-child containment |

For plugin-specific relationship types, `run_on_host`, and decision guidance, see `knowledge/docs/general/relationships.md`. For lifecycle operation patterns (ND-003, ND-004), load `dap-bpa knowledge docs get general/lifecycle-operations`.

### Intrinsic Functions

| Function | Evaluation | Description |
|---|---|---|
| `get_secret: key` | Runtime | Retrieve from secret store. Nested: `[secret_name, json_key]` |
| `get_input: name` | Deploy-time | Reference input values |
| `get_attribute: [node, attr]` | Runtime | Runtime properties of node instances |
| `get_property: [node, prop]` | Deploy-time | Static node properties |
| `get_capability: [dep_id, cap]` | Runtime | Capabilities from other deployments |
| `get_environment_capability: cap` | Runtime | Alias for `get_capability` from parent deployment |
| `get_attribute_list: [node, attr]` | Runtime | List of attr values across all instances |
| `get_attribute_dict: [node, attrs]` | Runtime | Multiple attrs across all instances |
| `get_label: [key, index]` | Runtime | Deployment label values |
| `get_sys: [obj, field]` | Runtime | System metadata: `[tenant, name]`, `[deployment, id]`, etc. |
| `concat: [str1, str2, ...]` | Varies | String concatenation |
| `string_find: [str, substr]` | Deploy-time | Index of substring (-1 if not found) |
| `string_replace: [str, old, new, count?]` | Deploy-time | Replace occurrences |
| `string_split: [str, delim, index?]` | Deploy-time | Split string, optionally return element |
| `string_lower: str` | Deploy-time | Lowercase |
| `string_upper: str` | Deploy-time | Uppercase |
| `merge: [dict1, dict2, ...]` | Varies | Merge dictionaries (last key wins) |
| `get_inventory: capability_ref` | Deploy-time | Fetches live inventory for UI dropdowns |

**`get_capability` notes**: Can use `get_attribute`, `get_secret`, `concat` inside capability values. `get_property` and `get_input` resolve at deploy-time and cannot be used inside capability values — capability values are evaluated at runtime, after deploy-time resolution has already completed.

### Capabilities & Outputs

**Use `capabilities`, not `outputs`** — capabilities expose values to both users and other deployments. Every capability must have `value` and `description` fields. `outputs` is a legacy alias.

```yaml
capabilities:
  vm_ip:
    description: "IP address for VM"
    value: { get_attribute: [ vm, ip ] }
```

### Labels

Both `labels` and `blueprint_labels` are required:

```yaml
labels:
  # csys-obj-type classifies the deployed object for the DAP catalog
  csys-obj-type:
    values:
      - environment
  environment:
    values:
      - production

blueprint_labels:
  # env tags the blueprint; non-orchestrator (utility/helm) blueprints also
  # set csys-blueprint-type, while the top-level orchestrator sets env only
  env:
    values:
      - Dell
  csys-blueprint-type:
    values:
      - utility
```

Each label key maps to an object with a single key `values`, which must be a list containing exactly one string. The repo validator (`scripts/validate_blueprints.sh`) enforces `csys-obj-type` under `labels`, `env` under `blueprint_labels`, and `csys-blueprint-type` on every non-orchestrator blueprint.

### Workflows

Built-in workflows: `install`, `uninstall`, `update`, `execute_operation`.

Custom workflow definition:

```yaml
workflows:
  clear_cache: my_plugin.cache_module.clear_cache_method
  update_app:
    mapping: my_plugin.update_module.run_updates
    parameters:
      app_version:
        description: Version to update to
```

### Security Best Practices

1. **Never pass a literal string to `get_secret`** — always resolve via `{ get_secret: { get_input: secret_input } }` (SC-001)
2. **Never put `get_secret` in capabilities or outputs** — values display in orchestrator UI
3. **Never log secret values** — `ctx.logger.info` with `ctx_parameters` containing secrets leaks them
4. **Never store secrets in runtime_properties** — retrievable via API
5. **Never use `get_secret` as default in node type properties** — readable in blueprint source

### Available Plugins

| Category | Plugins |
|---|---|
| NativeEdge (private) | Asset discovery, NativeEdge (VM creation, image upload) |
| Cloud | vSphere, AWS, Azure, GCP, vCloud, OpenStack, Serverless Framework |
| Container/Orchestration | Helm, Kubernetes, Docker, Terraform, Terragrunt |
| Automation | Ansible, Fabric (SSH) |
| Other | Libvirt, Utilities |

Exception: the NativeEdge plugin (nativeedge) still uses `nativeedge.*` node type prefixes. All other plugins use `dell.*`.

### Blueprint Directory & Multi-File Patterns

A blueprint lives in a directory on disk.

Always use multi-file structure: blueprint.yaml, inputs.yaml, capabilities.yaml. Single-file is not production-ready.

Key rules:
- Name the main file `blueprint.yaml`
- Only `blueprint.yaml` imports plugins and `dell/types/types.yaml`
- YAML anchors (`dsl_definitions`) are scoped to the file they are defined in. Each imported file must define its own `dsl_definitions` block if it needs anchors. To share values across files, use inputs or namespaced imports — not YAML aliases.
- Node template IDs must be unique across ALL files

---

## CLI Quick Reference

Full CLI reference with all flags, fields, and workflows: `references/cli-commands.md`

For troubleshooting failed deployments and uploads: `references/troubleshooting.md`

**Always attempt commands immediately.** Do not ask the user whether credentials are configured. Just run the command; if credentials are missing, `dap-bpa` returns a clear error.

### Essential commands

```bash
# Find example blueprints
# Query can be positional OR --query flag
dap-bpa knowledge blueprints find "<description>"
dap-bpa knowledge blueprints find --query "<description>" --plugin <name>
dap-bpa knowledge blueprints get <id> --include-files

# Look up node types
dap-bpa knowledge plugins list <plugin>
dap-bpa knowledge plugins get <plugin> <node_type>
dap-bpa knowledge types get <type_name>
dap-bpa knowledge types list
dap-bpa knowledge plugins docs <plugin>

# Search documentation
dap-bpa knowledge docs search "<query>"
dap-bpa knowledge docs search "<query>" --plugin <name>

# Lint and validate
dap-bpa blueprint lint --file <path> --verify
# Run lint first. Do not run validate-all until lint --verify passes.
dap-bpa blueprint validate-all --file <path>

# Upload
dap-bpa orchestrator blueprints upload --file blueprint.yaml --id <id> --revision <ver>

# Deploy
dap-bpa orchestrator deployments create --blueprint-id <id> [--inputs <file>]

# Troubleshoot
dap-bpa orchestrator executions list
dap-bpa orchestrator executions get <id> --fields id status error error_structured
dap-bpa orchestrator events get <execution_id>
```

---

## Monitor

Runs a full install/uninstall lifecycle for a blueprint with auto-fix. Trigger: 'monitor this', 'did it pass', 'last run', 'check status', 'any failures'. Load references/monitor.md.
