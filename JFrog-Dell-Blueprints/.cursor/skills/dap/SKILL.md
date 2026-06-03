---
name: dap
description: >-
  Use when the user says "write a blueprint", "fix my blueprint",
  "create a deployment", "what node type", "how do I deploy",
  "blueprint won't validate", "lint this", "review this yaml",
  "add an input", "which plugin", "help me with TOSCA",
  "babysit", "monitor", "did it pass", "did it fail",
  "last run", "any failures", "check status",
  or any request to write, review, debug, or test blueprint YAML.
---

# Blueprint Assist — Dell Automation Platform

This skill provides a blueprint authoring reference distilled from the official Blueprint Developer's Guide (Feb 2026, Rev A01), plus CLI access to the Dell Automation Platform via the `bpa` command.

## Reference Files

Detailed reference material is in the `references/` directory:

| File | Content |
|---|---|
| `rules/blueprint-rules.md` (Windsurf Rule) | **God-level rules** — mandatory best practices, loaded automatically via `activation: model_decision` |
| `references/cli-commands.md` | Full CLI reference — all commands, flags, fields, building/uploading/deploying workflows |
| `references/input-reference.md` | Detailed input, constraint, secret_key, input_groups, and data type reference with examples |
| `references/blueprint-examples.md` | Complete blueprint template, multi-file patterns (basic split, layered split), decision guide |
| `references/migration-guide.md` | Cloudify / NativeEdge → DAP migration tables and post-migration checklist |
| `references/troubleshooting.md` | Failed deployment diagnosis, upload error reference, common runtime errors |

### Plugin Lookup

When the user asks about a specific plugin (e.g. AWS, Kubernetes, Helm), retrieve plugin details on-demand via the CLI — no separate skill needed:

```bash
bpa knowledge plugins list <plugin>        # List all node types for a plugin
bpa knowledge plugins get <plugin> <type>  # Get node type properties
bpa knowledge plugins docs <plugin>        # Plugin overview, auth, patterns
bpa knowledge docs search "<query>" --plugin <name>  # Search plugin docs
```

Available plugins: ansible, aws, azure, docker, fabric, helm, hzp-edge, kubernetes, libvirt, openstack, redfish, storage, terraform, terragrunt, utilities, vcloud, vsphere.

---

## Blueprint Generation Process

Follow these 8 steps in order. All blueprints must comply with the mandatory rules in `blueprint-rules.md`.

### 1. Combined search

Start with a broad search to find relevant docs, plugins, and examples:

```bash
bpa knowledge search "<query>"
```

If `bpa knowledge search` is not available, fan out manually:

```bash
bpa knowledge docs search "<query>"
bpa knowledge blueprints find "<query>"
```

### 2. Targeted research

Drill into specifics with focused commands. Do NOT write YAML until all lookups are complete.

```bash
bpa knowledge docs search "<query>"
bpa knowledge plugins docs <plugin>
bpa knowledge plugins get <plugin> <node_type>
bpa knowledge blueprints find "<description>"
bpa knowledge blueprints get <id> --include-files
```

### 3. Propose

Present the user a short plan:
- What node types and plugins will be used
- Single-file or multi-file structure
- Key design decisions

### 4. Get user approval

Do **not** write YAML until the user confirms the plan. Ask for target directory.

### 5. Look up node types

Run `bpa knowledge plugins get <plugin> <node_type>` for **every** node type in the approved plan. This retrieves the exact properties, required fields, and defaults.

### 6. Build the blueprint

Write YAML using the looked-up properties. Comply with all mandatory rules from `blueprint-rules.md`:

- **Multi-file split** if 2+ plugins OR 5+ inputs (BS-010)
- **Use `dell.*` prefix**, NOT `cloudify.*` or `nativeedge.*` (TD-002)
- **Use `capabilities:`**, NOT `outputs:` (CP-001)
- **Secrets**: Use `type: secret_key`, never literal passwords (SC-001, SC-002)
- **CHANGELOG.yaml** is mandatory (BS-009)
- **No inline code** — use script files (ND-005)

### 7. Lint

**CRITICAL:** Run the linter BEFORE validation. Do NOT run validation commands until linting passes.

```bash
bpa blueprint lint --file blueprint.yaml --verify
```

**STOP HERE if linting fails.** Fix all errors and re-lint until `errorsFound: false`.

Do NOT confuse this with `bpa blueprint validate` — that checks plugin schemas, not `blueprint-rules.md` compliance.

### 8. Validate

After lint passes, validate node properties against plugin schemas:

