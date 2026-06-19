---
description: "Optimize a prompt in augment mode (add hardening boilerplate) or rewrite mode (full AI-ready restructure); mode is inferred from intent when no flag is given, defaulting to augment."
argument-hint: "[--augment | --rewrite] <prompt text>"
allowed-tools: ["Read"]
---

# /optimize-prompt

Harden or restructure a prompt using the two-mode optimization skill.

**No arguments?** The prompt is taken from the most recent user message in the conversation. Invoke with no argument when you've already pasted the prompt into chat.

**With arguments?** Pass the prompt text directly, optionally prefixed by a mode flag:
- `/optimize-prompt --augment <prompt>` — forces augment mode (add hardening clauses; preserve original wording)
- `/optimize-prompt --rewrite <prompt>` — forces rewrite mode (full AI-ready restructure with interview if ambiguous)
- `/optimize-prompt <prompt>` — mode is inferred from request intent; defaults to augment when intent is genuinely ~50/50

## Input channel

The prompt to be optimized is resolved in this order:

1. The text in `$ARGUMENTS` after stripping any leading `--augment` or `--rewrite` flag.
2. When `$ARGUMENTS` is empty, the most recent user message in the conversation.

State which source was used before proceeding.

## Flow

Run the full mode-selection and optimization procedure defined in `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/SKILL.md`:

1. **Resolve mode** — apply the mode-selection contract (explicit flag wins; inferred intent second; augment-as-default when genuinely ambiguous). State the selected mode in one sentence before doing any further work.

2. **Augment branch** — if augment mode: load `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/augment-heuristics.md`, classify the prompt shape, select and apply library entries from `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/boilerplate-library.md`, suppress conflicts, and return the original prompt followed by a labeled `## Augmentation` block with the applied clauses and an enumeration of what was added and why.

3. **Rewrite branch** — if rewrite mode: load `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/rewrite-rubric.md`, run the ambiguity test, conduct a bounded clarifying-question interview (ceiling: five questions in one response) if the test trips, then return the optimized prompt and a labeled rationale for the structural changes.

## Output contract

- Always state the selected mode before producing output.
- Augment output: original prompt unchanged + `## Augmentation` block + applied/suppressed clause enumeration.
- Rewrite output: optimized prompt as a standalone block + labeled rationale section.
- The user can see from the output alone what changed and why — augment names the clauses added; rewrite names the structural changes made.
- No loop framework is involved. The rewrite interview is a normal conversational turn; this command does not depend on ralph-loop or any loop state file.
