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

- After `dap-bpa lint-blueprint` passes and the blueprint is ready to test on a real environment
- Before committing a new or changed blueprint to version control

### How to start

If the user attaches or mentions a blueprint file (e.g. `my-blueprint.yaml` or drags a file into the chat), use its path directly:

```bash
dap-bpa monitor --file <path-to-blueprint.yaml>
# with inputs:
dap-bpa monitor --file <path-to-blueprint.yaml> --inputs '{"key": "value"}'
# fire-and-forget (returns immediately, runs in background):
dap-bpa monitor --file <path-to-blueprint.yaml> --detach
```

In attached mode (default), the terminal shows live step-by-step progress and a final success/failure summary.
In detached mode (`--detach`), returns immediately with `{ status: "in_progress", session_id, deployment_id, ... }`.
The user receives an OS notification when it finishes.

### How to check status

```bash
dap-bpa monitor --status          # most recent active session
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

When the session finishes, `dap-bpa monitor --status` returns a full `RunReport`. Key fields:

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
- Manual `dap-bpa deploy` / `dap-bpa execution start` while a monitor session is active for the same blueprint

### Setup

The monitor requires an LLM adapter to perform auto-fixes. Run `dap-bpa setup` and follow Step 3b (Diagnostician) to configure one. Supported adapters: Bedrock, OpenAI, Claude Code, Devin.
