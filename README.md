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

```
/pr-review-loop <PR#> [--max-iterations 5] [--bar 0-blockers] [--restart]
```

Run it from inside a git repo with an open PR you have push access to. The loop:

1. Dispatches an outsider review subagent each cycle.
2. Auto-fixes mechanical Blockers; interrupts with a question only on design-pin judgment calls.
3. Commits + pushes remediation per cycle.
4. On reaching 0 Blockers, runs the close-out sub-flow and posts a consolidated final comment **under your `gh` identity** (with consent, asked once per loop).

Cancel mid-loop with `/cancel-ralph`. See the plugin's `SKILL.md` for the full interrupt model and merge-bar semantics.

### Requirements

- Claude Code with plugin support
- `ralph-loop` plugin (see above)
- `gh` CLI, authenticated, with push access to the PR's head branch

## Contributing / forking

MIT licensed — see [LICENSE](LICENSE). Fork it, adapt the merge bar, swap the commit trailer for your project's convention. The plugin makes no assumptions about your repo beyond `gh` + a GitHub PR; issue-filing labels (`P0`…`P3`) are applied only if your repo already defines them.
