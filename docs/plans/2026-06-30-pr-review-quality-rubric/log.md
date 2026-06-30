# Spec-log — pr-review-loop code-quality rubric

Bundle log per `.claude/rules/03-logging.md` (spec-log altitude): load-bearing decisions,
discarded alternatives, and in-flight deviations. Append-only, oldest-first.

---

## 2026-06-30 01:00 — Improve pr-review-loop rather than vendor a standalone thermo-nuclear skill

**Decision:** Lift the core patterns of Cursor's `thermo-nuclear-code-quality-review` (MIT) into
the existing `pr-review-loop` skill instead of vendoring it as a standalone review skill.
**Why:** the lab already has five review surfaces (`/code-review`, `/simplify`, pr-review-toolkit
agents, pr-review-loop); a 6th invites "which do I run when?" sprawl. pr-review-loop has the gap
the rubric fills (no substantive code-quality rubric) and the machinery to drive findings to a bar.
**Alternatives:** standalone `thermonuclear-review` plugin — rejected, adds a parallel tool and
duplicates the merge-bar/issue-filing machinery. Pull the whole `thermos` system (correctness +
security + orchestrator) — rejected, overlaps `/code-review` + `/security-review` hard.

---

## 2026-06-30 01:30 — Backoff lifecycle for simplification findings (pin b + decay schedule)

**Decision:** Two-tier rubric. `[regression]` findings (1k-line crossing in-diff, spaghetti branch
into unrelated flow, feature-logic leak) are hard Blockers throughout. `[simplification]` findings
decay: **Blocker at age 0 (one critical-blocking cycle), Important at age 1–2, follow-up issue at
any terminal (cap, merge-ready, or age ≥ 3)**. Outstanding simplifications are filed as issues on
every terminal exit path.
**Why:** thermo-nuclear's "block on any missed simplification" stance cannot fold verbatim into a
convergence-seeking loop — the 0-Blocker bar must stay reachable. Backoff gives one cycle of real
push (teeth) then steps aside (convergence); the issue-fallback guarantees nothing is dropped.
**Alternatives:** never-gate (advisory only) — rejected, the bar gains no structural teeth.
Harsh/full-thermo presumptive blockers — rejected, loop may never reach 0 Blockers and interrupts
every cycle. Demote-on-first-recurrence (one nudge) — superseded by the owner's explicit
1-Blocker-then-2-Important schedule.

---

## 2026-06-30 02:00 — Reuse existing machinery; no parallel loop

**Decision:** Recurrence/age detection reuses Step 6's overlap mechanism; issue-filing reuses Step
7.5; the terminal fallback extends Step 2 (max_iter) and Step 7 (close-out). Only one new state
field (`deferred_simplifications`).
**Why:** minimises new state and regression risk in a shipped tool; a recurring simplification that
self-demotes also reduces false stuck-interrupts (a free win on the existing Step 6 alarm).

---

## 2026-06-30 03:00 — Deviation: ledger entry carries `finding_text` beyond the planned schema

**Decision:** `deferred_simplifications` entries are `{fingerprint, first_seen_pass, age, finding_text}`
— `finding_text` added to the plan's `{fingerprint, first_seen_pass, age}`.
**Why:** the max_iter terminal (Step 2) files outstanding simplifications as issues with **no live
review file** to source prose from (the review ran on the prior pass). Persisting `finding_text` in
the ledger is the only way the terminal can build the issue body. Minimal, additive; does not change
the lifecycle. Logged per the deviation-from-approved-plan routing in `.claude/rules/03-logging.md`.

---

## 2026-06-30 03:30 — Gate evidence: backoff lifecycle hand-trace (Task 3 verification)

**Decision:** Task 3's lifecycle verified by hand-trace (no automated gate exists for prompt logic).
`max_iterations = 5` throughout; S1 = a `[simplification]`, R = a `[regression]`.

- **T1 — schedule (S1 deferred, no regression).** P1: Step 5 `hard_blocker_count=0`,
  `simplifications_this_pass=[S1]`; Step 6 skipped (empty hard text); Step 6.5 first-sees S1 →
  age 0 → Blocker → `effective_blocker_count=1` → Step 8 → design-pin → one interrupt → user defers →
  no edit → Step 9.0 skips commit → Step 10 persists ledger `[{S1,age0}]`. **S1 = Blocker@age0.**
  P2: fresh review re-raises S1; Step 6 skipped (S1 is NOT in hard text → no false stuck though it
  recurred); Step 6.5 matches → age 1 → Important; `age0_simplifications=[]` →
  `effective_blocker_count=0` → Step 7 merge-ready → Step 7.5 folds S1 from the ledger into
  `issues_to_file` → filed (P2-backlog), ledger cleared. **S1 = Important@age1 → issue@terminal.**
