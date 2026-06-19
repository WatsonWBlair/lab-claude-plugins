# lab-claude-plugins

A [Claude Code](https://code.claude.com) plugin marketplace from the CAMELS Research Group lab. Install once, then use the plugins in any repo.

## Plugins

| Plugin | What it does |
|---|---|
| **pr-review-loop** | Drives a GitHub PR through alternating review and remediation passes until an outsider review returns 0 Blockers, then runs a close-out sub-flow (resolve Important findings, fold easy Suggestions, file issues for the rest, post one consolidated PR comment). |
| **logging-automation** | Detects loggable moments and drafts correctly-routed, correctly-formatted audit-trail log entries by *applying* `lab-os .claude/rules/03-logging.md` (source of truth) — it does not redefine the rules. Load-bearing-decision writes are gated behind human approval. **First designated consumer: mission-control Phase 6** (`log:` capture flow) — MC Phase 6 is designed to consume this skill's routing, format, and gate logic; MC retains its own approve-UI, `log_entries` store, file-append, and divergence tripwire. Consumer contract: `plugins/logging-automation/skills/logging-automation/reference/consumer-contract.md`. |

## Install

```
/plugin marketplace add WatsonWBlair/lab-claude-plugins
/plugin install pr-review-loop@lab-claude-plugins
/plugin install logging-automation@lab-claude-plugins
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

### logging-automation

```
/log [<repo>] <what happened>
```

Capture a loggable moment as a correctly-routed, correctly-formatted log-entry draft. With no arguments, it scans the current conversation for the most recent loggable moment and surfaces it for confirmation. The skill:

1. Classifies the moment against the three entry triggers (load-bearing decision / irreversible or external event / direction change), or routes it elsewhere (PR comment, plan execution log, issue, …) when no trigger fires.
2. Resolves the owning log altitude (lab / project / plan-execution) and the exact target file.
3. Drafts the entry in the canonical `03-logging.md` format and presents it.

It is **draft-only**: load-bearing decisions and direction changes are held for your explicit approval, and the skill never writes, commits, or posts on its own. It can also fire automatically when a session reaches a loggable moment. See the plugin's `SKILL.md` and `consumer-contract.md` for the full classification, routing, and gate model.

## Requirements

- Claude Code with plugin support
- **pr-review-loop:** the `ralph-loop` plugin (see above); `gh` CLI, authenticated, with push access to the PR's head branch
- **logging-automation:** read access to the lab logging rules it applies (`lab-os/.claude/rules/03-logging.md`, source of truth); no network or `gh` dependency

## Contributing / forking

MIT licensed — see [LICENSE](LICENSE). Fork it and adapt to your project's conventions — for `pr-review-loop`, adjust the merge bar and swap the commit trailer; its issue-filing labels (`P0`…`P3`) are applied only if your repo already defines them. `logging-automation` applies the lab's `03-logging.md` rules, so point it at your own logging standard if you fork it.
