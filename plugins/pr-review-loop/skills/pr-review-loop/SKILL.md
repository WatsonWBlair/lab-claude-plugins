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

Configurable via `--bar` flag (v1 supports `0-blockers` only; stricter bars are deferred).

## Interrupt model

| Finding type | Loop behavior |
|---|---|
| Mechanical Blocker (commit-subject length, missing Files path, dead anchor, wording typo, count-of-N inconsistency) | Auto-fix via `Edit`. No interrupt. |
| Design-pin Blocker (option A vs B with non-trivial downstream implications) | Interrupt with `AskUserQuestion` carrying 2-3 defensible options + "(Recommended)" tag. |
| Mechanical Important (close-out path only) | Auto-fix via `Edit`. No interrupt. |
| Design-pin Important (close-out path only) | Interrupt with `AskUserQuestion` — must be resolved this pass. |
| Mechanical Suggestion (close-out path only — "easy") | Auto-fold via `Edit`. No interrupt. |
| Design-pin Suggestion (close-out path only — non-easy) | File as GitHub issue automatically. No interrupt. |
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

Declining consent skips only the PR comment (step 7.7); the Important + Suggestions work and issue filing still proceed because those are the substance of the close-out.

## See also

- [reference/classify-blockers.md](reference/classify-blockers.md) — mechanical vs design-pin decision tree
- [reference/review-format.md](reference/review-format.md) — the format the dispatched review subagent must follow
- [PROMPT.md](PROMPT.md) — the looped prompt the ralph framework feeds back each cycle
