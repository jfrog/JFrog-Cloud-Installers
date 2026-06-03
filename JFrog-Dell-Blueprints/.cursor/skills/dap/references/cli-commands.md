# Blueprint Assist CLI — Full Reference

All commands output JSON. Use `bpa <command>` if installed, or `./bpa-docker.sh <command>` via Docker if not.

Commands follow a hierarchical form: `bpa <group> <subgroup> <action>`.

---

## CLI Availability

1. **Direct CLI**: `bpa` — Installed via npm or locally built
2. **Docker runner**: `bpa-docker.sh` — Runs via Docker container when CLI not installed

```bash
# If bpa is installed (npm or local build)
bpa <command> [options]

# If bpa is not available, use Docker runner
./bpa-docker.sh <command> [options]
```

**When to use which:**
- Use `bpa` if it's installed (fastest, no Docker overhead)
- Use `bpa-docker.sh` if `bpa` command is not available (look for the script in `~/tmp/` or project directory)

The Docker runner provides the same functionality as the direct CLI but runs in a container, so it works without local installation.

---

## Configuration

DAPO API commands (`orchestrator blueprints list`, `orchestrator deployments list`, etc.) require authentication. If a command fails with a missing-credentials error:

```bash
export DAP_ORCHESTRATOR_DOMAIN="mcp-poc1216.pub.staging.automation.dell.com"
export DAP_TOKEN="eyJhbGci..."
```

Or create `~/.blueprint-assist/config.json`:
```json
{
  "orchestrator_domain": "your-orchestrator.domain.com",
  "token": "your-token"
}
```

Knowledge commands (node types, docs, examples, linting) work without auth.

**Always attempt the command immediately.** Do not ask the user whether credentials are configured, and do not explain auth requirements upfront. Just run the command and report the actual output. If credentials are missing, `bpa` will return a clear error — only then explain what needs to be set up.

---

## Building a New Blueprint (MANDATORY STEPS)

You MUST follow these steps in order. Do not skip any step.

1. **Search for an example** — always start here, never from scratch:
   ```bash
   bpa knowledge blueprints find "<what the user wants>"
   ```

2. **Get the example YAML** — this is your template:
   ```bash
   bpa knowledge blueprints get <id> --include-files
   ```

3. **Look up every node type you plan to use** — get exact properties:
   ```bash
   bpa knowledge types get <type_name>
   bpa knowledge plugins list <plugin>
   bpa knowledge plugins get <plugin> <node_type>
   ```
   Use `knowledge types get` as the default — it searches plugins and base types automatically. Use `knowledge plugins get` when you need to specify a particular plugin.

