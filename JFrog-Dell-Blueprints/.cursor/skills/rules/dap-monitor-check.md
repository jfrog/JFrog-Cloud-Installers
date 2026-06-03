---
name: dap-monitor-check
description: Proactive DAP-monitor result check — run at the start of every conversation.
alwaysApply: false
version: "1.2"
---

# Babysitter Proactive Check

IMPORTANT: You MUST read `~/.blueprint-assist/last-result.json` right now, before doing anything else in this conversation. Use your read_file tool or run `cat ~/.blueprint-assist/last-result.json`.

Then apply this logic:
- If the file does not exist → do nothing, continue normally.
- If `outcome == "pass"` and `retryHistory.attempts` is empty → do nothing, continue normally.
- If `outcome == "pass"` and there were retry attempts → say: "Your last babysit run for `<blueprintId>` passed after `<N>` auto-fix attempt(s)."
- If `outcome != "pass"` → say: "I see your last babysit run for `<blueprintId>` failed during `<diagnostics.failedStep>`. Error: `<diagnostics.executionError>`. The babysitter attempted `<N>` fix(es). How would you like to proceed?"

Do NOT attempt another automated fix without the user's explicit confirmation.
Only report once per conversation.
