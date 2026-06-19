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

## Sample D — Load-bearing decision with gate visibly firing (Tier 2 write behavior)

### Candidate moment

During design of the storage layer in `example-repo`, a decision was made to use SQLite as
the embedded database rather than LevelDB or a flat JSON store. LevelDB was ruled out because
it requires a C++ native dependency that complicates cross-platform packaging; flat JSON was
ruled out due to lack of transactional integrity. SQLite satisfies durability and atomicity
requirements within the single-process constraint.

### Classification walkthrough

**Trigger 1 — Load-bearing decision?**
- Real alternatives considered (LevelDB, flat JSON store, SQLite): YES.
- Reversal requires redesigning the storage layer, re-migrating data, and updating the
  packaging manifest: YES.
- Both tests pass → **Trigger 1 fires. Verdict: LOGGABLE. Tier 2 (decision gate required).**

**Bare-status guard:** carries rationale and weighed alternatives — guard does not apply.

### Altitude routing

- Cross-repo? No — the event concerns `example-repo` only.
- Matters after the plan ships? Yes — the storage-engine choice outlives the implementation
  plan and constrains future migration and packaging work.
- → **Project altitude** → `example-repo/project_log.md`

### Target surface

`example-repo/project_log.md` → top-insert at head of `## Entries` section.
Add matching index line to `## Standing Decisions` (same change).

### Format shape produced (DRAFT — NOT written)

The skill presents the following draft and **halts before writing anything**:

```
DRAFT — held for approval before any write:

---

## 2026-06-18 14:30 — chose SQLite over LevelDB and flat JSON for storage layer

**Decision:** example-repo storage layer uses SQLite as the embedded database; LevelDB and
flat JSON store both ruled out.
**Why:** LevelDB introduces a C++ native dependency that breaks cross-platform packaging;
flat JSON lacks transactional integrity; SQLite satisfies durability and atomicity within
the single-process constraint at no packaging cost.
**Alternatives:** LevelDB (native-dependency blocker), flat JSON store (no transactions).
**Refs:** #31, C:/Users/watso/Development/example-repo/docs/storage-design.md

---

Standing Decisions index line (add to ## Standing Decisions):
- 2026-06-18 14:30 — chose SQLite over LevelDB and flat JSON for storage layer · #31

---

Target file:  C:/Users/watso/Development/example-repo/project_log.md
Insertion:    Top of ## Entries section, preceded by `---` + blank line

Awaiting approval — nothing written.
Approve to write, or revise the text above before proceeding.
```

### Write status

**WRITE GATED — gate fired. No write has been performed.**

The gate is the hard invariant from `write-tiers.md` § Tier 2: a load-bearing-decision entry
is never written to a project/lab log until the human explicitly approves the drafted text.
No autonomy mode or inline continuation bypasses it.

On approval, the skill writes exactly the entry and index line shown above — byte-for-byte —
to `example-repo/project_log.md`, then confirms. Nothing is written until that approval is
received.

---

## Sample E — Bare status auto-drafted to PR comment

### Candidate moment

After merging PR #22 in `example-repo`, the CI pipeline ran green. The session note reads:
"Merged PR #22. CI green. Branch deleted."

### Classification walkthrough

**BARE-STATUS GUARD (checked first):** "Merged PR #22. CI green. Branch deleted." can be
posted verbatim as a PR comment without losing meaning. Guard fires immediately.

**Verdict: ELSE-ROUTE.** Else-routes table: "Bare status" → **PR comment.**
No project-log entry. No index line.

### Altitude routing

Bare-status else-route → does not route to any log altitude. Target is a PR comment.

### Target surface

A comment posted to PR #22 in `example-repo`. No write to any `project_log.md`.

### Format shape produced (DRAFT — NOT written to any log)

The skill auto-drafts a PR-comment artifact. **Tier 1 — no gate required for this surface.**

PR comment draft:

```
Merge closeout — PR #22

- Merged: 2026-06-18 14:30
- CI: green
- Branch cleanup: branch deleted post-merge
```

### Write status

**NO project-log write. No index line.** Auto-drafted to PR comment only. The draft above
is the artifact that would be posted to PR #22; no `project_log.md` is touched.

---

## Sample F — Irreversible/external event auto-drafted to project log (no index line)

### Candidate moment

The `example-repo` v1.2.0 release was published to PyPI. This is a durable, externally
observable event — the package is now publicly indexed and cannot be unpublished without
a new release.

### Classification walkthrough

