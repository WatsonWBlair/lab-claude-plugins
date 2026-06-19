# Trigger Classification — Project Log Entry Decision Procedure

Source of truth: `lab-os/.claude/rules/03-logging.md` § Entry triggers.
This file is an operational restatement. If wording in the source diverges from this file, the source wins.

---

## Decision procedure

Run the candidate moment through the three triggers in order. First trigger that fires → verdict is **loggable** at that trigger. If none fire → verdict is **else-route**; pick the single matching home from the else-routes table. One verdict out, never ambiguous.

---

## Trigger 1 — Load-bearing decision

**Fires when:** a decision was made among real alternatives, and reversing it would change direction or architecture.

Tests:
- Were real alternatives considered (not just one path)? If no → not this trigger.
- Does reversal require re-scoping, re-designing, or rebuilding? If no → not this trigger.

Both must be true. A decision with no serious alternatives is not load-bearing.

---

## Trigger 2 — Irreversible/external event

**Fires when:** an event has occurred that cannot be undone or that crosses a system boundary.

Canonical examples (not exhaustive): release published, migration executed, secret rotated, org/repo setting changed, data published externally.

Tests:
- Is the event complete (past tense, not planned)? If no → not this trigger.
- Is it irreversible, or does it cross an external boundary? If no → not this trigger.

Both must be true.

---

## Trigger 3 — Direction change / re-scope

**Fires when:** the project's direction, scope, or active plan is being superseded.

Canonical examples: pivot, pause, reactivation, supersession of a spec or plan.

Note: pausing or retiring a project also requires a README top banner — `Status: paused YYYY-MM-DD — see lab log`. The log entry and the banner are both required; neither substitutes for the other.

Tests:
- Does this supersede an existing spec, plan, or project direction? If no → not this trigger.

---

## BARE STATUS GUARD — read before writing any entry

> **"Merged. Smoke passed." is NOT a project-log entry.**

A bare status fact — a merge confirmation, a CI result, a deploy check, a branch-cleanup note — belongs in a **PR comment**, not the project log. This is the most common wrong-surface failure.

Rule: if the full content of the candidate entry could appear verbatim as a PR comment without losing meaning, it is a PR comment, not a log entry. Route it there.

---

## Else-routes table

If Triggers 1, 2, and 3 all failed to fire, route to exactly one home:

| Candidate moment | Home |
|---|---|
| Deviation from an approved plan | Plan doc `## Execution Log` |
| Expensive finding or gotcha | `TROUBLESHOOTING.md` or GitHub issue |
| Open work, follow-up, review finding | GitHub issue |
| Bare status ("merged, smoke passed") | PR comment |
| Session narrative / what-I-did | PR body |
| Long-lived people or preference fact | Auto-memory |

**Exception — trigger-meeting review findings:** a review finding that independently satisfies Trigger 1, 2, or 3 is additionally logged under that trigger. Filing a GitHub issue is still required; the log entry is also required. The issue and the log entry are not substitutes for each other.

No candidate matches more than one home. If a candidate could plausibly match two, it is a sign the moment contains multiple distinct pieces of information — split them and route each separately.

---

## Quick-reference verdict table

| Candidate moment | Verdict | Trigger or home |
|---|---|---|
| Chose approach A over B and C after real tradeoff analysis | **loggable** | Trigger 1 — Load-bearing decision |
| Published the v1.0 release | **loggable** | Trigger 2 — Irreversible/external event |
| Rotated a secret | **loggable** | Trigger 2 — Irreversible/external event |
| Pivoted from approach X to approach Y | **loggable** | Trigger 3 — Direction change |
| Paused FCM_Analysis project | **loggable** | Trigger 3 — Direction change (+ README banner) |
| "Merged PR #42, smoke passed" | **else-route** | PR comment |
| Ran deploy, CI green | **else-route** | PR comment |
| Used a different library than the plan specified | **else-route** | Plan doc `## Execution Log` |
| Hit an obscure env-setup gotcha | **else-route** | `TROUBLESHOOTING.md` or GitHub issue |
| Opened three follow-up tasks | **else-route** | GitHub issues |
| Watson prefers dense AI-tier doc voice | **else-route** | Auto-memory |
