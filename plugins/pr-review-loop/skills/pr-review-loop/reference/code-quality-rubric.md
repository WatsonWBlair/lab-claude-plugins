<!--
  Adapted from Cursor's "thermo-nuclear-code-quality-review" skill.
  Source: github.com/cursor/plugins (cursor-team-kit / thermos), MIT licensed, © 2026 Cursor.
  Lifted and re-shaped for pr-review-loop's convergence-seeking loop: the original's
  "block on any missed simplification" stance is replaced by the two-tier tag + backoff
  schedule below so the 0-Blocker merge bar stays reachable. See ../../../../../docs/plans/
  2026-06-30-pr-review-quality-rubric/log.md for the design rationale.
-->

# Code-quality rubric — what rises to a structural finding

This file is the **substantive code-quality contract** the per-cycle review subagent applies
on **code-touching PRs only**. It tells the reviewer what counts as a structural problem and how
to tag it so the loop can route it. Structural findings populate the **existing** Blockers /
Important / Suggestions sections of `review-format.md` — this rubric adds no new section; it adds a
**tag** the reviewer prepends to each structural finding.

## Diff-scoping (read first)

**Only findings introduced by *this PR* are in scope.** A reviewer tags a structural finding only
when *this diff* creates it, crosses the threshold, or moves code into the offending shape.
Pre-existing smells the PR merely sits next to are **out of scope** — do not tag them; mention them,
if at all, as an untagged Suggestion. The test for every tag below is: *did this PR introduce or
worsen it?* If the answer is "it was already like that," it is not a structural finding here.

## The two tags

Every structural finding carries exactly one tag as the **first token** of its finding text:

| Tag | Meaning | Routing |
|---|---|---|
| `[regression]` | A structural regression this PR introduces | **Hard Blocker** — gates the merge bar every cycle until fixed |
| `[simplification]` | A missed simplification / avoidable complexity this PR adds | **Backoff** — Blocker on first sighting, then decays (see Lifecycle below) |

Non-structural findings (correctness bugs, security, test gaps, doc rot) are **untagged** and flow
through the normal Blocker/Important/Suggestion bars unchanged. The rubric governs *structural
quality only*; it does not replace correctness review.

## `[regression]` — hard structural regressions

Tag a finding `[regression]` when *this PR* does any of the following. These are presumptive
Blockers: the loop will not let the PR meet its bar while one stands.

1. **File crosses 1000 lines in this diff.** A source file the PR pushes past **1000 lines** (or
   that the PR newly creates above it). The threshold is a heuristic for "this file now does too
   much" — the remedy is a split along a real seam, not a mechanical line-count trim. A file already
   over 1000 lines that the PR only edits in-place is *pre-existing* (out of scope) unless the PR
   makes it materially longer.
2. **New ad-hoc branch bolted into an unrelated flow.** A new conditional / special-case branch
   wedged into a control flow that does not own that concern — "spaghetti" coupling that routes one
   feature's logic through another's code path. The remedy is to handle the concern where it belongs,
   not to thread a flag through a foreign function.
3. **Feature logic leaked into a shared / canonical path.** Feature- or caller-specific logic
   pushed down into a shared helper, base class, or canonical code path that other callers traverse —
   so every other caller now pays for, or must reason about, one feature's special case. The remedy
   is to keep the special case at the feature boundary and leave the shared path general.

## `[simplification]` — missed simplifications (code-judo)

Tag a finding `[simplification]` when *this PR* adds avoidable structural complexity that a simpler
shape would remove. These are the "code-judo" smells — places where deleting or reframing is
stronger than adding. Each carries its preferred remedy:

- **Missed structural simplification** — the change adds machinery where reframing the problem
  removes the need for it. *Remedy: delete the layer, or reframe the state model so the case can't
  arise.*
- **Thin wrapper / identity abstraction** — a function, class, or indirection that forwards to one
  callee and earns nothing (no added invariant, no seam, no test surface). *Remedy: inline it; let
  callers reach the real thing.*
- **Cast / optionality churn** — a value made optional, nullable, or `any`-typed and then defended
  with casts and guards the PR also adds, when the type could have stayed precise at the source.
  *Remedy: tighten the type where the value originates; delete the downstream guards.*
- **Near-duplicate of a canonical helper** — new code that re-implements (slightly differently) a
  helper, validator, or pattern that already exists canonically in the repo. *Remedy: call the
  canonical helper; if it's almost-but-not-quite right, extend it once rather than forking it.*

Other defensible remedies the reviewer may name: extract a helper to collapse a repeated block,
flatten nested conditionals into early returns, replace a hand-rolled loop with the standard library
call. The throughline is **less code carrying the same behavior** — the reviewer states the simpler
shape concretely, not "this could be cleaner."

**Emit a `target:` key with every `[simplification]`.** So the loop can track the same simplification
across independent fresh passes, prefix each `[simplification]` finding — right after the tag — with
`(target: <file>::<anchor>)`, where the anchor is the named symbol or construct the smell concerns,
read from the code rather than your wording. Two fresh passes that word one smell differently must
still produce the same `target`. See `review-format.md` for the exact placement and the
no-single-symbol fallback. `[regression]` findings need no target.

## How the loop treats each tag (summary; full lifecycle in PROMPT.md Steps 5–6.5)

- `[regression]` → counted as a gating **Blocker** every cycle until resolved.
- `[simplification]` → **Blocker at age 0** (first cycle it's seen), **Important at age 1–2**, then
  **filed as a follow-up GitHub issue at any terminal exit or age ≥ 3**. The backoff keeps the
  0-Blocker bar reachable while still giving each missed simplification one cycle of real push; the
  issue-fallback guarantees nothing is silently dropped.

Classification of a tagged finding into mechanical (auto-fix) vs design-pin (interrupt) follows
`classify-blockers.md`.
