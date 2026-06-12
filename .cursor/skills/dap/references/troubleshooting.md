# Troubleshooting Guide

## Troubleshooting a Failed Deployment

1. `dap-bpa orchestrator executions list` — find the failed execution
2. `dap-bpa orchestrator executions get <id> --fields id status error error_structured`
3. `dap-bpa orchestrator events get <id>` — get the event trail
4. Examine error messages and event types to diagnose

### Detailed steps

```bash
# 1. Find the failed execution
dap-bpa orchestrator executions list --fields id deployment_display_name workflow_id status error ended_at

# 2. Get full error details
dap-bpa orchestrator executions get <id> --fields id status error error_structured parameters

# 3. Get execution events (the log trail)
dap-bpa orchestrator events get <id>

# 4. If many events, paginate
dap-bpa orchestrator events get <id> --from-event 0 --batch-size 50
dap-bpa orchestrator events get <id> --from-event 50 --batch-size 50
```

**What to look for in events:**
- `event_type: "task_failed"` — the specific operation that failed
- `error_causes` — root cause chain
- `node_name` + `operation` — which node and what it was doing
- Events with `type: "cloudify_log"` often have the most detail

## Deployment Not Starting

```bash
# Check deployment status
dap-bpa orchestrator deployments get <id> --fields id display_name deployment_status installation_status

# Check latest execution
dap-bpa orchestrator deployments get <id> --fields id latest_execution_id latest_execution_status
```

Common causes:
- Missing secrets (check `dap-bpa orchestrator secrets list` against blueprint requirements)
- Plugin not installed (check `dap-bpa orchestrator plugins list`)
- Blueprint validation errors (run `dap-bpa blueprint lint --file <blueprint>`)

## Blueprint Upload Failed

```bash
# Get blueprint state
dap-bpa orchestrator blueprints get <id> --fields id state upload_execution

# If upload_execution exists, check its events
dap-bpa orchestrator events get <upload_execution_id>
```

## Upload Error Reference

| Error Message | Cause | Solution |
|---|---|---|
| `"Archive must contain exactly 1 directory or multiple directories together with manifest.yaml"` | Archive has loose files at root level (no wrapping directory) | As of v0.15.0, `.zip` archives are auto-repacked with a wrapping directory. For `.tar.gz`, re-create with exactly 1 directory at root containing all files. If using an older version, re-create the archive correctly or pass the `blueprint.yaml` file directly. |
| `"<filename>.yaml does not exist in the application directory"` | Blueprint YAML not found at expected path inside archive | Use `--application-file-name <name>` to specify the correct YAML entrypoint (e.g. `--application-file-name blueprint.yaml`) |
| `"<filename>.zip does not exist in the application directory"` | Old CLI bug: archive filename was used as `application_file_name` instead of the YAML inside | Upgrade `dap-bpa` to v0.13.0-20260312+ which auto-detects the YAML, or use `--application-file-name blueprint.yaml` |
| `HTTP 413: Request Entity Too Large` | Archive too large for upload | Remove unnecessary files, pass `blueprint.yaml` directly instead of a pre-built archive |
| `"Cannot create a revision of a blueprint with modified main_file_name"` | Trying to upload revision with different internal filename from first upload | Use same internal YAML filename as the original upload, or create a new blueprint ID |
| `"failed_extracting"` state | Archive structure or content issues | Check blueprint state error field: `dap-bpa orchestrator blueprints get <id> --fields id state error` |

**Version Compatibility Notes:**
- All blueprints must use `dell_1_1` (TD-001). Do not use `dell_1_0` or any other version.

**Debugging Upload Issues:**
1. Check blueprint state and error: `dap-bpa orchestrator blueprints get <blueprint_id> --fields id state error revisions`
2. If state is `failed_extracting` or `invalid`, the `error` field contains the specific reason
3. For archive structure issues, re-create following the requirements above, or simply pass the `blueprint.yaml` file directly

