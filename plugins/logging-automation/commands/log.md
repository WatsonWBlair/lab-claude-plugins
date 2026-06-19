---
description: "Classify, route, and draft an audit-trail log entry for a loggable moment (or the most recent one) per the lab logging rules."
argument-hint: "[<repo>] <what happened>"
---

# /log

Capture a loggable moment as a correctly-routed, correctly-formatted log-entry draft.

**No arguments?** Scan the current conversation for the most recent event that meets a trigger — load-bearing decision, irreversible/external event, or direction change/re-scope. Surface it for confirmation before proceeding. This is not an error; on-demand capture from context is the default no-arg behavior.

**With arguments?** The optional leading `<repo>` token narrows altitude routing to a specific project log; the remaining text is the event description.

## Flow

Run the three-step flow defined in `${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/SKILL.md`:

1. **Classify** — apply the trigger decision tree in `${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/trigger-classification.md`. Determine whether the event is loggable and which trigger class it belongs to (load-bearing decision / irreversible or external event / direction change or re-scope). If the event does not meet any trigger, say so and stop — do not draft a spurious entry.

2. **Route** — apply the altitude rules in `${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/altitude-routing.md`. Resolve the owning log file (lab / project / plan-execution) and state it explicitly before drafting.

3. **Draft** — produce the entry in the canonical format defined in `${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/entry-format.md`. Consult `${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/examples.md` for correctly-routed examples across all three altitudes. Present the complete draft to the user.

## Output contract

- Present the draft and the resolved owning log path. Do not write, commit, push, or post a PR comment.
- For a load-bearing-decision entry, hold the draft for explicit human approval before any write. State clearly: "Awaiting your go-ahead to write this entry."
- For irreversible/external events and direction changes, the same approval gate applies — no write without confirmation.
- The command never bypasses the comms approval gate.
