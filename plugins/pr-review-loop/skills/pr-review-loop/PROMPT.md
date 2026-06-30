# pr-review-loop — iteration prompt

> **For the looping Claude instance:** This prompt is fed to you each iteration by the ralph-loop framework. Read state, do the cycle's work, persist state, attempt exit. The framework re-feeds this prompt until you emit `<promise>LOOP_DONE</promise>`. Steps 1-11 below are the full per-cycle workflow.

> **Terminal cleanup routine:** every terminal exit path (max_iter, stuck-abort, merge_ready, and the user_abort / error-abort branches in Steps 4.4 / 5.3 / 9.8) must, in this order: (1) **run the ledger-discharge step** (below), then (2) delete `.claude/.pr-review-loop.state.json` via `Bash rm`, then (3) emit `<promise>LOOP_DONE</promise>`.
>
> **Ledger-discharge step (single definition — every terminal invokes it, none re-implements it):** if `state.deferred_simplifications` is non-empty, run the deferred-simplification filing routine (Step 6.5) over every remaining entry so each becomes a follow-up issue (its consent guard asks once). This is the single guarantee behind the PRD's "no simplification dropped on any terminal exit path". A terminal that already discharged + cleared the ledger as part of its own logic — the merge-ready close-out folds the ledger into `issues_to_file` in Step 7.5 and clears it — finds the ledger empty here, so the step is a safe no-op, never a double-file. Adding a new terminal? Invoke this step before the `rm`.
>
> The audit trail lives in three durable places that don't depend on the state file: (a) per-cycle commits in `git log` (subjects + bodies enumerate fixes), (b) per-cycle review files in `%TEMP%` (OS-managed), (c) the final consolidated PR comment on GitHub. Crashed loops (process death mid-cycle) leave the state file in place — this is intentional, the file's presence tells the next `/pr-review-loop` invocation that a loop was in flight and prompts `--restart` or `/cancel-ralph`.

## Step 1: Read state and surface status banner

