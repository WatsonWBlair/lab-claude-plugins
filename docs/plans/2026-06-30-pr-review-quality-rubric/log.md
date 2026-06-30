# Spec-log — pr-review-loop code-quality rubric

Bundle log per `.claude/rules/03-logging.md` (spec-log altitude): load-bearing decisions,
discarded alternatives, and in-flight deviations. Append-only, oldest-first.

---

## 2026-06-30 — Improve pr-review-loop rather than vendor a standalone thermo-nuclear skill

**Decision:** Lift the core patterns of Cursor's `thermo-nuclear-code-quality-review` (MIT) into
the existing `pr-review-loop` skill instead of vendoring it as a standalone review skill.
**Why:** the lab already has five review surfaces (`/code-review`, `/simplify`, pr-review-toolkit
agents, pr-review-loop); a 6th invites "which do I run when?" sprawl. pr-review-loop has the gap
the rubric fills (no substantive code-quality rubric) and the machinery to drive findings to a bar.
**Alternatives:** standalone `thermonuclear-review` plugin — rejected, adds a parallel tool and
duplicates the merge-bar/issue-filing machinery. Pull the whole `thermos` system (correctness +
security + orchestrator) — rejected, overlaps `/code-review` + `/security-review` hard.

---

## 2026-06-30 — Backoff lifecycle for simplification findings (pin b + decay schedule)

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

## 2026-06-30 — Reuse existing machinery; no parallel loop

**Decision:** Recurrence/age detection reuses Step 6's overlap mechanism; issue-filing reuses Step
7.5; the terminal fallback extends Step 2 (max_iter) and Step 7 (close-out). Only one new state
field (`deferred_simplifications`).
**Why:** minimises new state and regression risk in a shipped tool; a recurring simplification that
self-demotes also reduces false stuck-interrupts (a free win on the existing Step 6 alarm).
