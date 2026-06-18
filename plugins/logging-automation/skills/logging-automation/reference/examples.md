# Worked Examples — Dry Classification and Routing

Phase-A integration checkpoint. Three sample moments are walked end-to-end through
classification → altitude → target surface → exact format shape. **No file write is
performed by any example in this file.** The entries below are drafts only — each is
held for human approval (write-gated) or routed to a non-log surface.

Source references used throughout: `trigger-classification.md`, `altitude-routing.md`,
`entry-format.md`.

Synthetic date/time used for all headers: **2026-06-18 14:30**. No real content from any
gated dataset appears. Repo names and paths are fabricated.

---

## Sample A — Load-bearing decision (loggable → project altitude)

### Candidate moment

During implementation of the auth module in `example-repo`, a decision was made to use
token-based session authentication rather than cookie-based sessions or OAuth delegation.
Cookie sessions were ruled out due to cross-origin limitations in the deployment topology;
OAuth delegation was ruled out as premature given the single-tenant scope. Token-based auth
was chosen as the fit-for-purpose option given current constraints.

### Classification walkthrough

**Trigger 1 — Load-bearing decision?**
- Real alternatives considered (cookie sessions, OAuth delegation, token-based): YES.
- Reversal would require re-designing the session layer and re-scoping the auth module: YES.
- Both tests pass → **Trigger 1 fires. Verdict: LOGGABLE.**

Triggers 2 and 3 are not evaluated once Trigger 1 fires (first-match rule per
`trigger-classification.md` § Decision procedure).

**Bare-status guard:** this is not a bare status — it carries decision rationale and weighed
alternatives. Guard does not apply.

### Altitude routing

- Cross-repo? No — the event concerns `example-repo` only.
- Matters after the plan ships? Yes — the session-layer choice outlives any individual
  implementation plan and constrains future auth work.
- → **Project altitude** → `example-repo/project_log.md`

### Target surface

`example-repo/project_log.md` → prepend under `## Entries` (top-insert, reverse-chron).
Add matching index line to `## Standing Decisions`.

### Format shape produced (DRAFT — NOT written)

Full entry (grammar from `entry-format.md` § 1; separator from § 2):

```
---

## 2026-06-18 14:30 — chose token-based auth over cookie sessions and OAuth delegation

**Decision:** auth module uses token-based session authentication; cookie sessions and OAuth
delegation both ruled out.
**Why:** cookie sessions fail under the cross-origin deployment topology; OAuth delegation is
premature for a single-tenant scope; token-based auth satisfies current constraints without
over-engineering.
**Alternatives:** cookie sessions (cross-origin blocker), OAuth delegation (out-of-scope
complexity).
**Refs:** #12, C:/Users/watso/Development/example-repo/docs/auth-design.md
```

Standing Decisions index line (grammar from `entry-format.md` § 3; `—` is U+2014, `·` is
U+00B7):

```
- 2026-06-18 14:30 — chose token-based auth over cookie sessions and OAuth delegation · #12
```

### Write status

**WRITE GATED — held for human approval. No write has been performed.**
The entry and index line above are the exact artifact that would be written upon approval.

---

## Sample B — Bare status ("merged, smoke passed") → else-route → PR comment

### Candidate moment

After merging PR #17 in `example-repo`, the CI pipeline ran green and a quick smoke check
confirmed the feature endpoint returned the expected response. The session note reads:
"Merged. Smoke passed."

### Classification walkthrough

**BARE-STATUS GUARD (checked first, per `trigger-classification.md` § BARE STATUS GUARD):**
The full content — "Merged. Smoke passed." — can appear verbatim as a PR comment without
losing meaning. Guard fires immediately.

**Trigger 1 — Load-bearing decision?**
No decision was made; this is a completion status. → NOT this trigger.

**Trigger 2 — Irreversible/external event?**
A merge is technically irreversible, but the rule in `trigger-classification.md` quick-reference
table explicitly classifies "Merged PR #42, smoke passed" as else-route → PR comment. The
trigger requires the event to cross a system boundary or be externally observable in a durable
way (release published, secret rotated, data published). A routine PR merge with CI green does
not clear that bar.
→ NOT this trigger.

**Trigger 3 — Direction change / re-scope?**
No direction or scope change. → NOT this trigger.

**Verdict: ELSE-ROUTE.** Else-routes table match: "Bare status ('merged, smoke passed')" →
**PR comment.**

### Altitude routing

Else-routes do not route to a log altitude. Target is a PR comment on PR #17.

### Target surface

A comment posted to PR #17 in `example-repo`. No write to any `project_log.md`.

### Format shape produced (DRAFT — NOT written to any log)

PR comment draft:

```
Merge closeout — PR #17

- Merged: 2026-06-18 14:30
- CI: green
- Smoke check: feature endpoint returned expected response
- Branch cleanup: branch deleted post-merge
```

### Write status

**NO project-log write. No index line.** This moment routes exclusively to a PR comment.
The draft above is what would be posted to PR #17; no project log is touched.

---

## Sample C — Plan deviation → else-route → plan-execution one-liner

### Candidate moment

During execution of task 4 of the `example-repo` implementation plan
(`docs/plans/2026-06-15-data-pipeline.md`), the approved plan specified using `pandas` for
CSV parsing. At implementation time, `polars` was substituted because the input files
exceeded the memory limit that `pandas` handles gracefully on the available dev machine.
No architectural decision was revisited; the substitution was a local implementation call
within the bounds of the task.

### Classification walkthrough

**Trigger 1 — Load-bearing decision?**
- Real alternatives considered? Technically yes (pandas vs polars), but:
- Does reversal change direction or architecture? No — this is a library substitution within
  a single task. Swapping back to pandas does not re-scope, re-design, or rebuild anything
  beyond that task.
- Both tests must be true; second test fails. → NOT this trigger.

**Trigger 2 — Irreversible/external event?** No external boundary crossed; no irreversible
system change. → NOT this trigger.

**Trigger 3 — Direction change / re-scope?** No direction or scope change — the pipeline
design is unchanged; only the internal tool changed. → NOT this trigger.

**Verdict: ELSE-ROUTE.** Else-routes table match: "Deviation from an approved plan" →
**Plan doc `## Execution Log`.**

### Altitude routing

Else-routes do not route to a project or lab log. Target is the `## Execution Log` section
of the plan document.

### Target surface

`example-repo/docs/plans/2026-06-15-data-pipeline.md` → append to `## Execution Log`.

### Format shape produced (DRAFT — NOT written to any log)

Plan-execution one-liner (grammar from `entry-format.md` § 4; `·` is U+00B7):

```
2026-06-18 14:30 · task 4 · substituted polars for pandas for CSV parsing; pandas OOM on
available dev machine with input file sizes; no design change, local implementation call
```

### Write status

**NO project-log write. No index line.** Plan-execution entries never emit a Standing
Decisions index line (per `entry-format.md` § 3: "Events and plan-execution entries get NO
index line"). The one-liner above is the exact artifact that would be appended to
`## Execution Log` in `2026-06-15-data-pipeline.md`; no `project_log.md` is touched.

---

## Appending additional samples

Task 10 will add further worked examples. Append new samples after Sample C using the same
section structure: `## Sample D — <label>` etc., with the five subsections
(Candidate moment / Classification walkthrough / Altitude routing / Target surface /
Format shape produced / Write status) in the same order.
