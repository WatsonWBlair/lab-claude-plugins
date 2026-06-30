---
name: pr-review-loop
description: Use when driving a multi-pass PR review to a merge bar; when the user invokes /pr-review-loop; when a review pass returned critical findings that need fixing followed by another review; when iterative PR review-fix cycles need to run mostly hands-off.
---

# pr-review-loop

## Overview

A [ralph-loop](https://github.com/anthropics/claude-code)-powered cycle that drives a PR through alternating review and remediation passes until an outsider review returns 0 Blockers (the default merge bar). At that point the loop does NOT just exit — it runs a **close-out sub-flow** that resolves all Important findings, folds easy Suggestions, files GitHub issues for non-foldable items, re-reviews once for regression, and posts a single consolidated final PR comment.

> **Requires the `ralph-loop` plugin.** The loop's per-cycle re-feed is driven by ralph-loop's stop hook. It is declared as a dependency and installs automatically; if your Claude Code version predates plugin dependencies, install it manually first (`/plugin install ralph-loop@claude-plugins-official`).

## When to use

- A PR has had at least one review pass that returned findings, and the next pass is likely to surface new things post-remediation
- You want the review-remediate cycle to run mostly autonomously with interrupts only on design-pin findings (judgment calls)
- The PR has push access on the head branch (the loop commits remediation per cycle)

## When NOT to use

- Single-shot review wanted (use a one-shot review skill directly)
- PR not yet ready for review (draft scope still moving)
- No push access on head branch (fork-PRs and read-only checkouts)
- PR where every finding is likely a design pin — the loop becomes a Q&A wrapper, interactive review is faster

## The merge bar

Default is **0 Blockers** — a PR review with no critical items. Important and Suggestions are surfaced for human triage but do not block.

On code-touching PRs the gate counts **effective Blockers** = hard Blockers (`[regression]` findings + untagged Blockers) **plus** any age-0 `[simplification]` finding. A recurring simplification self-demotes out of the gate (see the code-quality rubric below), so the bar stays reachable while still giving each missed simplification one blocking cycle.

Configurable via `--bar` flag (v1 supports `0-blockers` only; stricter bars are deferred).

## Code-quality rubric (code-touching PRs)

Each review pass also applies a structural rubric (`reference/code-quality-rubric.md`, adapted from Cursor's MIT-licensed `thermo-nuclear-code-quality-review`). The subagent tags each structural finding `[regression]` or `[simplification]`; only findings this PR introduces are in scope. Doc/plan-only PRs are unchanged — the rubric is not referenced.

- **`[regression]`** (1000-line crossing in-diff, ad-hoc branch in an unrelated flow, feature logic leaked into a shared path) — a hard Blocker every cycle until fixed.
- **`[simplification]`** (code-judo smells: thin wrappers, cast/optionality churn, near-duplicate of a canonical helper) — backs off: **Blocker at age 0**, **Important at age 1–2**, **follow-up issue at age ≥ 3 or any terminal**. Every outstanding simplification is discharged on **every** terminal exit (merge-ready, max-iterations, stuck-abort, and the error-aborts) — filed as an issue with consent, or listed for manual filing if consent is declined; never silently dropped. Each `[simplification]` carries a `(target: file::symbol)` key derived from the code, so the loop re-matches the same finding across fresh re-worded passes.

## Interrupt model

| Finding type | Loop behavior |
|---|---|
| Mechanical Blocker (commit-subject length, missing Files path, dead anchor, wording typo, count-of-N inconsistency) | Auto-fix via `Edit`. No interrupt. |
| Design-pin Blocker (option A vs B with non-trivial downstream implications) | Interrupt with `AskUserQuestion` carrying 2-3 defensible options + "(Recommended)" tag. |
| `[regression]` structural finding (code PRs) | Hard Blocker — gates every cycle; classified mechanical/design-pin like any Blocker. |
| `[simplification]` at age 0 (first sighting, code PRs) | Blocker — auto-fix if a trivial extraction, else **one** design-pin interrupt, then deferred (never re-interviewed). |
| `[simplification]` at age 1-2 (recurred) | Important — does not gate; ages in the ledger, surfaced in the summary. |
| `[simplification]` at age ≥3 or any terminal | Filed as a GitHub follow-up issue (`P2-backlog`), consent-gated. No interrupt. |
| Mechanical Important (close-out path only) | Auto-fix via `Edit`. No interrupt. |
| Design-pin Important (close-out path only) | Interrupt with `AskUserQuestion` — must be resolved this pass. |
| Mechanical Suggestion (close-out path only — "easy") | Auto-fold via `Edit`. No interrupt. |
| Design-pin Suggestion (close-out path only — non-easy) | File as GitHub issue (consent-gated). No interrupt. |
| Stuck loop (this pass's Blocker text overlaps prior pass's by >50% of lines) | Interrupt with `AskUserQuestion`: abort / continue / show-diff. |
| Verification re-review regression (close-out fixes triggered new Blockers) | Interrupt with `AskUserQuestion`: stop-as-stuck (default) / continue-as-fresh-cycle / force-exit-as-merge-ready. |
| `pass > max_iterations` | Stop. Print summary. State file persists for inspection. |

Classification heuristics: [reference/classify-blockers.md](reference/classify-blockers.md). Review format the dispatched subagent must follow: [reference/review-format.md](reference/review-format.md).

## Usage

```
/pr-review-loop <PR#> [--max-iterations 5] [--bar 0-blockers] [--restart]
```

Slash command initializes state at `<active-repo>/.claude/.pr-review-loop.state.json`, extends `.gitignore` (idempotent), and hands off to the ralph-loop framework. Each cycle's review file lives at `%TEMP%/pr<N>_review_pass<K>.md` (Windows) or `${TMPDIR:-/tmp}/...` (POSIX). State file persists across cycles; manual cleanup is `rm .claude/.pr-review-loop.state.json` when the audit trail is no longer needed.

`/cancel-ralph` aborts the loop mid-cycle (removes ralph framework state; this skill's state persists for inspection).

## First-cycle consent

The loop's terminal `merge_ready` path runs a close-out sub-flow that (a) commits + pushes additional fixes for Important + easy Suggestions, (b) files GitHub issues for non-foldable items under the active `gh` user identity, and (c) posts a consolidated final PR comment under that same identity. On the first cycle where merge_ready is reachable, the loop fires an `AskUserQuestion` requesting consent for the entire close-out scope (not just the comment). The answer persists in `state.consent_to_post_pr_comments` for the remainder of this loop only; a new `/pr-review-loop` invocation on a different PR re-asks.

Declining consent withholds **all** `gh`-identity posts — no PR comment **and** no issue filing. The Important + easy-Suggestion fixes still apply (those are branch commits, already authorized by running the loop); the items that would have been filed (design-pin Suggestions + any deferred simplifications) are listed in the terminal summary for you to file manually, so nothing is silently dropped. The same consent governs the filing routine at the non-merge-ready terminals (max-iterations, stuck-abort), which asks its own context-accurate question there rather than reusing this close-out prompt.

## See also

- [reference/classify-blockers.md](reference/classify-blockers.md) — mechanical vs design-pin decision tree (incl. structural-tag handling)
- [reference/code-quality-rubric.md](reference/code-quality-rubric.md) — the `[regression]` / `[simplification]` rubric the subagent applies on code PRs
- [reference/review-format.md](reference/review-format.md) — the format the dispatched review subagent must follow
- [PROMPT.md](PROMPT.md) — the looped prompt the ralph framework feeds back each cycle