**BARE-STATUS GUARD:** "Published v1.2.0 to PyPI" is not bare status — it crosses an
external system boundary and is permanently indexed. Guard does not fire.

**Trigger 2 — Irreversible/external event?**
- Release published to an external registry (PyPI): YES.
- Externally observable in a durable way: YES.
- → **Trigger 2 fires. Verdict: LOGGABLE. Tier 1 (auto-draft; no gate required).**

No index line is emitted for Trigger 2 events (per `write-tiers.md` summary table and
`entry-format.md` § 3).

### Altitude routing

- Cross-repo? No — `example-repo` only.
- Matters after the plan ships? Yes — a published release is a durable external event.
- → **Project altitude** → `example-repo/project_log.md`

### Target surface

`example-repo/project_log.md` → top-insert at head of `## Entries`. **No index line.**

### Format shape produced (DRAFT — auto-applied without gate)

```
---

## 2026-06-18 14:30 — published example-repo v1.2.0 to PyPI

**Decision:** v1.2.0 release published to PyPI; package now publicly indexed.
**Why:** scheduled release cadence; all acceptance tests green; changelog finalized.
**Refs:** #28, https://pypi.org/project/example-repo/1.2.0/
```

### Write status

**Tier 1 — auto-applied. No gate.** No Standing Decisions index line is emitted (Trigger 2
events do not produce index lines). Entry is inserted top-of-entries, preceded by `---` and
a blank line.

---

## Sample G — Reversal (superseding entry) and contrasting typo-fix via `log-lint:override`

### Candidate moment (G-1: reversal)

