---
name: dap-scripts
description: Use when writing or debugging Python scripts for DAP blueprints — from dell import ctx, ctx_parameters, runtime_properties, NonRecoverableError, RecoverableError, REST client. Triggers — blueprint script, dell ctx.
---

# Blueprint Script Authoring — Dell Automation Platform

## Runtime Mode

You are running in IDE mode with shell access.
Use the `bpa` CLI for BPA operations.
Do not use the function interface unless explicitly instructed by the host.

Python scripts are used in blueprint operations when the logic is custom and doesn't fit an existing plugin. The script is referenced by a relative path in the operation's `implementation:` field and is executed by the DAP agent.

## When to Use Scripts vs Other Execution Methods

| Need | Recommended approach | Why |
|---|---|---|
| Custom Python logic (API calls, data transforms, conditional flows) | **Python script** (this skill) | Full access to `ctx`, runtime_properties, REST client |
| Run shell commands on a remote host via SSH | **Fabric plugin** (`dap-plugin-fabric` skill) | Purpose-built for SSH; handles auth, sudo, output capture |
| Configure a host with packages, services, templates | **Ansible plugin** (`dap-plugin-ansible` skill) | Idempotent, declarative, Galaxy ecosystem |
| Provision cloud/infra resources declaratively | **Terraform plugin** (`dap-plugin-terraform` skill) | State management, plan/apply lifecycle |
| Bootstrap a VM at first boot (users, SSH keys, packages) | **cloud-init** via the compute plugin's `cloudInit` property | Runs once at VM creation before the agent connects |

