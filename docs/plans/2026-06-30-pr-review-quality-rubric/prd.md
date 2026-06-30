# PRD — pr-review-loop code-quality rubric (thermo-nuclear lift)

Date: 2026-06-30 · Repo: lab-claude-plugins · Plugin: pr-review-loop

## Problem

`pr-review-loop`'s per-cycle review subagent has a **structure** contract
(`reference/review-format.md`) and a **fix** contract (`reference/classify-blockers.md`),
but **no substantive code-quality rubric** — what rises to a Blocker on maintainability is
left entirely to subagent judgment. Code PRs get inconsistent structural-quality review.

Cursor's MIT-licensed `thermo-nuclear-code-quality-review` (github.com/cursor/plugins) supplies
exactly that rubric, but its "block on any missed simplification" stance cannot fold verbatim
into an autonomous, convergence-seeking loop: the 0-Blocker merge bar must stay reachable.

## Success criteria (measurable)

- The review subagent applies a documented code-quality rubric on **code-touching** PRs and
  tags each structural finding `[regression]` or `[simplification]`.
- `[regression]` findings (file crossing 1k lines *in this diff*; new spaghetti branch in an
  unrelated flow; feature logic leaked into a shared path) **gate the merge bar as Blockers**.
- `[simplification]` findings follow the backoff schedule: **Blocker at age 0 (pass first seen),
  Important at age 1–2, follow-up issue at any terminal (cap, merge-ready, or age ≥ 3)**.
- Every outstanding `[simplification]` is **captured as a GitHub issue on every terminal exit
  path** — no silent drops.
- A clean PR (no `[regression]`; simplifications demoted) still **converges to 0 hard Blockers
  within `max_iterations`**.
- Plan/doc-only PRs are **unchanged** (rubric is code-PR-conditional).

## Scope

**In:**
- New `reference/code-quality-rubric.md` (lifted + adapted from thermo-nuclear; Cursor MIT attribution).
- Wiring into `PROMPT.md`: review brief, parse split, backoff lifecycle, terminal issue-filing; one new state field `deferred_simplifications`.
- Updates to `reference/classify-blockers.md` and `reference/review-format.md`.
- Attribution, version bump (1.0.1 → 1.1.0), README + marketplace description.

**Out (explicitly):**
- Applying the code rubric to plan/doc-only PRs (rubric stays code-conditional).
- The broader `thermos` system (correctness/security skill, orchestrator, subagents).
- Flag-configurable backoff schedule (v1 hardcodes 1-Blocker / 2-Important / issue).
- A standalone harsh-audit skill (separately offered; not this bundle).

## Constraints

- Markdown/prompt-only skill — **no automated test gate**; verification is structural + a
  lifecycle trace (the PR-template Verification section is the gate).
- **Reuse existing machinery** — Step 6 overlap (recurrence), Step 7.5 issue-filing, Step 2
  terminal — to minimise new state and risk.
- Cursor MIT license: attribution preserved.
- Backward-compatible: doc/plan-only PRs behave exactly as today.

## Plan (phased)

- **Phase 1 — rubric + wiring** (Tasks 1–4): the rubric file, brief/parse wiring, backoff
  lifecycle, classifier handling.
- **Phase 2 — release** (Task 5): attribution, version bump, README/marketplace.

## Open questions

- **Bundle location** — placed in-repo at `docs/plans/` to match the repo's two existing plan
  bundles; the workspace `_specs/lab-claude-plugins/` cutover convention is the alternative.
  Flagged for the owner; trivially relocatable.
- **1k-line threshold override** — v1 uses a fixed heuristic documented in the rubric; a
  per-repo override is deferred unless it proves noisy.
- **Backoff configurability** — v1 hardcodes the schedule; a `--simplification-backoff` flag is
  a candidate follow-up if the fixed schedule chafes.
