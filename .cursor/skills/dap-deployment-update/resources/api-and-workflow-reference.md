# Deployment Update — Full API & Workflow Reference

Ground-truth reference sourced directly from orchestrator and gateway source code.

---

## REST API Endpoints

### `POST /rest/v1/deployment-updates/{deployment_id}/update/initiate`

**The primary user-facing endpoint.** Kicks off an update and returns immediately.

- `{deployment_id}` is the **deployment ID**, not an update ID.
- Creates a `DeploymentUpdate` object, queues an `update` execution, returns the update object.
- All behaviour flags (skip_install, skip_reinstall, etc.) are passed here.

### `POST /rest/v1/deployment-updates/{id}/update/finalize`

**No-op.** Returns the existing update object unchanged. Present only for backward compatibility with old Cloudify-era clients.

### `GET /rest/v1/deployment-updates`

List deployment updates. Supports:
- `_size`, `_offset` — pagination
- `_sort`, `order` — sorting
- `_include` — comma-separated field selection
- `filter` — PowerAPI filter ruleset
- `_search` — substring search on `id`

**Response:** `PaginatedDeploymentUpdateResponse` with `items` (array of `DeploymentUpdateResponse`) and `metadata`.

### `GET /rest/v1/deployment-updates/{id}`

Retrieve a single deployment update by its update ID (not the deployment ID).

**Response:** `DeploymentUpdateResponse`

| Field | Description |
|---|---|
| `id` | Update ID |
| `deployment_id` | Target deployment |
| `old_blueprint_id` / `new_blueprint_id` | Blueprint before and after |
| `old_inputs` / `new_inputs` | Inputs before and after |
| `state` | `updating` → `executing_workflow` → `finalizing` → `successful` / `failed` / `preview` |
| `execution_id` | Execution running this update |
| `steps` | List of `DeploymentUpdateStep` dicts |
| `deployment_plan` | Full resolved plan at update time |
| `deployment_update_nodes` | Node list |
| `deployment_update_node_instances` | Instance change dict (`added`, `removed`, `extended`, `reduced`) |
| `modified_entity_ids` | Entities that changed |
| `central_plugins_to_install` / `central_plugins_to_uninstall` | CDA plugin changes |
| `created_at`, `created_by`, `tenant_name`, `visibility` | Metadata |

### Internal-only endpoints (used by mgmtworker, not external clients)

| Method | Path | Purpose |
|---|---|---|
| `PUT` | `/api/v3.1/deployment-updates/{id}` | Create the update object at workflow start |
| `PATCH` | `/api/v3.1/deployment-updates/{id}` | Update state/plan/steps/nodes/instances during each phase |
| `POST` | `/api/v3.1/deployment-updates` | Bulk-create for snapshot restore (internal/snapshot tag only) |

---

## Workflow Phases

The `update_deployment` workflow runs four sequential phases. **Phases 2 and 4 are skipped entirely when `preview=true`.**

```
update_deployment(ctx, *, update_id, preview, workflow_id, custom_workflow_timeout, **kwargs)
│
├─ Phase 1: _prepare_update_graph          [always runs]
│   ├─ prepare_plan          — resolve blueprint+revision, merge inputs, compute plan
│   ├─ create_steps          — diff old vs new plan → DeploymentUpdateStep list
│   ├─ prepare_update_nodes  — compute added/removed/extended/reduced instances
│   └─ prepare_plugin_changes — identify host-agent & CDA plugin installs/uninstalls
│
├─ Phase 2: _perform_update_graph          [SKIPPED in preview]
│   ├─ set_deployment_attributes       — update deployment object (blueprint, inputs, outputs, workflows, …)
│   ├─ prevent_removing_locked_instances — abort if any removed instance is locked
│   ├─ update_inter_deployment_dependencies
│   ├─ update_deployment_nodes         — create new nodes, update modified ones in DB
│   └─ update_deployment_node_instances — create new instances, extend existing ones
│
├─ Phase 3: _execute_deployment_update     [lifecycle ops]
│   ├─ if reduced AND NOT skip_uninstall  → _unlink_relationships()
│   ├─ if removed AND NOT skip_uninstall  → lifecycle.uninstall_node_instances()
│   ├─ update_or_reinstall_instances()   — drift check, update ops, heal, reinstall
│   ├─ if added AND NOT skip_install     → lifecycle.install_node_instances()
│   └─ if extended AND NOT skip_install  → _establish_relationships()
│   [Phase 3b: _execute_resume_install — installs instances stuck in non-started state]
│
├─ Phase 4: _post_update_graph             [SKIPPED in preview]
│   ├─ delete_removed_relationships    — remove unlinked relationships from DB
│   ├─ delete_removed_instances        — remove uninstalled instances from DB
│   ├─ delete_removed_nodes            — remove removed nodes from DB
│   ├─ update_schedules                — create/update execution schedules from plan
│   ├─ update_operations               — update operation inputs for operation-type steps
│   └─ [plugin uninstall tasks if host_plugins_to_uninstall is non-empty]
│
└─ set state = 'successful'
```