**Default preference**: Use an existing plugin when one fits. Use a Python script when you need custom orchestrator-side logic (accessing `ctx`, reading/writing runtime_properties, calling the REST client, or implementing complex conditional flows that plugins don't support).

## Required imports (MANDATORY)

Every DAP Python script must use the `dell` module — **never** `cloudify` or `nativeedge`.

```python
from dell import ctx                                    # ctx object: node, instance, logger, operation
from dell.state import ctx_parameters as inputs         # operation inputs passed from the blueprint
from dell.exceptions import NonRecoverableError, RecoverableError  # error handling
```

The `json.load(sys.stdin)` pattern used in older Cloudify scripts is **forbidden** — always use `inputs.get()` instead.

---

## Full canonical script pattern

```python
from dell import ctx
from dell.state import ctx_parameters as inputs
from dell.exceptions import NonRecoverableError, RecoverableError
def main():
    # 1. Read operation inputs (passed via the blueprint's operation inputs: section)
    cluster_name = inputs.get('cluster_name')
    config_data  = inputs.get('config_data', {})
    credential   = inputs.get('credential')   # resolved from get_secret in blueprint

    if not cluster_name:
        raise NonRecoverableError("'cluster_name' is required")

    # 2. Log via ctx.logger — integrates with DAPO's event stream
    ctx.logger.info(f"Starting operation for cluster: {cluster_name}")
    ctx.logger.info(f"Node: {ctx.node.id}  Instance: {ctx.instance.id}  Op: {ctx.operation.name}")

    # 3. Read static node properties (defined in blueprint node_templates.properties)
    some_property = ctx.node.properties.get('some_property', 'default')

    try:
        result = do_work(cluster_name, config_data, credential)

        # 4. Write outputs to runtime_properties — downstream nodes read these
        #    via  get_attribute: [this_node, result]
        ctx.instance.runtime_properties['result']       = result
        ctx.instance.runtime_properties['status']       = 'completed'
        ctx.instance.runtime_properties['cluster_name'] = cluster_name

        ctx.logger.info("Operation completed successfully")

    except TemporaryFailure as e:
        # 5. RecoverableError → DAPO retries the operation (respects max_retries)
        raise RecoverableError(f"Temporary failure, will retry: {e}")

    except Exception as e:
        # 6. NonRecoverableError → operation fails immediately, no retry
        ctx.logger.error(f"Fatal error: {e}")
        raise NonRecoverableError(f"Operation failed: {e}")
class TemporaryFailure(Exception):
    pass
if __name__ == "__main__":
    main()
```

---

## `ctx` object reference

| Attribute | Description |
|---|---|
| `ctx.node.id` | Node template name (e.g. `vm`, `storage`) |
| `ctx.node.type` | Node type (e.g. `dell.nodes.vsphere.Server`) |
| `ctx.node.properties` | Static properties from the blueprint `properties:` section |
| `ctx.instance.id` | Unique runtime instance ID |
| `ctx.instance.runtime_properties` | Read/write dict persisted across operations and readable by other nodes via `get_attribute` |
| `ctx.instance.update()` | Flush runtime_properties to the orchestrator immediately (use after large writes) |
| `ctx.operation.name` | Currently executing operation (`create`, `start`, `delete`, etc.) |
| `ctx.operation.retry_number` | Current retry attempt (0-indexed) |
| `ctx.logger.info/debug/warning/error(msg)` | Write to DAPO event log |
| `ctx.download_resource('path/file')` | Download a blueprint resource file to the agent's working directory |
| `ctx.download_resource_and_render('file.j2', template_variables={...})` | Download and Jinja2-render a template |

---

## Error types

| Exception | Behaviour |
|---|---|
| `NonRecoverableError` | Operation fails immediately. No retry. Marks the node as failed. |
| `RecoverableError` | Operation is retried after `retry_interval` seconds, up to `max_retries` times. After exhausting retries it becomes a `NonRecoverableError`. |

Use `RecoverableError` for transient conditions (API timeouts, resource not ready yet). Use `NonRecoverableError` for configuration errors, missing inputs, or any condition that retrying won't fix.

---

## How operation inputs flow from blueprint to script

Blueprint:
```yaml
node_templates:
  my_node:
    type: dell.nodes.Root
    interfaces:
      dell.interfaces.lifecycle:
        create:
          implementation: scripts/create.py
          max_retries: 3
          inputs:
            cluster_name: { get_input: cluster_name }
            credential:   { get_secret: { get_input: my_secret_name } }
            config_data:  { get_attribute: [other_node, result] }
```

Script:
```python
cluster_name = inputs.get('cluster_name')   # from get_input
credential   = inputs.get('credential')     # already-resolved secret value
config_data  = inputs.get('config_data')    # runtime_properties of other_node
```

The `inputs:` section of the operation is the bridge. Everything passed there is available via `inputs.get()` in the script. The orchestrator resolves all intrinsic functions (`get_input`, `get_secret`, `get_attribute`) before invoking the script.

For the full lifecycle sequence (precreate through postdelete) and cross-plugin patterns like ND-003, see `knowledge/docs/general/lifecycle-operations.md`.

---

## Reporting task results (`ctx.returns`)

For most lifecycle operations, writing to `ctx.instance.runtime_properties` *is* the output — no explicit return is needed.

When an operation must surface a **task result value** to the orchestrator (most commonly `check_drift`, but also any custom workflow task whose return value the workflow logic reads), use `ctx.returns(<payload>)`:

```python
ctx.returns({'drift': True, 'diff_count': 3})   # orchestrator reads this
ctx.returns(None)                                 # explicit "no result"
```

Scripts run in a subprocess — a plain Python `return` statement is **ignored** by the orchestrator. `ctx.returns()` is the only channel whose value is captured as the task result. The payload must be JSON-serializable.

**Never** use `return <value>` to communicate with the orchestrator, and never mutate `runtime_properties` as a substitute return channel in operations that use `ctx.returns` (e.g. `check_drift` must be read-only).

For the `check_drift`-specific contract and the `configuration_drift` payload shape consumed by the update workflow UI, see `dap-deployment-update/SKILL.md` → *check_drift return payload*.

---

## Relationship operations

For operations defined in `source_interfaces` or `target_interfaces` on a relationship, use `ctx.source` and `ctx.target` instead of `ctx.node` / `ctx.instance`:

```python
source_props  = ctx.source.node.properties
target_rp     = ctx.target.instance.runtime_properties
ctx.source.instance.runtime_properties['connected_to'] = ctx.target.node.id
```

---

## Accessing the manager REST client (advanced)

If the script needs to call the DAPO REST API directly (e.g. to read or write secrets programmatically):

```python
from dell import ctx, manager

rest_client = manager.get_rest_client()
secret = rest_client.secrets.get('my_secret_name')
value  = secret['value']
```

---

## Script location

Scripts must be inside the blueprint archive. Reference them by path relative to the blueprint root:

```yaml
implementation: scripts/configure.py        # scripts/ at blueprint root
implementation: application/scripts/run.py  # nested path — fine
```

Keep all scripts in a `scripts/` directory (or subdirectory). Do not inline Python code in YAML.

---

## Forbidden patterns

| Pattern | Why forbidden | Use instead |
|---|---|---|
| `from cloudify import ctx` | Legacy Cloudify — not supported in DAP | `from dell import ctx` |
| `from nativeedge import ctx` | Legacy NativeEdge — not supported in DAP | `from dell import ctx` |
| `json.load(sys.stdin)` | Old Cloudify input mechanism | `inputs.get('key')` |
| `executor: central_deployment_agent` | Cloudify/NativeEdge artefact — invalid in DAP | Omit `executor` (uses manager agent) or use `executor: { get_environment_capability: oxy_agent }` for Oxy offload |

---

## Retrieval

**Search for script-related topics**:
```bash
bpa knowledge docs search "blueprint script"
bpa knowledge docs search "runtime_properties"
```