```bash
bpa blueprint validate-all --file blueprint.yaml
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
    constraints:
      - pattern: '^[a-zA-Z][a-zA-Z0-9-]*$'
        error_message: Must start with a letter, alphanumeric and hyphens only.
```

#### Input Properties Reference

| Property | Type | Required | Description |
|---|---|---|---|
| `type` | string | Yes | `string`, `integer`, `float`, `boolean`, `list`, `dict`, `textarea` |
| `display_label` | string | Yes | UI label (IN-004) |
| `description` | string | Yes | Tooltip text (IN-001) |
| `default` | varies | Rec. | Default value — empty string OK, `null` discouraged |
| `hidden` | bool | No | Hide from UI (default: `false`) |
| `allow_update` | bool | No | Allow change via deployment update (default: `true`) |
| `constraints` | list | No | Validation constraints |
| `only_with` | string | No | Show only when referenced boolean input is true |
| `input_group` | — | — | Assigned via top-level `input_groups` section, not per-input |

#### Constraint Types

| Constraint | Example | Applies to |
|---|---|---|
| `valid_values: [a, b, c]` | Dropdown | All types |
| `pattern: '<regex>'` | Regex match | `string` |
| `min_length` / `max_length` | Length bounds | `string` |
| `in_range: [min, max]` | Numeric range | `integer`, `float` |
| `greater_than` / `less_than` | Numeric bounds | `integer`, `float` |

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

### Relationships

| Relationship | Purpose |
|---|---|
| `dell.relationships.depends_on` | Ordering dependency (target created first) |
| `dell.relationships.connected_to` | Network/logical connection |
| `dell.relationships.contained_in` | Parent-child containment |

For plugin-specific relationship types, `run_on_host`, and decision guidance, see `knowledge/docs/general/relationships.md`. For lifecycle operation patterns (ND-003, ND-004), see `knowledge/docs/general/lifecycle-operations.md`.

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

**`get_capability` notes**: Can use `get_attribute`, `get_secret`, `concat` inside capability values. `get_property` and `get_input` only work in capabilities if runtime-only evaluation is set.

### Capabilities & Outputs

**Use `capabilities`, not `outputs`** — capabilities expose values to both users and other deployments. Every capability must have a `description`. `outputs` is a legacy alias.

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
  environment:
    values:
      - { get_input: owner }
      - production

blueprint_labels:
  author:
    values:
      - my_team
```

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

### Blueprint Directory & Multi-File Patterns

A blueprint lives in a directory on disk.

**When to split**:

1. **Single file** — ONLY when: one plugin, ≤2 node templates, <5 inputs
2. **Basic split** — 2+ plugins OR 5+ inputs: `blueprint.yaml`, `inputs.yaml`, `capabilities.yaml`
3. **Layered split** — Different infrastructure + app concerns: use subdirectories

Key rules:
- Name the main file `blueprint.yaml`
- Only `blueprint.yaml` imports plugins and `dell/types/types.yaml`
- YAML anchors (`dsl_definitions`) are scoped to the file they are defined in. Each imported file must define its own `dsl_definitions` block if it needs anchors. To share values across files, use inputs or namespaced imports — not YAML aliases.
- Node template IDs must be unique across ALL files

---

## CLI Quick Reference

Full CLI reference with all flags, fields, and workflows: `references/cli-commands.md`

For troubleshooting failed deployments and uploads: `references/troubleshooting.md`

**Always attempt commands immediately.** Do not ask the user whether credentials are configured. Just run the command; if credentials are missing, `bpa` returns a clear error.

### Essential commands

```bash
# Find example blueprints
# Query can be positional OR --query flag
bpa knowledge blueprints find "<description>"
bpa knowledge blueprints find --query "<description>" --plugin <name>
bpa knowledge blueprints get <id> --include-files

# Look up node types
bpa knowledge plugins list <plugin>
bpa knowledge plugins get <plugin> <node_type>
bpa knowledge types get <type_name>
bpa knowledge types list
bpa knowledge plugins docs <plugin>

# Search documentation
bpa knowledge docs search "<query>"
bpa knowledge docs search "<query>" --plugin <name>

# Lint and validate
bpa blueprint lint --file <path> --verify
bpa blueprint validate-all --file <path>

# Upload
bpa orchestrator blueprints upload --file blueprint.yaml --id <id> --revision <ver>

# Deploy
bpa orchestrator deployments create --blueprint-id <id> [--inputs <file>]

