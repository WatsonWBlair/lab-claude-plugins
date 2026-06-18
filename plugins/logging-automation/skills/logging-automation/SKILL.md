---
name: logging-automation
description: Use when a load-bearing decision is reached mid-session (real alternatives were weighed, reversal would change direction or architecture); when an irreversible or external event occurs (release, migration, secret rotation, org/repo change, data published); when a direction change or re-scope happens (pivot, pause, reactivation, supersession of a spec or plan); or when the user explicitly invokes /log.
---

# logging-automation

> **Supersedes:** Open-Threads "Logging / Convention Skills / Rules" thread. `lab-os/.claude/rules/03-logging.md` remains the authoritative rules source — this skill applies those rules, never redefines them.

## Overview

This skill turns a loggable moment into a correctly-routed, correctly-formatted log entry. It classifies the event against the three altitude tiers (lab / project / plan-execution), selects the owning log file, drafts an entry in the canonical format, and gates the write behind human approval before committing anything to disk.

Source of truth for all rules this skill applies: `lab-os/.claude/rules/03-logging.md`.

## When to use

- A **load-bearing decision** was just reached: real alternatives were on the table and reversal would change direction or architecture
- An **irreversible or external event** occurred: release cut, migration executed, secret rotated, org or repo setting changed, dataset or artifact published
- A **direction change or re-scope**: pivot, pause, reactivation, or a spec/plan is superseded
- The user explicitly invokes `/log` to record an event they have identified as loggable

## When NOT to use

These cases belong elsewhere — do not fire this skill for them:

| Event | Correct home |
|---|---|
| Deviation from an approved plan | `## Execution Log` in the plan doc |
| Expensive finding or gotcha | `TROUBLESHOOTING.md` or a GitHub issue |
| Open work, follow-ups, review findings | GitHub issues |
| Bare status ("merged, smoke passed") | PR comment |
| Session narrative / what-I-did summary | PR body |
| Long-lived people/preference/project facts | Auto-memory (`~/.claude/projects/.../memory/`) |

## Reference files

- [`${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/trigger-classification.md`](reference/trigger-classification.md) — decision tree: is this event loggable, and which trigger class applies
- [`${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/altitude-routing.md`](reference/altitude-routing.md) — lab vs project vs plan-execution routing rules and owning file paths
- [`${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/entry-format.md`](reference/entry-format.md) — canonical entry template, field rules, byte budget, immutability constraints
- [`${CLAUDE_PLUGIN_ROOT}/skills/logging-automation/reference/examples.md`](reference/examples.md) — worked examples of correctly-routed, correctly-formatted entries across all three altitudes
