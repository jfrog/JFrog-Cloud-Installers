---
name: dap-deployment-update
description: Use when updating a deployment — blueprint version bumps, input changes, skip_install/uninstall/reinstall, reinstall_list, force_reinstall, preview mode, drift check. Trigger: deployment update, node reinstall.
---

# Deployment Update — DAP / NativeEdge

Ground-truth reference for the deployment update API and workflow, sourced directly from the orchestrator and gateway source code.

**Source files:**
- `mgmtworker/nativeedge_system_workflows/deployment_update/workflow.py`
- `mgmtworker/nativeedge_system_workflows/deployment_update/step_extractor.py`
- `mgmtworker/nativeedge_system_workflows/deployment_update/update_instances.py`
- `rest-service/manager_rest/rest/resources_v3_1/deployment_updates.py`
- `hzp-api-gateway-svc/server/api/openapi/config/deployment_updates/`

For full details see the reference docs in the `resources/` directory alongside this file.

---

## Overview

A deployment update applies changes to a **running** deployment — new blueprint version, changed inputs, added/removed nodes, changed relationships, updated operations/plugins — without a full teardown and reinstall.

---

## CLI Usage (bpa)

All deployment update operations use the `bpa` CLI. Always use `bpa` for these commands — never call the REST API directly from scripts.

> **Important distinction**: `bpa orchestrator deployments update` is a simple PATCH to update a deployment's inputs field directly. It is NOT a deployment update workflow. Use `bpa orchestrator deployment-updates initiate` for the full deployment update workflow.

### Initiate a deployment update

```bash
bpa orchestrator deployment-updates initiate <deployment_id> --body <body.json>
```

The `--body` flag accepts a JSON file containing the request body. All 18 parameters are specified in the JSON file.

**Example: inputs-only update (no node changes)**

```bash
# body.json
{
  "inputs": { "image_size": "large" },
  "skip_reinstall": true
}

bpa orchestrator deployment-updates initiate my-deployment --body body.json
```

**Example: blueprint version bump**

```bash
# body.json
{
  "blueprint_id": "my-bp",
  "blueprint_version": "v2.1.0"
}

bpa orchestrator deployment-updates initiate my-deployment --body body.json
```

**Example: preview / dry-run**

```bash
# body.json
{
  "blueprint_version": "v2.1.0",
  "preview": true
}

bpa orchestrator deployment-updates initiate my-deployment --body body.json
```

**Example: partial update — force-reinstall specific instances only**

```bash
# body.json
{
  "blueprint_version": "v2.1.0",
  "skip_reinstall": true,
  "reinstall_list": ["app_server_abc123", "app_server_def456"]
}

bpa orchestrator deployment-updates initiate my-deployment --body body.json
```

**Example: force re-update after failure**

```bash
# body.json
{ "force": true }

bpa orchestrator deployment-updates initiate my-deployment --body body.json
```

The command returns the `DeploymentUpdate` object immediately (state `updating`). The update workflow runs asynchronously — use `bpa orchestrator executions get <execution_id>` to monitor progress.

### List deployment updates

```bash
# All updates across all deployments
bpa orchestrator deployment-updates list

# Updates for a specific deployment
bpa orchestrator deployment-updates list <deployment_id>
```

### Get a specific deployment update

```bash
bpa orchestrator deployment-updates get <update_id>
```

### Monitor the update execution

After initiating, the response includes an `execution_id`. Track progress with:

```bash
bpa orchestrator executions get <execution_id> --fields id status error finished_operations total_operations
bpa orchestrator events get <execution_id>
```

### Complete workflow example

```bash
# 1. Upload the new blueprint revision
bpa orchestrator blueprints upload --file blueprint.yaml --id my-bp --revision v2.1.0
bpa orchestrator blueprints get my-bp --fields id state revisions
# Wait until state: uploaded

# 2. Initiate the deployment update
cat > update-body.json << 'EOF'
{
  "blueprint_id": "my-bp",
  "blueprint_version": "v2.1.0",
  "skip_reinstall": true
}
EOF
bpa orchestrator deployment-updates initiate my-deployment --body update-body.json

# 3. Monitor progress
bpa orchestrator executions get <execution_id> --fields id status error
bpa orchestrator events get <execution_id>
```

---

## Request Body Parameters

The deployment update workflow is triggered via:

```
POST /api/v3.1/deployment-updates/<deployment_id>/update/initiate
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `blueprint_id` | string | current | New blueprint ID (for blueprint version bump) |
| `blueprint_version` | string | current | New blueprint revision |
| `inputs` | object | `{}` | Input overrides — merged with existing inputs |
| `reinstall_list` | string[] | `[]` | Node instance IDs to force-reinstall even if topology unchanged |
| `skip_install` | bool | `false` | Skip install operations on added nodes |
| `skip_uninstall` | bool | `false` | Skip uninstall operations on removed nodes |
| `skip_reinstall` | bool | `false` | Skip reinstall on modified nodes (use with caution) |
| `force_reinstall` | bool | `false` | Reinstall all nodes regardless of changes |
| `force` | bool | `false` | Force re-update after a failed update |
| `skip_drift_check` | bool | `false` | Skip runtime property drift comparison |
| `preview` | bool | `false` | Dry-run: compute and return the update plan without executing |
| `runtime_only_evaluation` | bool | `false` | Evaluate intrinsic functions at runtime rather than deploy-time |
| `update_plugins` | bool | `true` | Update plugins to latest matching versions |
| `workflow_id` | string | — | Custom update workflow (receives update context) |

### Drift Detection

When `skip_drift_check` is `false` (default), the system compares current runtime properties against the blueprint's expected state before applying changes. Nodes with drifted properties are flagged for reinstall.

### Preview Mode

Set `preview: true` to see what would change without executing. The response includes which nodes would be added, removed, modified, or reinstalled; the ordered execution steps; and any drift detected.

---

## Common Patterns

### Inputs-only update (no node changes)

```json
{ "inputs": { "image_size": "large" }, "skip_reinstall": true }
```

`skip_reinstall=true` prevents nodes from being reinstalled just because an input changed.

### Blueprint version bump

```json
{ "blueprint_id": "my-bp", "blueprint_version": "v2.1.0" }
```

### Partial update — touch only specific instances

```json
{
  "blueprint_version": "v2.1.0",
  "skip_reinstall": true,
  "reinstall_list": ["app_server_abc123", "app_server_def456"]
}
```

`skip_reinstall=true` suppresses automatic reinstall of every changed node; `reinstall_list` opts specific IDs back in.

### Preview / dry-run

```json
{ "blueprint_version": "v2.1.0", "preview": true }
```

Returns the update object with `steps` populated and `state: "preview"`. No lifecycle ops run.

### Force re-update after failure

```json
{ "force": true }
```

### Custom workflow

```json
{ "blueprint_version": "v2.1.0", "workflow_id": "my_custom_update_workflow" }
```

The custom workflow receives: `update_id`, `modified_entity_ids`, `added_instance_ids`, `added_target_instances_ids`, `removed_instance_ids`, `remove_target_instance_ids`, `extended_instance_ids`, `extend_target_instance_ids`, `reduced_instance_ids`, `reduce_target_instance_ids`, `skip_install`, `skip_uninstall`, `ignore_failure`, `install_first`, `node_instances_to_reinstall`, `central_plugins_to_install`, `central_plugins_to_uninstall`, `update_plugins`.

---

## Critical Gotchas

- **Unsupported changes abort the entire update** (before any lifecycle ops): changing a node's type, changing its `contained_in` host, or modifying relationship properties.
- **`skip_reinstall=true` does NOT mean "run update ops only"** — it means skip the node entirely (no update, no reinstall).
- **`skip_uninstall=true` leaves ghost instances** in the DB; they must be cleaned up manually later.
- **`update_plugins` defaults to `true`**, not `false` — plugins are updated by default.
- **`check_drift` runs in `preview` mode** with real side-effects on instance `system_properties`.
- **Schedules are never deleted** by an update — only created or updated.
- **`bpa orchestrator deployments update` is NOT this** — that command is a PATCH to `/rest/v1/deployments/{id}` that only patches the `inputs` field directly (no workflow, no lifecycle ops). Use `bpa orchestrator deployment-updates initiate` for the full update workflow.

---

## Node-Level Implementation (ND-009)

When the platform runs a deployment update, it invokes these lifecycle operations on each affected node instance in order:

1. **`check_drift`** — Compare live state to desired state. Must be **read-only** (no mutations) because it runs during `preview` mode.
2. **`preupdate`** — Pre-change hook (optional).
3. **`update`** — Apply the actual change (resize VM, update config, etc.). Must be idempotent (ND-004).
4. **`postupdate`** — Post-change validation, notification, or cache invalidation.

Additional optional operations: `update_config`, `update_apply`, `update_postapply`, `preheal`, `heal`, `postheal`.

### YAML Example

```yaml
node_templates:
  vm:
    type: dell.nodes.vsphere.Server
    properties:
      # ...
    interfaces:
      dell.interfaces.lifecycle:
        create:
          # ... (install workflow)
        delete:
          # ... (uninstall workflow)

        # ND-009: Update workflow operations
        check_drift:
          implementation: scripts/check_drift.py
          inputs:
            expected_cpus: { get_input: vm_cpus }
            expected_memory: { get_input: vm_memory_mb }
        update:
          implementation: scripts/update_vm.py
          inputs:
            cpus: { get_input: vm_cpus }
            memory: { get_input: vm_memory_mb }
        postupdate:
          implementation: scripts/verify_vm.py
```

**Key implementation notes:**
- `check_drift` sets `ctx.instance.runtime_properties['drifted'] = True` if live state differs from expected
- `update` applies the change and should be idempotent — retrying must not cause a second state change
- `postupdate` is for validation or notification — it should not mutate infrastructure

See `references/blueprint-examples.md` → "Update Workflow Lifecycle" for additional guidance.

---

## Full Reference

See `resources/api-and-workflow-reference.md` for:
- All REST endpoints (including internal ones)
- Full workflow phase diagram
- Node graph diff algorithm detail
- `update_or_reinstall_instances` decision logic
- Behaviour matrix for all skip/force flag combinations

---

## Retrieval

**Search for deployment update topics**:
```bash
bpa knowledge docs search "deployment update"
bpa knowledge docs search "skip reinstall"
```