# Troubleshoot
bpa orchestrator executions list
bpa orchestrator executions get <id> --fields id status error error_structured
bpa orchestrator events get <execution_id>
```

---

## Monitor

The monitor runs a full install/uninstall lifecycle for a blueprint, showing live step-by-step progress in the terminal.
When an error occurs it automatically classifies the failure, invokes an LLM to fix the blueprint, and re-runs — up to 3 attempts. The user receives an OS desktop notification when it finishes.

### Proactive check on conversation start

**At the start of every new conversation, before doing anything else:**

1. Read `~/.blueprint-assist/last-result.json`
2. If the file exists and `outcome != 'pass'` and you have not already reported this result in this session (check `finishedAt` against what you last surfaced) — surface the failure immediately:

> "I see your last monitor run for `<blueprintId>` failed during `<failedStep>`. Here's what happened: `<executionError>`. The monitor attempted `<N>` fix(es) — here's what was tried. How would you like to proceed?"

3. If `outcome == 'pass'` and there were retry attempts, you may briefly note the success:

> "Your last monitor run for `<blueprintId>` passed after `<N>` auto-fix attempt(s)."

Do **not** attempt another automated fix without the user's confirmation.

### When to start the monitor

- After `bpa lint-blueprint` passes and the blueprint is ready to test on a real environment
- Before committing a new or changed blueprint to version control

### How to start

If the user attaches or mentions a blueprint file (e.g. `my-blueprint.yaml` or drags a file into the chat), use its path directly:

```bash
bpa monitor --file <path-to-blueprint.yaml>
# with inputs:
bpa monitor --file <path-to-blueprint.yaml> --inputs '{"key": "value"}'
# fire-and-forget (returns immediately, runs in background):
bpa monitor --file <path-to-blueprint.yaml> --detach
```

In attached mode (default), the terminal shows live step-by-step progress and a final success/failure summary.
In detached mode (`--detach`), returns immediately with `{ status: "in_progress", session_id, deployment_id, ... }`.
The user receives an OS notification when it finishes.

### How to check status

```bash
bpa monitor --status          # most recent active session
```

Key fields in the response:

| Field | Meaning |
|---|---|
| `session_state` | `running` / `completed` / `failed` / `timedOut` |
| `execution_status` | DAP execution state (`started`, `terminated`, etc.) |
| `finished_operations` / `total_operations` | Progress within the execution |
| `events_summary.recent_errors` | Last 3 distinct error messages — useful for quick diagnosis |
| `data.report` (when finished) | Full `RunReport` including `diagnostics` and `retryHistory` |

### Understanding the result

When the session finishes, `bpa monitor --status` returns a full `RunReport`. Key fields:

```json
{
  "outcome": "pass" | "fail" | "timedOut" | "cancelled",
  "blueprintId": "...",
  "deploymentId": "...",
  "durationSeconds": 66,
  "steps": [
    { "step": "upload", "outcome": "pass" },
    { "step": "install", "outcome": "fail", "error": "..." }
  ],
  "diagnostics": {
    "failedStep": "install",
    "executionError": "Task failed ... secret not found",
    "classification": { "category": "blueprint_error", "matchedRule": "task_failed_event" }
  },
  "retryHistory": {
    "ceiling": 3,
    "attempts": [
      {
        "attempt": 1,
        "fix": { "patch": "...", "explanation": "Fixed typo in secret name" },
        "appliedAt": "..."
      }
    ],
    "finalOutcome": "pass"
  }
}
```

The same report is also written to `~/.blueprint-assist/last-result.json` and persists after the daemon shuts down.

### Failure categories

| Category | Meaning | Monitor action |
|---|---|---|
| `blueprint_error` | Wrong node type, missing property, bad secret name, script error | LLM invoked, fix attempted (up to 3x) |
| `resource_unavailable` | Permission denied, quota exceeded, resource already exists | Escalated immediately — no auto-fix |
| `network_timeout` | Connection refused, SSH timeout, DNS failure | Escalated immediately — no auto-fix |
| `unknown` | Upload validation failure, uncategorised error | Escalated immediately — no auto-fix |

When escalated, a desktop notification fires and the full diagnostics are in `last-result.json`.

### Reading last-result.json directly

```bash
cat ~/.blueprint-assist/last-result.json | jq '{outcome, blueprintId, failedStep: .diagnostics.failedStep, error: .diagnostics.executionError}'
```

### Do NOT use

- `--callback` — CI/Phase 2 only
- Manual `bpa deploy` / `bpa execution start` while a monitor session is active for the same blueprint

### Setup

The monitor requires an LLM adapter to perform auto-fixes. Run `bpa setup` and follow Step 3b (Diagnostician) to configure one. Supported adapters: Bedrock, OpenAI, Claude Code, Devin.
