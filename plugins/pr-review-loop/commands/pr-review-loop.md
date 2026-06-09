---
description: "Drive a PR through review-remediate cycles until the merge bar is met"
argument-hint: "<PR#> [--max-iterations N] [--bar VALUE] [--restart]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh:*)"]
---

# /pr-review-loop

Initialize pr-review-loop state and hand off to the ralph framework.

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" $ARGUMENTS
```

After the setup script writes the state files and emits PROMPT.md content, follow PROMPT.md's instructions for iteration 1. The ralph stop hook re-feeds the prompt each cycle. Emit `<promise>LOOP_DONE</promise>` only when a terminal state is genuinely reached (`merge_ready`, `max_iter`, stuck-aborted-by-user, or `user_abort`).

See: `${CLAUDE_PLUGIN_ROOT}/skills/pr-review-loop/SKILL.md`