4. **Check plugin docs if needed:**
   ```bash
   bpa knowledge plugins docs <plugin>
   ```
   Returns `{ "content": "<markdown>" }` — a full plugin reference covering node types, auth config shape, provider-specific quirks, and usage patterns. Use this when `knowledge plugins get` output alone isn't enough context.

   Pass the short plugin name without the `-plugin` suffix — `bpa knowledge plugins docs kubernetes` not `kubernetes-plugin`. The command normalises the name, but using the short form is clearer. Valid names match the plugin import format: `vsphere`, `helm`, `ansible`, `kubernetes`, `aws`, `azure`, `openstack`, `docker`, `terraform`, `terragrunt`, `fabric`, `libvirt`, `vcloud`, `redfish`, `utilities`.

   **If the name isn't found**, the command returns:
   ```json
   { "error": "Docs for '<name>' not found", "available": ["ansible", "aws", "helm", ...] }
   ```
   - Check `available` for the correct name (e.g. you said `vsphere-plugin`, it's listed as `vsphere`)
   - If the plugin you need is genuinely absent from `available`, its docs haven't been downloaded locally — see **Downloading missing plugin docs** below

5. **Write the blueprint** using ONLY the syntax from steps 1-4, validated against the Blueprint Authoring Reference in SKILL.md.

6. **Verify and lint the blueprint** before showing to the user:
   ```bash
   bpa blueprint lint --file <path> --verify
   ```
   `--verify` recursively scans the blueprint's directory for zero-byte YAML files before linting. If any are found, linting is skipped and the result is:
   ```json
   { "verify": { "ok": false, "checked": 5, "zeroByteFiles": ["inputs.yaml"] }, "lint": null }
   ```
   Fix the empty files and re-run. On a clean directory the result is:
   ```json
   { "verify": { "ok": true, "checked": 5, "zeroByteFiles": [] }, "lint": { ... } }
   ```
   Always use `--verify` for multi-file blueprints. For single-file blueprints it's optional but harmless.

7. **Validate node templates** against plugin definitions (optional but recommended):
   ```bash
   bpa blueprint validate-all --file <path>
   ```

8. If linting or validation finds errors, fix them and validate again.

   **If you believe a lint warning is a false positive**, re-run with `--report-fp`:
   ```bash
   bpa blueprint lint --file <path> --report-fp
   ```
   This writes a debug report to `.blueprint-assist/debug-reports/lint-fp-<timestamp>.md` (relative to cwd) containing the full lint output. When the report is generated, tell the user:

   > "I think this lint warning may be incorrect. I've saved a debug report to `.blueprint-assist/debug-reports/lint-fp-<timestamp>.md`. If you'd like to help improve blueprint-assist, please share that file with the blueprint-assist team."

   The `reportPath` field in the command output contains the exact path to use. Only generate the report if you have a genuine reason to believe the warning is wrong — not as a routine step.

---

## Uploading a Blueprint

Upload is asynchronous — the server processes the archive after accepting it. Always confirm the upload completed before proceeding.

### Recommended: Upload via Blueprint YAML File (simplest, always works)

Pass the main blueprint YAML directly. The CLI automatically tars the parent directory and sets the entrypoint:

```bash
bpa orchestrator blueprints upload --file blueprint.yaml --id <blueprint_id> --revision 1.0.0
```

This works for **both single-file and multi-file blueprints**. The CLI tars the entire directory containing `blueprint.yaml`, so all sibling files (`scripts/`, `resources/`, etc.) are included automatically.

### Uploading a Pre-Built Archive

You can also pass a `.zip` or `.tar.gz` archive directly. The CLI automatically inspects the archive to find the blueprint YAML entrypoint:

```bash
bpa orchestrator blueprints upload --file my-blueprint.zip --id <blueprint_id> --revision 1.0.0
```

If the CLI can't find the YAML automatically, or you have a non-standard YAML filename, use `--application-file-name` to specify it:

```bash
bpa orchestrator blueprints upload --file my-blueprint.zip --id <blueprint_id> --revision 1.0.0 --application-file-name my-blueprint.yaml
```

### Blueprint Archive Structure Requirements

The orchestrator expects **exactly one of these archive patterns**:

1. **Single directory**: archive contains exactly 1 directory with all blueprint files inside
2. **Multiple directories + manifest.yaml**: archive contains multiple directories PLUS a manifest.yaml file

**Auto-Repack (v0.15.0+):**
If a `.zip` archive has loose files at the root (e.g. created with `zip -r blueprint.zip .` from inside the blueprint folder), the CLI automatically repacks the archive by wrapping all entries in a single top-level directory before upload. A diagnostic message is printed when this occurs. This applies to both `upload-blueprint` and `install` commands.

**What would fail without auto-repack:**
- Archive with loose files at root level: `blueprint.yaml`, `scripts/` directly in the archive root (error: "Archive must contain exactly 1 directory or multiple directories together with manifest.yaml")

**Correct Archive Creation:**
```bash
# Structure: one root directory containing all blueprint files
my-blueprint/
  blueprint.yaml        # main entrypoint
  scripts/
    hello_world.py

# Create ZIP from the parent directory, including the blueprint directory
zip -r my-blueprint.zip my-blueprint/

# Or create tar.gz
tar -czf my-blueprint.tar.gz my-blueprint/

# Upload — CLI auto-detects blueprint.yaml as the entrypoint
bpa orchestrator blueprints upload --file my-blueprint.zip --id "my-blueprint" --revision 1.0.0

# If your main YAML has a non-standard name, specify it explicitly
bpa orchestrator blueprints upload --file my-blueprint.zip --id "my-blueprint" --revision 1.0.0 --application-file-name my-blueprint.yaml
```

**Requirements:**
- Archive must contain exactly 1 directory at root level
- All blueprint files (YAML, scripts, resources) must be inside that directory
- The CLI auto-detects `blueprint.yaml` as the entrypoint; use `--application-file-name` for non-standard names

### New blueprint (first upload)

```bash
bpa orchestrator blueprints upload --file blueprint.yaml --id <blueprint_id> --revision 1.0.0
bpa orchestrator blueprints get <blueprint_id> --fields id state
# wait until state: uploaded
```

### Uploading a revision (blueprint already exists)

**Always ask the user what version to use before uploading.** Do not invent or auto-increment the version.

1. **Check the current version:**
   ```bash
   bpa orchestrator blueprints get <blueprint_id> --fields id revisions
   ```
   Look at the `revisions` array. The latest entry shows the current version.

2. **Ask the user:**
   > "The current version is `<version>`. What should the new revision be? (e.g. `1.0.1` for a patch, `1.1.0` for a minor update, `2.0.0` for a breaking change)"

3. **Upload with the user-specified revision:**
   ```bash
   bpa orchestrator blueprints upload --file blueprint.yaml --id <blueprint_id> --revision <new_version>
   ```

4. **Confirm completion:**
   ```bash
   bpa orchestrator blueprints get <blueprint_id> --fields id state revisions
   ```

**If state is `failed`** — the `revisions` array contains the error message.

Do not proceed to `orchestrator deployments create` until state is `uploaded`.

---

## Creating Deployments

### New deployment

```bash
bpa orchestrator deployments create --blueprint-id <blueprint_id> [--inputs <json-file>] [--display-name <name>] [--environment <env-id>]
```

**Input Parameters Formatting:**

Deployment inputs must be provided as a JSON file when using the `--inputs` flag:

```yaml
# deployment-inputs.yaml
vm_name: "my-server"
cpu_count: 2
memory_size: 4096
enable_monitoring: true
```

Then reference it:
```bash
bpa orchestrator deployments create --blueprint-id my-blueprint --inputs deployment-inputs.yaml
```

**Direct JSON input:**
```bash
bpa orchestrator deployments create --blueprint-id my-blueprint --inputs '{"vm_name": "my-server", "cpu_count": 2}'
```

**Input Validation:**
- All required inputs must be provided
- Input values must match the blueprint's input schema (type, constraints)
- For complex nested inputs, use a JSON file rather than command-line JSON

---

## Inspecting a Blueprint Before Deployment

1. `bpa orchestrator blueprints get <id> --fields id description requirements revisions`
2. Look at `requirements.secrets` to identify needed secrets
3. `bpa orchestrator secrets list` — verify all required secrets exist

---

## Validating Blueprints Against Plugin Source Code

When you have access to plugin source code locally:

1. **Add plugin to knowledge base:**
   ```bash
   bpa knowledge plugins add helm --search-path ~/plugins
   ```

2. **Validate a specific node template:**
   ```bash
   bpa blueprint validate my_vm --file blueprint.yaml
   ```

3. **Validate all node templates:**
   ```bash
   bpa blueprint validate-all --file blueprint.yaml
   ```
   Comprehensive validation of entire blueprint against plugin definitions.

---

## Downloading Missing Plugin Docs

If `bpa knowledge plugins docs <plugin>` returns `{ "error": "...", "available": [...] }` and the plugin name you need is not in the `available` list, the docs for that plugin haven't been fetched locally yet.

Use `bpa knowledge plugins fetch` to pull them from the upstream repo:

```bash
# Fetch docs for a single plugin
bpa knowledge plugins fetch kubernetes

# Fetch all plugin docs at once
bpa knowledge plugins fetch --all
```

This uses your local `git` config for authentication — no token setup needed if you already have GitHub access. Fetched docs are written to `~/.blueprint-assist/knowledge/` and are picked up immediately by subsequent `knowledge plugins docs` calls.

By default the command fetches from `https://github.com/fusion-e/ai-bp-toolkit` on `main`. To override, add to `~/.blueprint-assist/config.json`:
```json
{
  "docs_upstream": "https://github.com/your-org/your-fork",
  "docs_upstream_branch": "main"
}
```

**If the fetch fails**, tell the user:

> "I wasn't able to fetch the plugin docs — this usually means you don't have GitHub access to the upstream repo. Please contact the blueprint-assist team for help getting access."

Do not attempt to write blueprint YAML for a plugin whose docs you cannot retrieve — the node type shapes and auth config are too plugin-specific to guess correctly.

---

## DAPO API Command Reference

These require `DAP_ORCHESTRATOR_DOMAIN` and `DAP_TOKEN` to be set.

### Blueprints

```bash
bpa orchestrator blueprints list
bpa orchestrator blueprints list --fields id name state
bpa orchestrator blueprints get <blueprint_id>
bpa orchestrator blueprints get gs-1 --fields id description requirements
bpa orchestrator blueprints upload --file <path>
bpa orchestrator blueprints upload --file <path> --id <id> --revision <ver>
bpa orchestrator blueprints upload --file <archive.zip> --id <id> --revision <ver> --application-file-name <name.yaml>
```

**Upload flags:**
- `--file <path>` — path to a `.yaml`, `.zip`, or `.tar.gz` file
- `--id <blueprint_id>` — required; the blueprint ID to create or revise
- `--revision <version>` — e.g. `1.0.0`; required when creating a new revision
- `--application-file-name <name>` — the YAML entrypoint filename inside an archive (auto-detected from the archive when omitted; defaults to `blueprint.yaml`)
- `--visibility tenant|global|private` — defaults to `tenant`

**Default fields:** id, name, state, revision, type, revision_date, creator, created, description, tags

**All fields:** description, state, name, tenant_name, created, creator, id, visibility, is_hidden, tags, revisions, latest_revision, main_file_name, plan, plugin_list, type, component_of, revision, revision_date, upload_execution

### Deployments

```bash
bpa orchestrator deployments list
bpa orchestrator deployments get <deployment_id>
bpa orchestrator deployments get d5e3f0e1-5670-4667-9b41-337babf3b5a2
bpa orchestrator deployments create ...
bpa orchestrator deployments update <id> --inputs <json-file>
  # PATCH inputs only — NOT a deployment update workflow
```

**Default fields:** id, display_name, created_at, deployment_status, drift_status, blueprint_id, blueprint_name, blueprint_version, blueprint_type, deployment_type, deployment_groups, updated_at, resource_tags

**All fields:** id, display_name, blueprint_id, blueprint_version, blueprint_name, blueprint_type, inputs, groups, permalink, outputs, capabilities, scaling_groups, workflows, requirements, operations, resource_tags, description, latest_execution_id, installation_status, deployment_status, labels, parents, deployment_type, deployment_groups, visibility, created_at, updated_at, created_by, tenant_name, drift_status

### Deployment Updates (full update workflow)

Use these commands to apply changes to a running deployment (new blueprint version, changed inputs, added/removed nodes, etc.).

> **Note**: `bpa orchestrator deployments update` (above) only PATCHes the inputs field directly. Use `deployment-updates initiate` for the full deployment update workflow with lifecycle operations.

```bash
bpa orchestrator deployment-updates initiate <deployment_id> --body <body.json>
bpa orchestrator deployment-updates list
bpa orchestrator deployment-updates list <deployment_id>
bpa orchestrator deployment-updates get <update_id>
```

**`--body` JSON file** — contains the update parameters. All parameters are optional:

```json
{
  "blueprint_id": "my-bp",
  "blueprint_version": "v2.1.0",
  "inputs": { "size": "large" },
  "skip_reinstall": true,
  "preview": false,
  "force": false,
  "reinstall_list": ["instance_id1"]
}
```

**Default fields for deployment-updates:** id, deployment_id, state, execution_id, old_blueprint_id, new_blueprint_id, created_at, created_by

### Executions

```bash
bpa orchestrator executions list
bpa orchestrator executions get <execution_id>
bpa orchestrator executions get b319198a-d395-4587-9138-5e7c530f409f --fields id status error parameters
bpa orchestrator executions start ...
```

**Default fields:** id, blueprint_id, deployment_id, deployment_display_name, workflow_id, status, status_display, created_at, started_at, ended_at, created_by, error, finished_operations, total_operations

**All fields:** allow_custom_parameters, blueprint_id, blueprint_version, created_at, created_by, creator_id, deployment_display_name, deployment_id, ended_at, error, error_structured, finished_operations, id, is_dry_run, is_system_workflow, parameters, schedule, scheduled_for, started_at, status, status_display, tenant_name, total_operations, visibility, workflow_id

### Plugins

```bash
bpa orchestrator plugins list
bpa orchestrator plugins get <plugin_id>
bpa orchestrator plugins get cc54f9eb-d537-46b9-b526-a34803ae5562
bpa orchestrator plugins upload --file <path.wgn|.zip> [--name <display-name>] [--visibility tenant|global]
bpa orchestrator plugins delete <plugin_id> [--force]
bpa orchestrator plugins download <plugin_id> [--output <path>]
```

**Default fields:** id, name, version, creator, uploaded_date

**Plugin upload protocol:** The archive is sent as a raw binary body with `Content-Type: application/zip`. `name` and `visibility` are URL query parameters, not form fields.

### Events

```bash
bpa orchestrator events list
bpa orchestrator events list --limit 50
bpa orchestrator events list --from-dt 2026-03-01T00:00:00Z --to-dt 2026-03-02T00:00:00Z

bpa orchestrator events get <execution_id>
bpa orchestrator events get b319198a-d395-4587-9138-5e7c530f409f --batch-size 50
```

### Secrets

```bash
bpa orchestrator secrets list
bpa orchestrator secrets get <name>
```

**Default fields:** id, display_name, type, created_at, updated_at, created_by, labels

---

## Knowledge Commands

These work locally — no auth, no API connection needed.

### Node Types

```bash
bpa knowledge plugins list helm
bpa knowledge plugins list openstack
bpa knowledge plugins list kubernetes
bpa knowledge plugins list edge

bpa knowledge plugins get helm dell.nodes.helm.Release
bpa knowledge plugins get openstack dell.nodes.openstack.Server
```

### Type Lookup (Base + Plugin Types)

```bash
# Resolve any type — searches plugins first, then base types
bpa knowledge types get dell.nodes.vsphere.Server
bpa knowledge types get dell.nodes.ServiceComponent
bpa knowledge types get dell.relationships.depends_on

# List all known types (base + plugin)
bpa knowledge types list
bpa knowledge types list --source base
bpa knowledge types list --source plugins
```

`knowledge types get` is the recommended way to look up any type. It checks plugin types first (returning the plugin's `.md` doc), then falls back to base types from `dell/types/types.yaml` (returning the YAML definition and parent chain). Use this instead of `knowledge plugins get` when you don't know which plugin provides the type.

### Docs

**Search for docs** (semantic/keyword search):
```bash
bpa knowledge docs search <query> [--plugin x] [--limit n]
bpa knowledge docs find <query>    # alias
```

Returns scored sections from docs matching the query. Use this when you don't know the exact doc path or want to find relevant content across multiple files.

Examples:
```bash
bpa knowledge docs search "aws authentication"
bpa knowledge docs search "security groups" --plugin aws
bpa knowledge docs search "k8s auth" --limit 10
```

**Get a specific doc** (direct file access):
```bash
bpa knowledge docs get <path>
```

Returns the full markdown content of the specified doc file. Use this when you know the exact doc path.

Path format: `<plugin>/<file>` (without `.md` extension)

Examples:
```bash
bpa knowledge docs get aws/plugin
bpa knowledge docs get general/k8s-auth
bpa knowledge docs get vsphere/plugin
```

**Success** — returns `{ "path": "aws/plugin", "plugin": "aws", "content": "<full markdown>" }`

**Failure** — if the doc isn't found:
```json
{ "error": "Doc 'aws/nonexistent' not found", "available": ["aws/plugin", ...] }
```

### Plugin Documentation

```bash
bpa knowledge plugins docs <plugin>
bpa knowledge plugins node-type-docs <plugin> <node_type>
```

Use the short plugin name without the `-plugin` suffix — `kubernetes` not `kubernetes-plugin`. The command normalises it, but the short form is canonical.

**Success** — returns `{ "content": "<markdown>" }` with a full plugin reference: node types, auth config shape, provider quirks, and usage patterns.

**Failure** — if the name isn't recognised locally:
```json
{ "error": "Docs for '<name>' not found", "available": ["ansible", "aws", "helm", ...] }
```
Use the `available` array to find the correct name or confirm whether the plugin docs have been fetched at all. If the plugin is absent from `available`, fetch it with `bpa knowledge plugins fetch <plugin>`.

### Blueprint Examples

```bash
# Query can be positional argument OR --query flag
bpa knowledge blueprints find "deploy vm in vsphere"
bpa knowledge blueprints find --query "kubernetes" --plugin kubernetes
bpa knowledge blueprints find "helm chart" --type single

bpa knowledge blueprints get single-vsphere
bpa knowledge blueprints get multi-k8s --include-files

# Import a single blueprint directory into the local library
bpa knowledge blueprints add ./my-blueprint

# Import from an archive
bpa knowledge blueprints add ./my-blueprint.zip

# Recursively import all blueprints under a root directory
bpa knowledge blueprints add ~/my-projects

# Preview what would be imported without writing
bpa knowledge blueprints add ~/my-projects --dry-run

# Override depth and file-type defaults
bpa knowledge blueprints add ~/my-projects --scan-depth 3 --copy-depth 2

# Recognise non-standard main filenames
bpa knowledge blueprints add ~/my-projects --main-file-names "blueprint.yaml main.yaml"

# Skip confirmation prompt
bpa knowledge blueprints add ~/my-projects --yes

# Deprecated — use add instead:
# bpa knowledge blueprints scan <dir>
# bpa knowledge blueprints registry <file>
```

### Blueprint Linting

```bash
bpa blueprint lint --file path/to/blueprint.yaml
bpa blueprint lint --file path/to/blueprint.yaml --verify
bpa blueprint lint --file path/to/blueprint.yaml --report-fp
bpa blueprint lint --content "tosca_definitions_version: dell_1_1"
```

**`--verify`** recursively scans the blueprint's directory for zero-byte `.yaml`/`.yml` files before linting. Zero-byte files are a common failure mode when a file was created but not written (e.g. interrupted generation). If any are found, linting is skipped:

```json
{ "verify": { "ok": false, "checked": 5, "zeroByteFiles": ["inputs.yaml"] }, "lint": null }
```

On a clean directory:
```json
{ "verify": { "ok": true, "checked": 5, "zeroByteFiles": [] }, "lint": { ... } }
```

Paths in `zeroByteFiles` are relative to the blueprint's directory. `--verify` requires `--file` (not `--content`).

**`--report-fp`** writes a debug report when lint issues are present and the LLM considers a warning a false positive. Report is written to `.blueprint-assist/debug-reports/lint-fp-<timestamp>.md` relative to cwd. Silently ignored if lint returns no issues. The output includes a `reportPath` field with the exact path:

```json
{ "warnings": [...], "errors": [], "reportPath": ".blueprint-assist/debug-reports/lint-fp-2026-03-04T12-00-00-000Z.md" }
```

### Blueprint Validation

```bash
bpa blueprint validate <node> --file path/to/blueprint.yaml
bpa blueprint validate-all --file path/to/blueprint.yaml
```

### Adding Plugins to Knowledge Base

```bash
bpa knowledge plugins add <name>
bpa knowledge plugins add helm --search-path ~/plugins
```

### Fetching Plugin Docs

```bash
bpa knowledge plugins fetch <plugin>
bpa knowledge plugins fetch --all
bpa knowledge plugins fetch helm --branch develop
bpa knowledge plugins fetch helm --upstream https://github.com/your-org/your-fork
```

Fetches plugin docs from the upstream repo using sparse git clone and installs them to `~/.blueprint-assist/knowledge/`. Uses your local git config for auth — no token setup needed if you have GitHub access. Run this when `knowledge plugins docs` returns a not-found error and the plugin is absent from `available`.

Config overrides in `~/.blueprint-assist/config.json`:
- `docs_upstream` — repo URL (default: `https://github.com/fusion-e/ai-bp-toolkit`)
- `docs_upstream_branch` — branch to fetch from (default: `main`)

**Available plugins for knowledge commands:** helm, openstack, edge, kubernetes (check `~/.blueprint-assist/knowledge/plugins/` for current list after fetching)