### Step sort order (before execution)

1. `remove` < `add` < `modify` (by action)
2. Within `remove`: relationships before nodes
3. Within `add`: nodes before relationships; nodes sorted by topology (dependencies first — higher `topology_order` first)

---

## Node Graph Diff — How Changes Are Detected

`extract_steps(nodes, deployment, new_plan)` in `step_extractor.py` compares the current deployment state against the new plan and yields `DeploymentUpdateStep` objects.

### What is compared

| Entity | How compared |
|---|---|
| **Nodes** | New node → `add node`. Missing node → `remove node`. Type or `contained_in` host changed → `modify node` (**unsupported** — aborts update) |
| **Node properties** | Dict diff of `properties`; each changed key → `add/remove/modify property` step |
| **Node operations** | List diff per operation name; multi-op lists supported. No-op operations (all fields empty) treated as absent |
| **Relationships** | Matched by `(type, target_id)` pair with duplicate-relationship counter. New rel → `add`. Missing rel → `remove`. Reordered rel → `modify` |
| **Relationship operations** | Diff of `source_operations` and `target_operations` per relationship |
| **Relationship properties** | Detected but **unsupported** — aborts update |
| **Plugins** | `plugins_to_install` and `plugins` arrays diffed per node; new/changed plugin → `add/modify plugin` step |
| **Outputs** | Dict diff; each changed key → step |
| **Workflows** | Dict diff (strips `is_available`/`failed_rules_details`); each changed key → step |
| **Groups** | Dict diff (members as sets); each changed key → **unsupported** — aborts update |
| **Description** | String equality; change → `modify description` step |
| **Lock expressions** | Per-node; change → `modify lock` step |
| **Capabilities** | Compared in `_diff_node_attrs()`; change triggers reinstall but emits no step |
| **planned_instances** | Compared in `_diff_planned_instances()`; change → instance add/remove via `modify_deployment()` |

### Unsupported steps — update is aborted before any lifecycle ops

- Changing a node's **type**
- Changing a node's **`contained_in` host** (moving it to a different container)
- Adding/removing **relationship properties**
- Adding/removing/modifying **groups**

### Instance change categories (computed by `tasks.modify_deployment()`)

| Category | Meaning |
|---|---|
| `added` | New instances (node added, or `planned_instances` count increased) |
| `removed` | Instances to delete (node removed, or count decreased) |
| `extended` | Existing instances that gained new relationships |
| `reduced` | Existing instances that lost relationships |

---

## `update_or_reinstall_instances` — Decision Logic

This function decides which existing instances get updated in-place vs reinstalled.

```
consider_for_update = all_instances − added − removed − not_installed

force_reinstall_instances = instances whose ID is in reinstall_list
must_reinstall = force_reinstall_instances
consider_for_update -= force_reinstall_instances

IF NOT skip_drift_check:
    run check_drift on instances that declare the operation
    instances_with_drift   = those that returned result=True
    failed_check           = those where check_drift itself failed → must_reinstall |= get_contained_subgraph()

fake_drift_instances = changed_instances (from steps) that don't declare check_drift
    → marked as drifted synthetically

FOR each instance in instances_with_drift:
    IF no update/update_config/update_apply op AND has own drift:
        must_reinstall |= get_contained_subgraph()

instances_to_update = instances_with_drift − must_reinstall

IF force_reinstall:
    must_reinstall |= instances_to_update   # move all to reinstall
    instances_to_update = {}

IF instances_to_update non-empty AND NOT skip_heal:
    run check_status
    heal unhealthy instances
    failed_heal → must_reinstall
    if failed_heal AND skip_reinstall → raise RuntimeError

run lifecycle.update_node_instances(instances_to_update)
failed_update = instances where update_failed flag == current execution_id
if failed_update AND skip_reinstall → raise RuntimeError
must_reinstall |= failed_update

IF skip_reinstall:
    must_reinstall = force_reinstall_instances only   # all other reinstalls suppressed

run lifecycle.reinstall_node_instances(must_reinstall, ignore_failure=ignore_failure)
clean up drift markers
```

### "Can be updated" check

An instance can be updated in-place (without reinstall) if it declares at least one of:
- `interfaces.lifecycle.update`
- `interfaces.lifecycle.update_config`
- `interfaces.lifecycle.update_apply`

If none exist **and** the instance has its own drift (not just relationship drift) → falls through to reinstall.

---

## Behaviour Matrix: Skip/Force Flags

| Scenario | Flags | Result |
|---|---|---|
| Changed property, node has `update` op | *(none)* | `update` op runs in-place |
| Changed property, node has no `update` op | *(none)* | Node reinstalled |
| Changed property, don't want reinstall | `skip_reinstall=true` | Node skipped entirely (not updated, not reinstalled) |
| Force reinstall for all changed nodes | `force_reinstall=true` | All changed nodes reinstalled (bypasses update ops) |
| Force reinstall for specific instances only | `reinstall_list=[id1,id2]` | Those IDs always reinstalled, even with `skip_reinstall=true` |
| Added node, don't install it | `skip_install=true` | New instances not installed |
| Removed node, keep it running | `skip_uninstall=true` | Removed instances not uninstalled, not deleted from DB |
| Failed previous update | `force=true` | Allows new update when previous state is `failed` |
| Drift check too slow / noisy | `skip_drift_check=true` | Skips `check_drift`; all step-changed instances treated as drifted |
| Node unhealthy, update anyway | `skip_heal=true` | Skips `check_status` and heal; directly runs update ops |
| Uninstall failure is acceptable | `ignore_failure=true` | Failures during uninstall of removed instances are tolerated |

