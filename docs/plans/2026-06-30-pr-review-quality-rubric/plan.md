# Plan — pr-review-loop code-quality rubric (thermo-nuclear lift)

Date: 2026-06-30 · Source of truth for decisions/alternatives: [log.md](./log.md) · PRD: [prd.md](./prd.md)

All paths relative to `plugins/pr-review-loop/skills/pr-review-loop/` unless noted.

---

## Task 1 — Author the code-quality rubric reference

**Files:** Create `reference/code-quality-rubric.md`
**Depends on:** —
**Spec:** [prd.md](./prd.md) §Success criteria, §Scope
**Acceptance:**
- Defines two tiers and the tag the review subagent must emit per structural finding:
  `[regression]` (hard Blocker) and `[simplification]` (backoff).
- `[regression]` enumerates: file crossing 1000 lines *in this diff*; new ad-hoc branch bolted
  into an unrelated flow; feature logic leaked into a shared/canonical path.
- `[simplification]` enumerates the "code-judo" smells (missed structural simplification, thin
  wrapper / identity abstraction, cast/optionality churn, near-duplicate of a canonical helper)
  and the preferred remedies (delete a layer, reframe the state model, extract a helper, …).
- States **diff-scoping**: only findings introduced by *this PR*; pre-existing issues are out of scope.
- Carries a Cursor MIT attribution header (source: `cursor/plugins` thermos, MIT, © 2026 Cursor).
**Verification:** `grep -nE "\[regression\]|\[simplification\]|1000|Cursor|MIT" reference/code-quality-rubric.md` returns matches in all five categories; manual read confirms both tier definitions and diff-scoping.
**Agent-suitable:** yes
**Commit:** `feat(pr-review-loop): add code-quality rubric reference (thermo-nuclear lift)`

---

## Task 2 — Wire the rubric into the review brief + parse

**Files:** Modify `PROMPT.md` (Step 4 brief, Step 5 parse), `reference/review-format.md`
**Depends on:** 1
**Spec:** [prd.md](./prd.md) §Success criteria
**Context:** the rubric only bites if the subagent is told to apply it and the loop parses the tags.
**Acceptance:**
- Step 4 brief instructs the subagent, **on code-touching PRs only**, to read
  `code-quality-rubric.md` and tag each structural finding `[regression]` / `[simplification]`.
- `review-format.md` documents the two tags and that structural findings populate the **existing**
  Blockers / Important / Suggestions sections (no new section, no parser change to heading levels).
- Step 5 parse separates `[simplification]`-tagged findings into a working list **distinct from
  the hard Blocker count** that gates the bar.
- Doc/plan-only PRs: rubric not referenced; behaviour identical to today.
**Verification:** trace a sample code review file through Steps 4–5 and confirm a `[simplification]`
Blocker does not inflate the gating Blocker count; `grep -n code-quality-rubric PROMPT.md` present.
**Agent-suitable:** yes
**Commit:** `feat(pr-review-loop): apply code-quality rubric in the review brief`

---

## Task 3 — Backoff lifecycle + state ledger

**Files:** Modify `PROMPT.md` (Step 1 state shape, severity-by-age logic, Step 2 + Step 7 terminal issue-filing, Step 6 interplay); `commands/pr-review-loop.md` (state seed, if it initialises the schema)
**Depends on:** 2
**Spec:** [prd.md](./prd.md) §Success criteria (backoff schedule)
**Context:** this is the load-bearing behaviour change; it must reuse existing machinery, not add a parallel loop.
**Acceptance:**
- State gains `deferred_simplifications`: a list of `{fingerprint, first_seen_pass, age}`.
- A `[simplification]` is a **Blocker at age 0**, **Important at age 1–2**, and **filed as a
  follow-up issue at age ≥ 3 or any terminal**.
- Recurrence/age uses the **Step 6 overlap mechanism**; a recurring simplification increments age,
  self-demotes, and does **not** trip a false stuck-interrupt.
- **Both** terminal paths — Step 2 (max_iter) and Step 7 (merge-ready close-out) — file every
  outstanding `deferred_simplifications` entry as an issue via the **Step 7.5** machinery before exit.
- A clean PR (no `[regression]`, simplifications demoted) converges to 0 hard Blockers within `max_iterations`.
**Verification:** lifecycle trace — a recurring `[simplification]` reads Blocker@pass1, Important@pass2–3,
issue@terminal; a sample state JSON carrying `deferred_simplifications` validates; confirm both Step 2 and
Step 7 invoke issue-filing for outstanding entries.
**Agent-suitable:** partial (reasoning-heavy prompt logic; needs a careful hand-trace)
**Commit:** `feat(pr-review-loop): backoff lifecycle for simplification findings`

---

## Task 4 — Classifier handling for simplification vs regression

**Files:** Modify `reference/classify-blockers.md`
**Depends on:** 1
**Spec:** [prd.md](./prd.md) §Success criteria
**Acceptance:**
- `[simplification]` at age 0: an **obvious extraction** (helper / module split) is *mechanical*
  (auto-fix); a **real restructure** is *design-pin* → one interrupt (pin b), no further.
- `[simplification]` at age ≥ 1: **never** interviewed or auto-refactored in close-out → routed
  to issue filing.
- `[regression]` findings classify through the existing mechanical/design-pin tree unchanged.
- A worked example is added for each branch.
**Verification:** read `classify-blockers.md`; confirm worked examples for `[simplification]`-trivial→mechanical,
`[simplification]`-restructure→design-pin-then-defer, and `[regression]`→existing tree.
**Agent-suitable:** yes
**Commit:** `docs(pr-review-loop): classify simplification vs regression findings`

---

## Task 5 — Attribution, version bump, README

**Files:** Modify `../../.claude-plugin/plugin.json` (version), `../../../../README.md` (lab-claude-plugins README), `../../../../.claude-plugin/marketplace.json` (pr-review-loop version + description); attribution lives in the rubric header (Task 1)
**Depends on:** 1, 2, 3, 4
**Spec:** [prd.md](./prd.md) §Constraints (license)
**Acceptance:**
- `pr-review-loop` version bumped `1.0.1` → `1.1.0` in `plugin.json` and `marketplace.json`.
- Cursor MIT attribution present and correct (rubric header names `cursor/plugins` thermos, MIT, © 2026 Cursor).
- README documents the code-quality rubric, the `[regression]`/`[simplification]` tiers, and the backoff behaviour.
**Verification:** `grep -ni "cursor\|MIT" reference/code-quality-rubric.md` matches; `grep -n '"version": "1.1.0"' ../../.claude-plugin/plugin.json` matches; README section renders.
**Agent-suitable:** yes
**Commit:** `chore(pr-review-loop): attribution + v1.1.0 for the quality rubric`