## Common Runtime Error Patterns

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `secret not found` | Missing secret in orchestrator | Create the secret via UI or API |
| `plugin not found` | Plugin not uploaded | Upload the required plugin |
| `connection refused` | Target host unreachable | Check network / firewall / VPN |
| `authentication failed` | Expired or invalid credentials | Refresh token, check secrets |
| `quota exceeded` | Cloud provider limit reached | Request quota increase or clean up |


## Script Execution Failures (Fabric Plugin)

When `fabric_plugin.tasks.run_script` fails, the event log reports `return_code`, `stdout`, and `stderr` for the script execution. Use `dap-bpa orchestrator events get <execution_id>` to find these values.

### Empty stdout/stderr with non-zero return code

The most common cause is a **shell syntax error** — the script uses bash-specific syntax (e.g. `< <(...)`, `[[ ]]`, `set -o pipefail`) but the Fabric plugin executes via `sh`, not `bash`. The script fails at parse time before producing any output.

**Diagnosis:**
1. Check the event log for the `run_script` task — look for `return_code`, `stdout`, `stderr`
2. If stdout and stderr are both empty (or contain only a shebang line), the script likely failed at parse time
3. Review the script for bash-specific constructs (see Fabric plugin skill → Best Practices → item 8)

**Fix:** Rewrite the script to be POSIX `sh` compatible. Use `#!/bin/sh`, `set -eu`, and avoid all bash-isms.

### Script runs but produces unexpected results

**Diagnosis:**
1. Add `set -x` to the top of the script — this enables command tracing and all executed commands appear in stdout
2. Add an EXIT trap to capture the failing line:
   ```sh
   trap 'echo "ERROR: failed at line $LINENO (exit $?)" >&2' EXIT
   ```

---

## Lint Error Fix Guide

After every `dap-bpa blueprint lint` run, apply this protocol for each error code. Re-run the linter after each fix pass and repeat until `errorsFound: false` or all remaining errors are confirmed false positives.

### `dsl-duplicate-block`

Extract the repeated block into `dsl_definitions` as a named anchor. Replace every occurrence in the file with an alias. The anchor and all its aliases must be in the same file — YAML anchors cannot cross file boundaries. If the duplicate spans imported files, define the anchor in `blueprint.yaml` and inline the values in the imported files instead.

### `no-unused-inputs`

Find the node that should consume this input and wire it in via `get_input`. If no node needs it, remove the input and its entry from `input_groups`.

### `parse-error: Unresolved alias`

The alias references an anchor defined in another file. YAML aliases cannot cross file boundaries. Fix in order of preference:

1. Move the node that uses the alias into the same file as the anchor
2. Duplicate the anchor definition into the file that uses it
3. Inline the values directly — remove the alias entirely

### `node-missing-lifecycle` (no delete)

Add a delete operation to the node. If the node is ephemeral or read-only (e.g. a lookup node), implement delete as a no-op Python script following the pattern in `dap-scripts/SKILL.md`.

### `unused-imports`

Check whether the plugin's node types are actually used in the blueprint. If yes, this is a known false positive for the utilities plugin (its types use non-standard prefixes) — leave it. If genuinely unused, remove the plugin import.

### `input-constraint-no-error-message`

Add `error_message: "<description of what's valid>"` indented under the constraint, at the same level as the constraint key.

### `node-template-interface-operation-valid`

Remove unsupported keys from the operation. Valid keys are: `executor`, `implementation`, `inputs`, `max_retries`, `retry_interval`. Remove `timeout` — use `retry_interval` and `max_retries` instead if retry behaviour is needed.

### Fix loop

After applying fixes, re-run the linter:

```bash
dap-bpa blueprint lint --file blueprint.yaml --verify
```

Repeat until `errorsFound: false` or until all remaining errors are confirmed false positives. Document which errors are false positives and why. Do not stop after one fix pass.