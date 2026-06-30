# Review format — what the dispatched subagent must produce

This file is the contract the per-cycle review subagent receives in its brief. The loop's parser depends on the structure documented here; deviations break the parse and trip the error-path `AskUserQuestion`.

The format codifies an **outsider-reader** posture: review what is actually there, not what was meant, and do not anchor on prior review passes.

## Required structure

The review file is a single markdown document with these sections in this order:

```markdown
# PR #<N> — Pass-<K> outsider review

**PR:** <PR title>
**Head commit:** <sha7>
**Branch:** <branch>
**Reviewer mode:** outsider, no anchoring on prior reviews (pass <K-1> not read).

## Methodology

<paragraph documenting what the reviewer read, what they verified, what they spot-checked>

## Recommendation

**`merge-as-is`** | **`address-then-merge`** | **`revise-and-re-review`** — <one-line rationale>

### Blockers

<numbered list; one paragraph per Blocker. Each paragraph names the offending location (file + heading or line), states the rule violated or the conflict, and proposes the fix or surfaces the choice>

### Important

<same shape; findings that should fix before merge but don't block>

### Suggestions

<same shape; quality-of-life improvements>

### Load-bearing strengths (don't lose in revision)

<bulleted list of what's working well — the outsider reader's "don't break this on the next revision" notes>

### Cross-cutting Q&A

<questions an implementing agent might ask + whether the plans/spec answer them>
```

**Heading levels are load-bearing.** The findings sections (`### Blockers`, `### Important`, `### Suggestions`, `### Load-bearing strengths`, `### Cross-cutting Q&A`) MUST use `### ` (three hashes). The loop's parser keys off heading level to delimit sections. `## ` works for the top-level `Methodology` / `Recommendation` headings but NOT for findings. Subagents that emit `## Blockers` instead of `### Blockers` will fail the parse and trip the error-path interrupt.

## Structural-finding tags (code-quality rubric)

On **code-touching PRs**, the brief also points the reviewer at `code-quality-rubric.md`. Every **structural** finding that rubric defines — a structural regression or a missed simplification — carries a tag as the **first token** of its finding text:

- `[regression]` — a structural regression this PR introduces (hard Blocker).
- `[simplification]` — a missed simplification this PR adds (the loop applies a backoff schedule).

Tagged findings populate the **existing** `### Blockers` / `### Important` / `### Suggestions` sections — there is **no new section** and **no change to heading levels**. The tag is metadata the loop reads to route the finding; the section the reviewer places it in still signals severity. Per the rubric, a first-sighting `[simplification]` belongs in `### Blockers`. Non-structural findings (correctness, security, tests, docs) stay **untagged** and unchanged.

**`[simplification]` findings must also carry a `target:` key.** Immediately after the tag, emit `(target: <file path>::<anchor>)`, where the anchor is the named symbol or construct the smell concerns (a function / class / method / type name), read from the **code** — not a restatement of your prose. The loop fingerprints on this key (not your wording) to recognise the same simplification across independent fresh passes, so two reviewers who describe one smell in different words must still land on the same `target`. Example: `1.` ``[simplification] (target: `src/api/user.ts::getUser`) getUser forwards to api.fetch and earns nothing — inline it.`` When no single symbol fits (e.g. a duplicated block), use `<file>::<canonical-thing-duplicated>` or `<file>::<smell>@<nearest-enclosing-symbol>`. `[regression]` findings need **no** `target:` — they gate every cycle until fixed, so they need no cross-pass identity.

On **doc/plan-only PRs** the rubric is not referenced and no tags appear — the format is exactly as described above, without the tag token.

## Prose tone

- **Outsider reader's eye.** Read what's there, not what's meant. If the doc relies on context only insiders have, that's a finding. If code reads ambiguously, flag it even if the reviewer can guess the intent.
- **Technical reasoning for every finding.** Not "this seems off" — name the rule violated, the conflict surfaced, or the question the doc fails to answer.
- **No performative agreement.** No "great", "nice", "wonderful". State the finding or state the strength; don't compliment.
- **Mode switch is explicit.** This is review mode. The reviewer is NOT helping author the work — they are surfacing what an outsider catches.

## Empty sections

If a section has no findings, write `None.` under the heading. Do not omit the heading; the parser uses heading presence as a structural signal.

Example:
```markdown
### Blockers

None. The three plans satisfy the merge gate.
```

## Worked example (abbreviated)

A `merge-as-is` review with an empty Blockers section and populated Important + Suggestions:

```markdown
# PR #42 — Pass-3 outsider review

**PR:** Add retry policy to the ingest client
**Head commit:** a1b2c3d
**Branch:** feat/ingest-retry
**Reviewer mode:** outsider, no anchoring on prior reviews (pass 2 not read).

## Methodology

Read the four changed files end-to-end; cross-checked the retry config against
the documented defaults; spot-checked the new test for the backoff-cap edge.

## Recommendation

**`merge-as-is`** — no Blockers; two Important items are post-merge-safe.

### Blockers

None. The retry policy is correctly bounded and tested.

### Important

1. `client.py` — the backoff cap is read from config but never validated; a
   negative value would loop immediately. Add a `>= 0` guard at load time.

### Suggestions

1. `test_retry.py` — the jitter test asserts a range but not determinism under a
   fixed seed; seeding would make the assertion exact.

### Load-bearing strengths (don't lose in revision)

- The retry/backoff separation keeps the transport layer free of policy.

### Cross-cutting Q&A

- Q: does the cap interact with the global request timeout? A: yes — documented
  in the docstring; no change needed.
```

## Common deviations to avoid

| Deviation | Effect | Fix |
|---|---|---|
| `## Blockers` instead of `### Blockers` | Parser fails to find Blockers section | Use `### ` |
| Omitting the `### Blockers` heading when count is zero | Parser flags missing section as anomaly | Write `### Blockers\n\nNone.` |
| Bulleted list inside Blockers section instead of numbered | Parser undercounts Blockers | Use `1.`, `2.`, `3.` |
| Mixing review and remediation in one document | Confuses reviewer and parser | Review pass is read-only; remediation is the loop's job |
| Including the prior pass's findings as context | Context pollution | Subagent is dispatched without prior-pass files in its brief |