- **T2 — age reaches 2.** If hard regressions keep `effective_blocker_count>0` through P1–P3
  (without >50 % hard-text overlap, so no stuck), S1 reads Blocker@age0(P1) → Important@age1(P2) →
  Important@age2(P3); the first terminal (merge-ready or max_iter) files it. **Covers age 1–2.**
- **T3 — max_iter discharge.** Loop never clears its regressions, reaches pass 6 > max ⇒ Step 2:
  `len(deferred_simplifications)≥1` → deferred-simplification filing routine files each as an issue
  (consent asked once if never captured) → cleanup → exit. **No simplification dropped at the bound.**
- **T4 — regressions DO trip stuck (contrast).** An unfixed R recurring with >50 % `hard_blocker_text`
  overlap fires Step 6's stuck-detector (R is in hard text); a recurring S1 never does. Confirms the
  self-demote / no-false-stuck property.
- **T5 — clean PR converges.** S1 = a trivial extraction (mechanical): Step 8 auto-fixes it P1 → P2
  fresh review drops it → ledger reconcile removes it (resolved, **no** issue) → `effective=0` →
  merge-ready at 0 hard Blockers within `max_iterations`.

**Refs:** PROMPT.md Steps 2 / 5 / 6 / 6.5 / 7.5 / 8 / 9 / 10; scripts/setup.sh seed.

---

## 2026-06-30 04:30 — Fingerprint on a structural `target:` key, not the finding's prose

**Decision:** The simplification ledger fingerprints each `[simplification]` on a `(target: <file>::<symbol>)`
key the reviewer emits from the code, not on a normalized slug of the finding's first sentence. Matching
is exact on the normalized target. The reviewer is required to emit it (`review-format.md`,
`code-quality-rubric.md`); a missing target degrades to the old slug with a flagged-in-summary warning.
**Why:** the loop dispatches a fresh, un-anchored review each pass, so reviewers re-word the same finding
independently; a prose-derived fingerprint never re-matches, which (a) stalls aging — a re-worded
recurrence reads as first-seen, re-blocking every cycle — and (b) silently drops a live finding mis-read
as resolved. A code-derived key (the named symbol/construct) is stable across re-wordings, so the backoff
arc actually holds. Surfaced by the pass-2 (Opus) audit of PR #5.
**Alternatives:** carry the prior ledger's fingerprints into the fresh reviewer's brief — rejected, breaks
the no-anchoring outsider posture the whole loop depends on. Coarse file-path-only key — rejected, collides
distinct smells in one file. Scope-cut the backoff to a follow-up — considered; owner chose fix-properly.
**Refs:** PROMPT.md Step 5.4; reference/review-format.md; reference/code-quality-rubric.md.

---

## 2026-06-30 04:31 — Terminal discharge centralized; decline = no gh-identity post

**Decision:** (a) All six terminal exit paths (max_iter, stuck-abort, merge-ready, and the error-aborts at
Steps 4.4 / 5.3 / 9.8) discharge the deferred-simplification ledger via one shared "ledger-discharge step"
before cleanup. (b) The filing routine fires its own context-accurate consent question rather than reusing
Step 7.1's merge-ready wording. (c) A declined consent (`false`) performs **no** `gh`-identity post anywhere
— no PR comment, no issue filing — and surfaces the would-be posts in the summary for manual handling;
branch-commit fixes still apply.
**Why:** the pass-2 audit found three error-abort terminals silently dropped the ledger (violating "no silent
drops on every terminal"), and the reused Step 7.1 text made false claims ("hit 0 Blockers", "post the final
comment") in every context the filing routine actually fired. The prior "decline still files issues" also
contradicted the global rule that declining a user-identity action posts nothing.
**Refs:** PROMPT.md terminal-cleanup routine + Steps 2 / 4.4 / 5.3 / 6.2 / 7.1 / 7.5 / 9.8.