An earlier decision logged at `2026-03-01 09:00` chose SQLite over LevelDB and flat JSON
(a hypothetical prior entry — distinct from Sample D's 2026-06-18 entry for illustration).
A new architectural review found that the multi-process access pattern introduced since then
makes SQLite's write-lock semantics untenable. PostgreSQL is now chosen as the replacement.

### Classification walkthrough

**Trigger 1 — Load-bearing decision?**
- Real alternatives considered (stay on SQLite, migrate to PostgreSQL, introduce a queue): YES.
- Reversal requires replacing the storage driver, running a migration, and updating packaging: YES.
- Both tests pass → **Trigger 1 fires. Verdict: LOGGABLE. Tier 2 (decision gate required).**
- Additionally: this reversal requires a `Supersedes:` field naming the prior entry verbatim.

### Altitude routing

- Cross-repo? No — `example-repo` only.
- → **Project altitude** → `example-repo/project_log.md`

### Target surface

`example-repo/project_log.md` → top-insert at head of `## Entries`. Add new index line to
`## Standing Decisions`. In the **same change**, remove the superseded index line for
`2026-03-01 09:00 — chose SQLite over LevelDB and flat JSON for storage layer`. The body
of the original entry is **never edited**.

### Format shape produced (DRAFT — NOT written)

```
DRAFT — held for approval before any write:

---

## 2026-06-18 14:30 — migrated storage layer from SQLite to PostgreSQL

**Decision:** example-repo storage layer migrated to PostgreSQL; SQLite retired.
**Why:** multi-process write access introduced since the original decision triggers SQLite's
write-lock, causing request queuing under load; PostgreSQL handles concurrent writers
natively and fits the updated deployment model.
**Alternatives:** stay on SQLite with a single writer process (requires re-scoping the
architecture); introduce a queue layer over SQLite (complexity cost exceeds migration cost).
**Supersedes:** 2026-03-01 09:00 — chose SQLite over LevelDB and flat JSON for storage layer
**Refs:** #44, C:/Users/watso/Development/example-repo/docs/storage-migration.md

---

Standing Decisions index line (add to ## Standing Decisions):
- 2026-06-18 14:30 — migrated storage layer from SQLite to PostgreSQL · #44

Index line to REMOVE from ## Standing Decisions (same change; entry body untouched):
- 2026-03-01 09:00 — chose SQLite over LevelDB and flat JSON for storage layer · #31

---

Target file:  C:/Users/watso/Development/example-repo/project_log.md
Insertion:    Top of ## Entries section, preceded by `---` + blank line

Awaiting approval — nothing written.
Approve to write, or revise the text above before proceeding.
```

### Write status

**WRITE GATED — gate fired. No write has been performed.**

On approval, the skill writes the new entry and index line, and removes the superseded index
line — all in one change (one PR at project altitude). The original `2026-03-01 09:00` entry
body is left byte-for-byte intact; history keeps both entries. The index removal is staged as
part of the same change, not a follow-up.

---

### Candidate moment (G-2: contrasting typo-fix — NOT a supersession)

Suppose the Sample G-1 entry had instead been committed with `#43` in `Refs:` by mistake.
The `2026-06-18 14:30` entry above has a wrong PR number in its `**Refs:**` line — the squash
SHA commit was used in error; the correct PR is #44 but `#43` was written. No meaning changed;
only a factual identifier is wrong.

### Classification walkthrough

**This is NOT a reversal of meaning.** The decision stands; only a PR number is incorrect.
The correct path is the `log-lint:override` route — not a new `Supersedes:` entry and not a
silent edit.

The skill **refuses to silently edit** the merged entry and **refuses to draft a superseding
entry** (which would be semantically wrong — the decision was not reversed). Instead it
surfaces the labeled-PR path:

```
This is a factual typo fix (wrong PR# in Refs:), not a reversal. The correct path is:

1. Create a branch with only the corrected Refs: line in the entry body.
2. Open a PR carrying the `log-lint:override` label.
3. PR body explains: "corrects PR# in Refs: from #43 to #44; squash SHA was used in error."

The skill does not apply this correction directly. A silent edit is not permitted.
A new Supersedes: entry is not appropriate — the decision itself is unchanged.
```

### Write status

**NO write performed.** The skill names the `log-lint:override` PR path and stops. The two
distinct paths — supersession for reversals of meaning, `log-lint:override` for factual
fixes — are mutually exclusive and the skill refuses to conflate them.

---

## Sample H — Lab-altitude entry (Refs are absolute paths/URLs, not PR#)

### Candidate moment

A cross-repo decision was made to adopt a unified backlog format (`Development/BACKLOG.md`)
as the single-source task queue across all lab repos. Previously, each repo maintained its
own ad-hoc issue list. This affects lab-os conventions and every active repo.

### Classification walkthrough

**Trigger 1 — Load-bearing decision?**
- Real alternatives considered (per-repo issue lists, a GitHub Project board, the unified
  backlog format): YES.
- Reversal requires updating lab-os conventions and migrating all active repos back to
  per-repo issue lists: YES.
- Both tests pass → **Trigger 1 fires. Verdict: LOGGABLE. Tier 2 (decision gate required).**

### Altitude routing

- Cross-repo? YES — the decision touches lab-os conventions and every active repo.
- → **Lab altitude** → `C:/Users/watso/Development/project_log.md`
- Lab-altitude caveat applies: **Refs must be absolute paths/URLs — never a PR#.** The lab
  log has no git/CI, so PR numbers are meaningless as durable references.

### Target surface

`C:/Users/watso/Development/project_log.md` → top-insert at head of `## Entries`. Add index
line to `## Standing Decisions`.

Immutability at lab altitude: begins once a newer entry exists (no PR/merge event to anchor
to), enforced on the honor system.

### Format shape produced (DRAFT — NOT written)

```
DRAFT — held for approval before any write:

---

## 2026-06-18 14:30 — adopted unified backlog format as single-source task queue

**Decision:** Development/BACKLOG.md is the single-source task queue for all active lab
repos; per-repo ad-hoc issue lists retired.
**Why:** per-repo lists caused cross-repo tasks to be tracked inconsistently and missed in
planning sweeps; the unified format (PRD+plan packets) provides a single surface for
prioritisation and overnight-agent execution.
**Alternatives:** GitHub Project board (requires network access, not local-first; adds
external dependency); per-repo issue lists maintained (root cause of the fragmentation
problem).
**Refs:** C:/Users/watso/Development/BACKLOG.md,
          C:/Users/watso/Development/lab-os/.claude/rules/01-workflow.md

---

Standing Decisions index line (add to ## Standing Decisions):
- 2026-06-18 14:30 — adopted unified backlog format as single-source task queue · C:/Users/watso/Development/BACKLOG.md

---

Target file:  C:/Users/watso/Development/project_log.md
Insertion:    Top of ## Entries section, preceded by `---` + blank line

Awaiting approval — nothing written.
Approve to write, or revise the text above before proceeding.
```

Note: the `·` separator in the index line is followed by an absolute path, not a PR#, because
the lab log has no git/CI. The path points to the owning artifact — the durable reference at
lab altitude.

### Write status

**WRITE GATED — gate fired. No write has been performed.**

Lab-altitude-specific behavior: on approval, the skill writes the entry and index line to
`C:/Users/watso/Development/project_log.md`. No PR# appears anywhere in the entry or index
line — absolute paths/URLs are the only durable refs at this altitude. Immutability begins
once a newer entry is prepended (honor-system, no CI guard).
