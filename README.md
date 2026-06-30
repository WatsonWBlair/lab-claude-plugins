# lab-claude-plugins

A [Claude Code](https://code.claude.com) plugin marketplace from the CAMELS Research Group lab. Install once, then use the plugins in any repo.

## Plugins

| Plugin | What it does |
|---|---|
| **pr-review-loop** | Drives a GitHub PR through alternating review and remediation passes until an outsider review returns 0 Blockers, then runs a close-out sub-flow (resolve Important findings, fold easy Suggestions, file issues for the rest, post one consolidated PR comment). On code-touching PRs it applies a **code-quality rubric**: structural regressions hard-block; missed simplifications follow a backoff schedule (Blocker → Important → follow-up issue) so the bar stays reachable. |
| **logging-automation** | Detects loggable moments and drafts correctly-routed, correctly-formatted audit-trail log entries by *applying* `lab-os .claude/rules/03-logging.md` (source of truth) — it does not redefine the rules. Load-bearing-decision writes are gated behind human approval. **First designated consumer: mission-control Phase 6** (`log:` capture flow) — MC Phase 6 is designed to consume this skill's routing, format, and gate logic; MC retains its own approve-UI, `log_entries` store, file-append, and divergence tripwire. Consumer contract: `plugins/logging-automation/skills/logging-automation/reference/consumer-contract.md`. |
| **prompt-optimization** | Hardens or restructures a prompt in two modes — **augment** (adds context-appropriate hardening clauses from a curatable library while preserving your original wording) or **rewrite** (produces a full AI-ready restructure with an explicit goal, success criterion, scope boundary, and output contract). Available as both a slash command (`/optimize-prompt`) and an auto-triggering skill. No loop-framework dependency. |

## Install

```
/plugin marketplace add WatsonWBlair/lab-claude-plugins
/plugin install pr-review-loop@lab-claude-plugins
/plugin install logging-automation@lab-claude-plugins
/plugin install prompt-optimization@lab-claude-plugins
```

### Dependency: `ralph-loop`

`pr-review-loop` is powered by the **`ralph-loop`** plugin's stop-hook framework and declares it as a dependency, so it installs automatically on recent Claude Code versions.

If your version predates plugin dependencies (or the auto-install is blocked), install it manually first:

```
/plugin install ralph-loop@claude-plugins-official
```

`ralph-loop` ships in Anthropic's official `claude-plugins-official` marketplace, which is configured in Claude Code by default.

## Usage

### pr-review-loop

```
/pr-review-loop <PR#> [--max-iterations 5] [--bar 0-blockers] [--restart]
```

Run it from inside a git repo with an open PR you have push access to. The loop:

1. Dispatches an outsider review subagent each cycle.
2. Auto-fixes mechanical Blockers; interrupts with a question only on design-pin judgment calls.
3. Commits + pushes remediation per cycle.
4. On reaching 0 Blockers, runs the close-out sub-flow and posts a consolidated final comment **under your `gh` identity** (with consent, asked once per loop).

Cancel mid-loop with `/cancel-ralph`. See the plugin's `SKILL.md` for the full interrupt model and merge-bar semantics.

#### Code-quality rubric (code-touching PRs)

On PRs that change code, each review pass also applies a structural code-quality rubric (`reference/code-quality-rubric.md`, adapted from Cursor's MIT-licensed `thermo-nuclear-code-quality-review`). The subagent tags every structural finding:

- **`[regression]`** — a structural regression this PR introduces (a file crossing 1000 lines in-diff, a new ad-hoc branch wedged into an unrelated flow, or feature logic leaked into a shared/canonical path). These are **hard Blockers** and gate the merge bar every cycle until fixed.
- **`[simplification]`** — a missed simplification the PR adds ("code-judo" smells: thin wrappers, cast/optionality churn, near-duplicates of a canonical helper). These follow a **backoff schedule** — a Blocker the first cycle (age 0), Important on the next one or two (age 1–2), then a follow-up GitHub issue at age ≥ 3 or any terminal exit. The backoff gives each missed simplification one cycle of real push while keeping the 0-Blocker bar reachable; the issue-fallback guarantees nothing is silently dropped.

Only findings the PR itself introduces are in scope (diff-scoped). Doc/plan-only PRs are unchanged — the rubric is not referenced.

### logging-automation

```
/log [<repo>] <what happened>
```

Capture a loggable moment as a correctly-routed, correctly-formatted log-entry draft. With no arguments, it scans the current conversation for the most recent loggable moment and surfaces it for confirmation. The skill:

1. Classifies the moment against the three entry triggers (load-bearing decision / irreversible or external event / direction change), or routes it elsewhere (PR comment, plan execution log, issue, …) when no trigger fires.
2. Resolves the owning log altitude (lab / project / plan-execution) and the exact target file.
3. Drafts the entry in the canonical `03-logging.md` format and presents it.

It is **draft-only**: load-bearing decisions and direction changes are held for your explicit approval, and the skill never writes, commits, or posts on its own. It can also fire automatically when a session reaches a loggable moment. See the plugin's `SKILL.md` and `consumer-contract.md` for the full classification, routing, and gate model.

### prompt-optimization

```
/optimize-prompt [--augment | --rewrite] <prompt text>
```

Pass your prompt as the argument, or invoke with no argument to optimize the most recent user message in the conversation.

- `--augment` — adds hardening clauses from the curatable boilerplate library to your original prompt; preserves your wording; names every clause it added and why
- `--rewrite` — restructures the prompt from scratch with an explicit goal, success criterion, scope boundary, and output contract; interviews you with bounded clarifying questions if the prompt is too ambiguous to rewrite safely
- _(no flag)_ — mode is inferred from your request; defaults to **augment** when intent is genuinely ~50/50 (least disruptive)

The skill also fires automatically when you describe a prompt as vague, incomplete, or missing guardrails, or ask to make a prompt "model-ready" — no explicit command needed.

**Augment output:** your original prompt, unchanged, followed by a labeled `## Augmentation` block listing what was added and why.
**Rewrite output:** the optimized prompt as a standalone block, followed by a labeled rationale for the structural changes.

This plugin has **no loop-framework dependency** — the rewrite interview is a normal conversational turn, not a ralph-style automated loop. Unlike `pr-review-loop`, you do not need `ralph-loop` installed.

## Requirements

- Claude Code with plugin support
- **pr-review-loop:** the `ralph-loop` plugin (see above); `gh` CLI, authenticated, with push access to the PR's head branch
- **logging-automation:** read access to the lab logging rules it applies (`lab-os/.claude/rules/03-logging.md`, source of truth); no network or `gh` dependency
- **prompt-optimization:** no additional dependencies — no `ralph-loop`, no network access, no `gh` CLI required

## Contributing / forking

MIT licensed — see [LICENSE](LICENSE). Fork it and adapt to your project's conventions — for `pr-review-loop`, adjust the merge bar and swap the commit trailer; its issue-filing labels (`P0`…`P3`) are applied only if your repo already defines them. `logging-automation` applies the lab's `03-logging.md` rules, so point it at your own logging standard if you fork it.