1. Use the `Read` tool to read `.claude/.pr-review-loop.state.json` (relative to the active repo's working directory).
2. Parse the JSON into a working object you'll mutate over the cycle.
3. Run `git rev-parse --short HEAD` via `Bash` to get a short sha for the banner.
4. Emit ONE line at the top of your output:
   `[pr-review-loop pass <K> of <max_iterations>] PR #<pr_number> on <repo> @ <branch> | HEAD <sha7>`
   Substitute the state file's fields. This banner is the human's progress signal — keep it tight.

## Step 2: Safety bound check (max_iterations)

1. If `state.pass > state.max_iterations`:
   a. Compose a terminal summary block naming: the path to the latest review file (`%TEMP%/pr<pr_number>_review_pass<state.pass - 1>.md` on Windows; `${TMPDIR:-/tmp}/pr<pr_number>_review_pass<state.pass - 1>.md` on POSIX), the final **effective** Blocker count from `state.blocker_history[-1].count` (hard Blockers + age-0 simplifications; or 0 if the array is empty), the count of simplifications about to be filed (`len(state.deferred_simplifications)`), the state file path, and a one-line reason ("safety bound reached after N cycles without meeting the 0-Blocker bar").
   b. Update the state object: `state.status = "complete"`, `state.completion_reason = "max_iter"` (in-memory only — the file is about to be deleted).
   c. **Run the ledger-discharge step** (terminal-cleanup routine, top of file): if `state.deferred_simplifications` is non-empty, the deferred-simplification filing routine (Step 6.5) files each remaining entry as a follow-up issue — no simplification is dropped at the safety bound; its consent guard asks once if consent was never captured. Capture any filed-issue numbers for step d's summary.
   d. Emit the summary block visibly (including any filed-issue numbers).
   e. Perform terminal cleanup: `rm .claude/.pr-review-loop.state.json` via `Bash`.
   f. Emit `<promise>LOOP_DONE</promise>` as a standalone line.
   g. Stop. Do not execute further steps.
2. Otherwise: continue to Step 3.

## Step 3: Capture current HEAD sha

1. Run `git rev-parse HEAD` via `Bash`.
2. Store the full sha in a working variable `sha_before` for this cycle. You'll use it in Step 10 when appending to `state.blocker_history`.

## Step 4: Dispatch review subagent

1. Compute the cycle's review file path:
   - Windows Git Bash: `${TEMP}/pr<pr_number>_review_pass<state.pass>.md` (typically `/c/Users/<user>/AppData/Local/Temp/...`)
   - POSIX: `${TMPDIR:-/tmp}/pr<pr_number>_review_pass<state.pass>.md`
   - If `${TEMP}` is unset, fall back to `$HOME/AppData/Local/Temp/pr<#>_review_pass<K>.md` on Windows or `/tmp/pr<#>_review_pass<K>.md` elsewhere.
2. Dispatch a subagent via the `Agent` tool:
   - `subagent_type`: `general-purpose`
   - `model`: `opus`
   - `description`: e.g. `Pass-<K> review of PR #<pr_number>`
   - `prompt`: a brief encoding ALL of the following:
     - PR number, repo (`state.repo`), branch (`state.branch`), `sha_before` from Step 3, pass number (`state.pass`)
     - "This is an outsider review. Do NOT read any prior review file. Do NOT anchor on prior decisions. Read the PR's files fresh."
     - Path to the review-format reference: `@@PLUGIN_ROOT@@/skills/pr-review-loop/reference/review-format.md` — instruct the subagent to read it first and follow it exactly, especially `### ` heading levels on findings sections.
     - **Code-quality rubric (code-touching PRs only):** if this PR changes code — i.e. the diff is **not** exclusively documentation/plan/text (`.md`, docs, plan bundles) — also point the subagent at `@@PLUGIN_ROOT@@/skills/pr-review-loop/reference/code-quality-rubric.md` and instruct it to apply that rubric: tag every **structural** finding it raises with `[regression]` or `[simplification]` as the **first token** of the finding text, placing it in the Blockers/Important/Suggestions section the rubric prescribes (first-sighting simplifications go in Blockers). On a **doc/plan-only PR**, do NOT reference the rubric — the brief is identical to today and the subagent emits no tags.
     - Output review file path (computed above).
     - "Return ONLY: recommendation line, Blocker count, Important count, Suggestion count, output file path. The full review body goes in the file, not the reply."
3. Wait for the subagent to complete. Do NOT `run_in_background`; this cycle blocks on the result.
4. On subagent error or empty / missing output file: fire an `AskUserQuestion` with options:
   - Retry (re-dispatch with the same brief)
   - Change model (re-dispatch with `model: sonnet`)
   - Abort (set `state.completion_reason = "user_abort"`, perform terminal cleanup — run the ledger-discharge step, then `Bash rm .claude/.pr-review-loop.state.json` — emit `<promise>LOOP_DONE</promise>`, exit)
5. Emit a one-line summary: `[step 4] review dispatched → <output file path>; <N> blockers / <M> important / <S> suggestions`.

## Step 5: Parse review file

1. Use the `Read` tool to read the review file written in Step 4.
2. Extract:
   - **Recommendation line:** the line starting with `**`` `merge-as-is`` `**` or similar; record verbatim.
   - **`### Blockers` section:** everything from the line matching `^### Blockers\b` up to (but not including) the next `^### ` line. If the section body is exactly `None.` or `None` or empty, the Blocker count is 0.
   - **Blocker count:** number of numbered list items in the Blockers section (lines matching `^\d+\.\s`). If the body is `None.`, count is 0.
   - **`### Important` section** and **`### Suggestions` section:** same extraction pattern. Carry the raw text forward — you'll need it at the merge-ready terminal path (Step 7) for the final PR comment.
3. Parse failure paths:
   - **No `### Blockers` heading found:** the subagent emitted a wrong format. Fire an `AskUserQuestion`:
     - Retry (re-dispatch the subagent with extra emphasis on heading levels — same as Step 4's retry but adds "MUST use `### ` for Blockers/Important/Suggestions" to the brief)
     - Treat-as-0-Blockers (record the parse anomaly in your output, set Blocker count to 0, proceed to Step 6)
     - Abort (set `state.completion_reason = "user_abort"`, perform terminal cleanup, emit promise, exit)
   - **Blockers section body present but Blocker count parses as ambiguous** (e.g. mixed bullets and numbered items): fire same `AskUserQuestion`, recommending Retry.
4. **Tag scan (code-quality rubric).** On code-touching PRs the subagent tags structural findings (Step 4). Scan every numbered item in the Blockers / Important / Suggestions sections for a leading `[regression]` or `[simplification]` token:
   - `hard_blocker_count` / `hard_blocker_text` ← the Blocker-section items that are **not** `[simplification]`-tagged: i.e. `[regression]`-tagged items plus untagged Blockers. This is the parse-time gating Blocker count; `[simplification]` items are held out of it.
   - `regressions_this_pass` ← the `[regression]`-tagged Blocker items (a subset of the hard Blockers, tracked separately only so the summary can report them).
   - `simplifications_this_pass` ← an ordered list of `{finding_text, fingerprint}` for every `[simplification]`-tagged item, wherever it appears (the rubric places first-sighting simplifications in Blockers). `fingerprint` = the finding's **`target:` key** — the `(target: <file>::<anchor>)` token the rubric (`review-format.md`) requires on every `[simplification]` — normalized (lowercased, whitespace-collapsed). The target is a structural anchor read from the **code** (a symbol/construct), **not** the finding's prose, so independent fresh passes that re-word the same simplification still produce the **same** fingerprint — this is what lets the age ledger (Step 6.5) track one finding across passes. Fallback: if a `[simplification]` carries no parseable `(target: …)`, derive `fingerprint` from `<file path>::<first-sentence-slug>` and append `(degraded fingerprint — reviewer omitted target)` to the Step 6.5 summary so the weaker match is visible; the parse never fails on a missing target.
   - The simplification list is **distinct from `hard_blocker_count`**: a `[simplification]` never inflates the parsed hard-Blocker count. Its effect on the *effective* gate is decided by the backoff lifecycle (Step 6.5), which re-admits a first-sighting (age-0) simplification to the gate, demotes a recurring one to Important, or files it as an issue.
   - Doc/plan-only PRs carry no tags; all three derived values fall back to the raw Blocker parse and behaviour is identical to today.
5. The stuck-detector (Step 6) and state update (Step 10) operate on `hard_blocker_text` (the hard Blockers from step 4 — regressions + untagged, **excluding** `[simplification]` findings). Recurring simplifications are deliberately kept out of the stuck input so they age out via Step 6.5 without tripping a false stuck-interrupt. `simplifications_this_pass` carries forward to Step 6.5.
6. Emit summary: `[step 5] parsed: recommendation=<verbatim>; blockers=<N> (regressions=<R>, simplifications=<Sx>); important=<M>; suggestions=<S>`.

## Step 6: Stuck-detector

The stuck-detector runs on **hard Blockers only** (`hard_blocker_text` from Step 5). Recurring `[simplification]` findings are excluded — they self-demote in Step 6.5 and must not register as "stuck". Skip the stuck check on the first pass (when `state.last_blocker_text == ""`) and proceed directly to Step 6.5. On subsequent passes:

1. **Compute line-level overlap** between `hard_blocker_text` (Step 5 result) and `state.last_blocker_text`:
   - Split each by newline, strip whitespace, drop empty lines.
   - Convert each to a set of unique lines.
   - `overlap = len(current ∩ prior) / max(len(current), len(prior))`
   - If `len(current) == 0` and `len(prior) == 0`: skip the detector (defensive — with no hard Blockers on either side, Step 6.5 owns the routing decision this pass).

2. **If `overlap > 0.5`:** the loop is likely stuck (same Blockers recurring). Fire `AskUserQuestion`:
   - `question`: `Loop may be stuck — pass <K>'s Blockers overlap pass <K-1>'s by <round(overlap*100)>%. Abort?`
   - `header`: `Stuck loop`
   - `options`:
     - `Continue anyway` — proceed to Step 6.5 (then Step 7 / Step 8); the next pass will re-test.
     - `Show diff` — print `hard_blocker_text` and `state.last_blocker_text` side-by-side (or just sequentially with headers), then re-ask this question.
     - `Abort (Recommended)` — set `state.status = "complete"`, `state.completion_reason = "stuck"` (in-memory only). Print a summary block naming the recurring Blockers. Then **perform terminal cleanup** (top-of-file routine): run the ledger-discharge step (the stuck terminal files any outstanding simplifications, dropping none), `rm .claude/.pr-review-loop.state.json`, and emit `<promise>LOOP_DONE</promise>`. Exit.

3. **If `overlap ≤ 0.5`:** continue to Step 6.5 (which computes the effective Blocker count and routes to Step 7 or Step 8).

4. Emit summary: `[step 6] stuck-detector: overlap=<round(overlap*100)>%, threshold=50%, <decision>`.

## Step 6.5: Backoff lifecycle for simplification findings

Turns `simplifications_this_pass` (Step 5) into severities via an age ledger, then computes the **effective Blocker count** that the Step 7 / Step 8 branch keys on. It reuses the recurrence principle of Step 6's overlap detector, applied **per-finding** via each finding's `fingerprint` (Step 5). The ledger is `state.deferred_simplifications`: a list of `{fingerprint, first_seen_pass, age, finding_text}` (`finding_text` is retained so a terminal with no live review file can still build the issue body).

Skip the whole step on doc/plan-only PRs (no tags ⇒ `simplifications_this_pass` empty and the ledger stays empty): set `effective_blocker_count = hard_blocker_count` and route exactly as before.

1. **Reconcile the ledger against this pass.** For each entry `e` in `simplifications_this_pass`:
   - If `e.fingerprint` matches an existing ledger entry `L`: it **recurred** — set `L.age = L.age + 1` and refresh `L.finding_text = e.finding_text`.
   - Else: it is **first seen** — append `{fingerprint: e.fingerprint, first_seen_pass: state.pass, age: 0, finding_text: e.finding_text}`.
   Then **drop resolved entries:** any ledger entry whose fingerprint is NOT in `simplifications_this_pass` was fixed (the fresh outsider review no longer raises it) — remove it, and do NOT file an issue for it.

2. **Assign severity by age** (after reconciliation):
   - `age == 0` → **Blocker** (re-admitted to the gate this pass; Step 8 processes it).
   - `age == 1` or `age == 2` → **Important** (does NOT gate; stays in the ledger, surfaced in the summary, filed at a terminal).
   - `age >= 3` → **file now**: run the **deferred-simplification filing routine** (below) for this entry, then remove it from the ledger.

3. **Compute the effective gate:**
   - `age0_simplifications` ← ledger entries with `age == 0` (their `finding_text`).
   - `effective_blocker_count = hard_blocker_count + len(age0_simplifications)`.
   - `gate_blocker_text` ← `hard_blocker_text` followed by the `age0_simplifications` findings, renumbered as one list. Step 8 iterates this; each age-0 simplification classifies via `classify-blockers.md` (obvious extraction → mechanical; real restructure → one design-pin interrupt, no further).

4. **Route:**
   - `effective_blocker_count == 0` → continue to **Step 7** (merge-ready close-out). Any ledger entries still present (age 1–2) are filed there via Step 7.5.
   - `effective_blocker_count > 0` → continue to **Step 8** (fix loop) using `gate_blocker_text`.

5. Emit summary: `[step 6.5] simplifications: <new> new (age0→Blocker), <aging> aging (age1-2→Important), <filed> filed (age>=3); effective blockers=<effective_blocker_count> (hard=<hard_blocker_count> + age0=<len(age0_simplifications)>)`.

### Deferred-simplification filing routine

Files one or more ledger entries as GitHub follow-up issues using the **Step 7.5 machinery** (label discovery + `gh issue create`), so the close-out and the terminal paths share one mechanism. **Consent guard:** issue creation acts under the operator's `gh` identity. Before the FIRST issue is filed in this loop, ensure consent is captured. If `state.consent_to_post_pr_comments` is `null`, fire **this routine's own context-accurate question** (NOT Step 7.1's merge-ready wording — that claims "hit 0 Blockers" and "post the final PR comment", both false at the max_iter / stuck / age-≥3 terminals where this routine actually fires):
- `question`: `Filing <N> outstanding code simplification(s) as follow-up GitHub issues under your gh identity (loop exiting via <state.completion_reason, or "deferral" mid-cycle>). Approve?`
- `header`: `File simplifications`
- `options`: `Approve (file issues)` → persist `state.consent_to_post_pr_comments = true`; `Decline (no identity posts)` → persist `false`.

Persist the answer (asked at most once per loop). When this routine is invoked from the merge-ready close-out (Step 7.5), consent was already captured at Step 7.1, so it does not re-fire here. Then branch on consent:
- **`false`** (declined here or at Step 7.1): do **not** file — list every would-be entry (`finding_text` + intended label) in the terminal / close-out summary so the operator can file manually. A declined `gh`-identity action posts nothing; the findings are surfaced, never silently dropped.
- **`true`**: for each entry, build the issue with `kind = "simplification"`, `finding_text` as the body's Finding section, and default label `P2-backlog` (skipped if the repo lacks it); append each result to `filed_issues`.

## Step 7: Merge-ready close-out path (effective Blocker count == 0)

Only reached when Step 6.5's effective Blocker count = 0 (no hard Blockers and no age-0 simplifications). This is the merge-bar terminal path — but the loop does NOT just post-and-exit. It first resolves Important + folds easy Suggestions + files issues for non-folded items, then runs ONE verification re-review, then posts a consolidated final PR comment.

### 7.1 First-cycle consent

When `state.consent_to_post_pr_comments == null`, fire `AskUserQuestion`:
- `question`: `Loop hit 0 Blockers. About to begin close-out (resolve Important, fold easy Suggestions, file issues for the rest) and post the final consolidated review as a PR comment under your user identity. Approve?`
- `header`: `Close-out consent`
- `options`:
  - `Accept and close out (Recommended)` — persist `state.consent_to_post_pr_comments = true`; proceed to 7.2.
  - `Decline (no identity posts)` — persist `false`; STILL proceed through 7.2–7.4 (Important + Suggestions are resolved and committed — branch commits, already authorized by running the loop), but make **no `gh`-identity post**: 7.5 files no issues and 7.7 posts no comment. The items 7.5 would have filed (design-pin Suggestions + the deferred-simplification ledger) are listed in the terminal summary for manual filing. Still mark merge_ready.

### 7.2 Process Important items

Initialise a per-close-out working buffer `closeout_log` (a list of strings, one per item handled, for the eventual commit body + final comment).

For each Important finding parsed in Step 5 (numbered list items, in order):

1. **Read the classifier reference once** if not already loaded this cycle: `Read` on `@@PLUGIN_ROOT@@/skills/pr-review-loop/reference/classify-blockers.md`. The same decision tree applies to Important as to Blockers — the difference is the bar, not the procedure.

2. **Classify** mechanical vs design-pin.

3. **If MECHANICAL:**
   - Apply via `Edit`. Minimal change; no adjacent refactoring.
   - Append to `closeout_log`: `Important <K> (mechanical): <file> — <one-line description>`.
   - Emit: `[important <K>] mechanical: <file> :: <one-line description>`.

4. **If DESIGN-PIN:**
   - Fire `AskUserQuestion` with 2-3 defensible options + (Recommended) tag on the safest.
     - `question`: `Important <K> — <verbatim Important title or first sentence>: how to resolve?`
     - `header`: 1-3 word tag
   - Apply the chosen option via `Edit`.
   - Append to `closeout_log`: `Important <K> (design-pin): chose "<answer label>" — <one-line rationale>`.
   - Emit: `[important <K>] design-pin: chose "<answer label>"`.

**All Important must be resolved in this sub-step.** None go to issue filing unless an `AskUserQuestion` explicitly chose a "defer to issue" option (which is not in the standard options — only present if the implementer adds it for cases where the fix is genuinely too large for this pass).

### 7.3 Process Suggestions

Initialise a `issues_to_file` working list. For each Suggestion (numbered list items, in order):

1. **Classify** mechanical vs design-pin via the same heuristics.

2. **If MECHANICAL (= "easy"):**
   - Apply via `Edit`.
   - Append to `closeout_log`: `Suggestion <K> (folded): <file> — <one-line description>`.
   - Emit: `[suggestion <K>] folded: <file> :: <one-line description>`.

3. **If DESIGN-PIN (non-easy):**
   - Do NOT interview. Add to `issues_to_file` an entry: `{kind: "suggestion", number: <K>, finding_text: <verbatim Suggestion text>}`.
   - Emit: `[suggestion <K>] design-pin → queued for issue filing`.

### 7.4 Commit + push close-out fixes

If `closeout_log` is empty (no Edits landed in 7.2 or 7.3): skip this step.

Otherwise:

1. **Stage:** collect the unique set of file paths from `closeout_log`; `git add` each via `Bash`. Verify nothing else is staged via `git status --porcelain --cached` — if unexpected paths appear, `AskUserQuestion` (inspect-diff / skip-step / abort).

2. **Compose commit subject** using Step 9's type/scope inference: `<type>(<scope>): PR <pr_number> close-out (Important + Suggestions)`. Trim per ≤72 char rule (drop scope first, then trim text).

3. **Compose commit body:**
   ```
   Post-merge-bar close-out for PR #<pr_number>.
   Important resolved: <N> (<mechanical / design-pin breakdown>).
   Suggestions folded: <M>.
   Design-pin Suggestions queued for issue filing: <len(issues_to_file)>.

   <closeout_log entries, one per line>

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

4. **Commit + push** via `Bash`: `git commit -F <body-file>` then `git push origin <state.branch>`.

5. **Capture `sha_after_closeout`:** `git rev-parse HEAD`. Step 7.6's verification re-review needs this.

6. Failure paths: same as Step 9 — `AskUserQuestion` on commit/push errors.

7. Emit: `[step 7.4] close-out committed + pushed: <sha7> "<subject>"`.

### 7.5 File issues for non-folded items

**First, fold in the deferred simplifications.** Append every remaining `state.deferred_simplifications` entry to `issues_to_file` as `{kind: "simplification", finding_text: <entry.finding_text>, age: <entry.age>}`, then clear the ledger (`state.deferred_simplifications = []`) — they are accounted for here. This is the merge-ready terminal's discharge of the backoff schedule: no outstanding simplification is dropped.

**Consent guard.** If `state.consent_to_post_pr_comments != true` (declined at Step 7.1), do NOT file: list each `issues_to_file` entry (`finding_text` + intended label) in the close-out summary for manual filing, set `filed_issues = []`, and skip the rest of 7.5. Filing acts under the operator's `gh` identity, which a decline withholds; surfacing the list keeps the no-silent-drops guarantee.

If `issues_to_file` is empty, skip. Otherwise:

1. **Discover repo labels** (once): `gh label list --limit 100` via `Bash`. Parse for priority-tier labels (`P0-critical`, `P1-next`, `P2-backlog`, `P3-someday`). If none of these exist, no labels will be applied. (These names are a convention; absent labels are silently skipped, so the loop works on any repo.)

2. **For each item in `issues_to_file`:**
   a. **Title:** the first sentence of the finding's prose (split on first `. ` or `!`/`?`). Truncate to ≤72 chars with `…` if longer.
   b. **Body:**
      ```
      Surfaced by pr-review-loop on PR #<pr_number> (<repo>) — final-review close-out.
      Filed automatically because the loop classified this <kind> as design-pin / non-foldable.

      ## Finding

      <finding_text verbatim>

      ## Backlinks

      - PR: https://github.com/<repo>/pull/<pr_number>
      - Final review file (local): <review_file_path>
      - Loop skill: https://github.com/WatsonWBlair/lab-claude-plugins (pr-review-loop)
      ```
   c. **Labels:** for `kind="suggestion"`, default to `P3-someday` if it exists; for `kind="simplification"`, default to `P2-backlog` (it is "should-fix" structural debt, not someday-maybe); for `kind="important"` (defensive), default to `P2-backlog`. Apply via `--label` flag, skipping if the label isn't on the repo.
   d. **Create:** `gh issue create --title "<title>" --body-file <body-tmp-file> [--label <label>]`. Capture the resulting issue number from stdout (`gh issue create` prints the issue URL; parse the trailing `/<N>`).
   e. **Record:** append `{number: <N>, title: <title>, url: <url>}` to a working list `filed_issues`.
   f. Emit: `[step 7.5] filed issue #<N>: <title>`.

3. **Failure paths:** `gh issue create` non-zero exit → `AskUserQuestion` (retry / skip-this-item / abort).

### 7.6 Verification re-review

The close-out commit might have regressed the review. Run one more Opus pass against the new HEAD sha to verify.

1. **Skip this step entirely if 7.4 was skipped** (no close-out fixes to verify). The pass-K review is already the final state; jump to 7.7 using the original review file path.

2. **Compute verification review file path:** `${TEMP}/pr<pr_number>_review_pass<state.pass>_verify.md`.

3. **Dispatch** an Opus subagent via `Agent` (same brief shape as Step 4, but: pass `sha_after_closeout` from 7.4 as the head sha; output to the verify file path; emphasize "this is a verification pass after a close-out commit"). Wait for completion.

4. **Parse the verification review** like Step 5: extract recommendation, Blocker count, Important count, Suggestions count, sections. This is a terminal **regression gate**, not a fresh backoff cycle: count **hard Blockers only** (`[regression]` + untagged). A `[simplification]` the verification pass newly surfaces in the close-out diff is filed as a follow-up issue via the deferred-simplification filing routine (Step 6.5), **not** blocked on — the loop does not re-enter the simplification lifecycle at the merge-ready terminal.

5. **If the verification hard-Blocker count == 0:** continue to 7.7 using the verification review file as the source.

6. **If the verification hard-Blocker count > 0:** the close-out regressed the review. Fire `AskUserQuestion`:
   - `question`: `Close-out fixes triggered <N> Blockers in the verification pass. How to proceed?`
   - `header`: `Close-out regression`
   - `options`:
     - `Stop with stuck reason (Recommended)` — set `state.completion_reason = "stuck"` (in-memory); skip 7.7's PR comment posting; the verification review file in `%TEMP%` preserves the regression detail. Perform terminal cleanup in 7.8. Manual `/pr-review-loop` (no --restart needed since state will be cleaned) to address.
     - `Continue as fresh cycle` — bump `state.pass`, jump back to Step 6 with the verification review as cycle K+1's source. Bounded by `max_iterations`.
     - `Force exit as merge_ready (override)` — set `merge_ready` regardless; print warning. Useful when the human inspects and decides the new Blockers are false-positives.

7. Emit: `[step 7.6] verification: <N> blockers, <M> important, <S> suggestions, decision: <continue | regression-stop | force-exit>`.

### 7.7 Post final consolidated PR comment

If `state.consent_to_post_pr_comments != true`, skip this step (still mark merge_ready in 7.8).

Otherwise:

1. **Compose the comment body** by concatenating, in order:
   - The verification review file contents (from 7.6, OR the original review file if 7.6 was skipped).
   - A `## Close-out actions` section:
     ```
     ## Close-out actions

     - **Important resolved:** N (<X mechanical, Y design-pin via interview>)
     <one bullet per closeout_log Important entry>

     - **Suggestions folded:** M
     <one bullet per closeout_log Suggestion entry>

     - **Issues filed for future work:** K
     <one bullet per filed_issues entry as: #<N> — <title> (<url>)>
     ```
   Write this composed body to a temp file.

2. **Post:** `gh pr comment <state.pr_number> --body-file <temp-file>` via `Bash`.

3. **Verify landing:** `gh pr view <state.pr_number> --json comments --jq '.comments[-1].body' | head -5` — confirm the first 5 lines match.

4. Failure: `AskUserQuestion` (retry / skip-and-continue / abort).

5. Emit: `[step 7.7] final comment posted: <url from gh output>`.

### 7.8 Terminal cleanup and exit

1. Update in-memory state: `state.status = "complete"`, `state.completion_reason = "merge_ready"` (or `"stuck"` if 7.6 routed there). No file write — about to be deleted.
2. Print the terminal summary block:
   - `🎯 Merge bar met` (or `⚠ Stuck after close-out regression` if applicable).
   - `PR: #<pr_number> on <repo> @ <branch>` + `HEAD <sha_after_closeout or current sha>`.
   - `Cycles run: <state.pass>` + `Close-out: Important resolved <N>, Suggestions folded <M>, Issues filed <K>`.
   - `Final comment URL: <url>` if 7.7 posted.
   - `Issues filed:` enumerate `filed_issues`.
3. **Perform terminal cleanup:** `rm .claude/.pr-review-loop.state.json` via `Bash`. The state file is gone; audit trail persists in git log + the final PR comment + the verification review file in `%TEMP%`.
4. Emit `<promise>LOOP_DONE</promise>` as a standalone line.
5. Stop.

## Step 8: Fix loop (effective Blocker count > 0)

Only reached when Step 6.5's effective Blocker count > 0 AND Step 6 (stuck-detector) did not interrupt.

1. **Read the classifier reference once per cycle.** Use the `Read` tool on `@@PLUGIN_ROOT@@/skills/pr-review-loop/reference/classify-blockers.md` to load the decision tree. The tree + worked examples there are the contract for the rest of this step — including how an age-0 `[simplification]` is classified (obvious extraction → mechanical; real restructure → one design-pin interrupt, then deferred — never re-interviewed on later passes).

2. **For each item in `gate_blocker_text` (numbered list items, in order — hard Blockers first, then the age-0 `[simplification]` findings re-admitted by Step 6.5):**

   a. **Classify** by walking the decision tree from `classify-blockers.md`. Mechanical markers: hard rule violation with single text-level fix; missing path/edge/typo/count-of-N inconsistency; future-tense reference to a closed item; section heading level wrong; two enumerated options where one is the simplest-defensible additive fix. Design-pin markers: option A vs B with meaningfully different downstream implications; "pin a shape" framing; conflicting spec interpretations; consent surface; explicit "implementer's choice with downstream impact" language. **Conservative fall-through: ambiguous → design-pin.**

   b. **Initialise a per-cycle working buffer** `cycle_fix_log` (a list of strings, one per Blocker addressed, formatted for the eventual commit body).

   c. **If MECHANICAL:**
      - Identify the file path(s) the Blocker names and the exact text-level change required.
      - Apply via the `Edit` tool. Make the minimal change that satisfies the Blocker — do not refactor adjacent prose, do not pre-emptively fix unrelated typos in the same file.
      - Append to `cycle_fix_log`: `Blocker <K> (mechanical): <file> — <one-line description of the change>`.
      - Emit: `[blocker <K>] mechanical: <file> :: <one-line description>`.

   d. **If DESIGN-PIN:**
      - Identify 2-3 defensible resolution options. The Blocker's prose usually names them — extract verbatim and tighten. If only one option is explicit, generate the realistic alternatives (typical pattern: option from prose + the lower-effort fallback + the YAGNI cut).
      - Tag the safest option with `(Recommended)`. "Safest" = least downstream redesign, matches existing repo state, smallest commit diff.
      - Fire `AskUserQuestion`:
        - `question`: `Blocker <K> — <verbatim Blocker title or first sentence>: how to resolve?`
        - `header`: a 1-3 word tag identifying the Blocker (e.g. `CI gate names`, `Artifact payload`)
        - `options`: 2-3 entries with `label` + `description` per `AskUserQuestion` tool spec
      - On user answer: apply the chosen option via `Edit`. The option's description tells you what concrete edit(s) to make.
      - Append to `cycle_fix_log`: `Blocker <K> (design-pin): chose "<answer label>" — <one-line rationale from the option's description>`.
      - Emit: `[blocker <K>] design-pin: chose "<answer label>"`.

3. **After all Blockers processed:** carry `cycle_fix_log` to Step 9 for the commit body.

## Step 9: Stage + commit + push

0. **Skip the commit if nothing was fixed.** If `cycle_fix_log` is empty — which happens when the only gate items were age-0 `[simplification]` findings the user chose to defer at the design-pin interrupt — emit `[step 9] no fixes landed this cycle; aging the deferred simplification(s)` and jump to Step 10 (the aged ledger still needs persisting). Do not create an empty commit.

1. **Determine the files touched this cycle.** From `cycle_fix_log` extract the unique set of file paths. Do NOT use `git add -A` or `git add .` — those pick up unrelated changes (the loop must not cross scope boundaries on the head branch).

2. **Stage:** `git add <each-file>` via `Bash`. Verify nothing else is staged: `git status --porcelain --cached` — if any unexpected paths appear, fire an `AskUserQuestion` with options to inspect-diff / skip-cycle / abort.

3. **Infer commit type + scope.** Read the most recent 5 commit subjects on the branch via `git log -5 --pretty=%s`. The dominant `<type>(<scope>):` prefix (mode of the 5) is the cycle's type/scope. If the branch has fewer than 5 commits, use the most recent. Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. If no clear pattern, default to `<type>` = `docs` for plan/markdown changes or `chore` for everything else, and skip scope.

4. **Compose the commit subject.** Template: `<type>(<scope>): address PR <pr_number> pass-<state.pass> review`. Verify length ≤ 72 chars. If over, drop `(<scope>)` first; if still over, shorten to `<type>: PR <#> pass-<K> review`.

5. **Compose the commit body.** Structure:
   ```
   Pass-<K> outsider review surfaced <N> Blockers (<M> mechanical, <D> design-pin).
   All addressed in this commit; <M2> Important + <S> Suggestions persist for triage.

   <cycle_fix_log entries, one per line>

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```
   Replace the placeholders with real values. Adjust the trailer to your project's commit convention if it differs.

6. **Commit:** `git commit -F <body-file>` via `Bash` (write the body to a temp file first to avoid shell escaping issues with multiline). Or use `git commit -m "<subject>" -m "<body>"` if the body has no special chars.

7. **Push:** `git push origin <state.branch>` via `Bash`. Capture stdout + stderr.

8. **Failure paths:**
   - `git add`, `git commit`, or `git push` exit non-zero: fire `AskUserQuestion`:
     - Show error (print full stdout+stderr, then re-ask)
     - Skip cycle (leave fixes uncommitted; set `state.completion_reason = "stuck"`, perform terminal cleanup, emit `<promise>LOOP_DONE</promise>`, exit)
     - Abort (set `state.completion_reason = "user_abort"`, perform terminal cleanup, emit promise, exit)
   - Commit succeeded but push failed (e.g. branch protection rejection, network): same `AskUserQuestion`, but additionally surface "retry push" as a fourth option.

9. **Capture `sha_after`:** run `git rev-parse HEAD` again. This is the post-commit sha; Step 10 appends it to `blocker_history`.

10. Emit: `[step 9] committed + pushed: <sha_after_7> "<subject>"`.

## Step 10: Update state file

Only reached when Step 6.5 routed to Step 8 (effective Blocker count > 0), so Step 7's merge-ready terminal did not fire. Reached whether or not Step 9 committed — a deferred-only cycle (Step 9.0) skips the commit but still persists the aged ledger here.

1. **Capture cycle outcome:** at this point you have `sha_before` (from Step 3) and `sha_after` (from Step 9 step 9). If Step 9 was skipped (Step 9.0, no commit), `sha_after = sha_before` — HEAD is unchanged this cycle.

2. **Update state:**
   - Append to `state.blocker_history`:
     ```json
     {"pass": <state.pass (current value, before increment)>,
      "count": <Step 6.5's effective_blocker_count>,
      "sha_before": "<sha_before>",
      "sha_after": "<sha_after>"}
     ```
   - Set `state.last_blocker_text` = `hard_blocker_text` (Step 5) — **hard Blockers only**, so the Step 6 stuck-detector never trips on a self-demoting simplification.
   - Set `state.deferred_simplifications` = the reconciled ledger from Step 6.5 (new + aged entries; resolved and age≥3-filed entries already removed).
   - Increment `state.pass` by 1.

3. **Atomic write the state file:**
   a. Write the full state JSON to `.claude/.pr-review-loop.state.json.tmp` via the `Write` tool.
   b. `mv .claude/.pr-review-loop.state.json.tmp .claude/.pr-review-loop.state.json` via `Bash`.

4. Emit summary: `[step 10] state updated: pass=<new pass>, history len=<len(blocker_history)>, last_blocker_text=<N chars>, deferred_simplifications=<len(state.deferred_simplifications)>`.

## Step 11: Try to exit

1. This cycle's work is done. Stop generating output — emit no further content for this iteration.

2. The ralph framework's stop hook (registered by the ralph-loop plugin) will intercept the termination, increment the iteration counter in `.claude/ralph-loop.local.md`, and re-feed this PROMPT.md back as the next iteration's input. You'll wake up at Step 1 of the next cycle with the just-persisted state.

3. **Do NOT emit `<promise>LOOP_DONE</promise>` here.** The promise is reserved for terminal exit paths (Step 2's max_iter, Step 6's stuck-abort, Step 7's merge_ready, or any error-path abort that sets `completion_reason = "user_abort"`). Emitting it here would short-circuit the loop after one cycle.

4. The framework's `--max-iterations` safety bound is independent of `state.max_iterations`: the ralph framework counts its own iterations and force-stops after the limit set at loop-init time. Step 2 above is the skill-level safety bound and is the one that emits `max_iter`. Both bounds being equal (default 5) means they trip together; if they diverge, Step 2 trips first.