---

## TypeScript Client Notes (`DapFullClient`)

The `ai-bp-toolkit` `DapFullClient` **has no dedicated deployment update method**. `deployments.update` is a simple PATCH to `/rest/v1/deployments/{id}` for inputs only — it is NOT a deployment update:

```typescript
// This is NOT a deployment update:
deployments.update(id: string, inputs?: Record<string, unknown>): Promise<Deployment>
// → PATCH /rest/v1/deployments/{id} { inputs }
```

To initiate a full deployment update from TypeScript, call the HTTP layer directly:

```typescript
// Using the private httpClient (or add a public deploymentUpdates namespace to DapFullClient)
const update = await client['httpClient'].post(
  `/rest/v1/deployment-updates/${deploymentId}/update/initiate`,
  {
    blueprint_id: 'my-blueprint',
    blueprint_version: 'v2.1.0',
    skip_reinstall: true,
    inputs: { size: 'large' },
  }
);
```

If building a proper integration, add a `deploymentUpdates` namespace to `DapFullClient` following the same pattern as the existing namespaces (`blueprints`, `deployments`, `executions`, etc.).

---

## Additional Gotchas

### `skip_uninstall` leaves ghost instances

Removed instances are not uninstalled and not deleted from the DB. They remain in the deployment's node instance list indefinitely. A subsequent update (without the flag) or manual execution is needed to clean them up.

### `update_plugins` defaults to `true`

Unlike all other boolean flags which default to `false`, `update_plugins` defaults to `true`. Plugins are updated automatically unless you explicitly pass `update_plugins=false`.

### `check_drift` runs in preview mode with real side-effects

Preview mode sets `ctx.dry_run = False` before running `check_drift`, then restores it. This means drift state in `system_properties["configuration_drift"]` is actually updated on instances even during a preview run. The side-effect is on the orchestrator side — the workflow handler (`_set_node_instance_drift`) writes the result of the finished task into `system_properties`. The `check_drift` script itself must remain read-only and communicate only via `ctx.returns(...)`.

### `check_drift` return protocol

The workflow's `check_drift` step expects the script to report its finding through the script-plugin's task-result channel:

- **Return channel:** `ctx.returns(<payload>)`. A plain Python `return` statement is invisible to the orchestrator (scripts run in a subprocess; only `ctx.returns` is captured as the task result).
- **Recommended payload** (unlocks the "View actual drift" UI): `{resource_id, diff_count, diff, state_drift, time}` — the shape produced by the orchestrator's `create_resource_drift_info` helper. Return `None` when nothing has drifted.
- **Minimum payload:** `{'drift': True | False}` — treated as a yes/no signal; UI renders no diff.
- **Never** mutate `runtime_properties` or `system_properties` from inside `check_drift` — it's called during `preview` and must be side-effect-free from the script's perspective.

Canonical runnable example: `blueprints/script/drift-example-blueprint.yaml` in the blueprint knowledge base.

### `blueprint_version` corresponds to `revision_id`

The `blueprint_version` field maps to the `revision_id` used when uploading a blueprint via `PUT /api/v3.1/blueprints/{id}/revisions/{revision_id}`. You can supply:
- Neither → current blueprint at current revision
- `blueprint_id` only → switch to different blueprint, latest revision
- `blueprint_version` only → stay on current blueprint ID, update to that revision
- Both → switch to a specific blueprint at a specific revision

### Relationship reordering happens post-lifecycle

If relationship order changes in the blueprint, `delete_removed_relationships` (Phase 4) reorders instance relationships to match the new plan. Lifecycle operations in Phase 3 use the old order.

### Schedules are never deleted

`update_schedules` creates and updates schedules from `deployment_settings.default_schedules` in the plan but never deletes stale schedules. Remove them manually via the schedules API.

### `install_first` reverses Phase 3 order

With `install_first=true`, the Phase 3 execution order becomes: install new instances → uninstall removed ones (instead of uninstall-first). Useful for rolling-style updates where new nodes must be available before old ones are torn down.

### `auto_correct_types` for input schema migrations

When a blueprint changes a declared input type (e.g., `string` → `integer`), existing deployments carry the old type. Without `auto_correct_types=true`, type mismatches cause plan evaluation errors.

### `reevaluate_active_statuses` for stuck updates

If a previous update got stuck in `updating` or `executing_workflow` state (e.g., the mgmtworker crashed), the normal concurrency check blocks new updates. `reevaluate_active_statuses=true` re-checks those states against actual execution statuses and clears them if the underlying execution is no longer active.
