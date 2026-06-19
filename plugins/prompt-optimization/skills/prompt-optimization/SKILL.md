---
name: prompt-optimization
description: Use when the user asks to optimize, improve, harden, or tighten a prompt; when /optimize-prompt is invoked; when a user hands over a rough prompt to be made AI-ready; when a prompt is described as vague, incomplete, or missing guardrails; or when the user asks for help making a prompt "production-ready" or "model-ready."
---

# prompt-optimization

> **Single-source note:** This skill contains no clause text and no rubric content. Library clauses live in `reference/boilerplate-library.md`; augment selection logic lives in `reference/augment-heuristics.md`; rewrite structure and interview rules live in `reference/rewrite-rubric.md`. This file is the router and mode-selection surface only.

## Overview

This skill optimizes a prompt in one of two modes — **augment** (add hardening boilerplate to the original) or **rewrite** (produce a full AI-ready restructure) — and presents a clear record of what changed and why so the user can audit the result.

The skill does not depend on a loop framework. The clarifying-question interview in rewrite mode is a normal conversational turn — a bounded question set in a single response, followed by the user's reply — not a ralph-style re-feed loop. No `ralph-loop` dependency is needed or declared.

---

## Input channel

The prompt to be optimized is taken from:

1. The command argument when invoked as `/optimize-prompt <prompt>` (or with flags: `/optimize-prompt --augment <prompt>`, `/optimize-prompt --rewrite <prompt>`).
2. When no argument is given, the most recent user message in the conversation.

---

## Mode-selection contract

Mode is determined in this priority order:

1. **Explicit flag** — `--augment` or `--rewrite` in the invocation. An explicit flag always wins; skip inference.
2. **Inferred intent** — when no flag is given, read the user's request for signals:
   - Signals toward **rewrite**: user says "rewrite," "restructure," "make this AI-ready from scratch," "completely redo," or the prompt is so thin that augmentation would add more text than the original.
   - Signals toward **augment**: user says "add guardrails," "harden," "tighten," "what clauses should I add," or the prompt already has substantial structure worth preserving.
   - Intent is genuinely ~50/50: **default to augment** — augment is the least-surprising, non-destructive choice (it preserves the author's wording; a rewrite discards it). This default is confirmed and does not require re-asking.
3. **State the selected mode** before doing any work. One sentence is sufficient: "Running in augment mode — adding hardening clauses to your prompt." Do not proceed until the mode is stated.

The user may override after seeing the mode statement; if they do, re-run in the requested mode without requiring a new invocation.

---

## Augment branch

When augment mode is selected:

1. Load [`reference/augment-heuristics.md`](reference/augment-heuristics.md). That file is the operative logic; follow it exactly.
2. Follow the augment heuristics to classify the prompt shape, evaluate each library entry's applicability, apply the conflict-suppression rule, and check for contradictions with the original prompt's instructions. Clause text is always fetched verbatim from [`reference/boilerplate-library.md`](reference/boilerplate-library.md) — never paraphrased.
3. Return the result in this order:
   - The original prompt, unchanged.
   - A clearly labelled append-block (e.g. `## Augmentation`) containing the applied clauses in verbatim form.
   - The enumeration required by the augment heuristics output contract: applied clauses (id, provenance, applicability match reason) and suppressed clauses (id, suppression reason).

Do not restructure, rephrase, or rewrite any part of the original prompt. If the prompt is so under-specified that no library entry is applicable, state that and suggest rewrite mode instead.

---

## Rewrite branch

When rewrite mode is selected:

1. Load [`reference/rewrite-rubric.md`](reference/rewrite-rubric.md). That file is the operative logic; follow it exactly.
2. Run the ambiguity test (Section 2 of the rubric) on the source prompt. The test may pass or trip:
   - **Test passes** (prompt is sufficiently clear): proceed to the rewrite.
   - **Test trips** (one or more ambiguity conditions hold): enter the interview branch (Section 3 of the rubric). Ask a bounded, specific question set — ceiling of five questions — in a single response and wait for the user's reply. Do not re-feed autonomously. The interview is a normal conversational turn.
3. Produce the rewrite output per the rubric's Section 4 output contract:
   - The optimized prompt as a standalone block satisfying all four rubric elements (goal, success criterion, scope boundary, output contract).
   - A labeled rationale section naming the structural changes made, any inferences drawn from context, and any assumptions stated when the interview ceiling was reached.

Do not embed clause text from the boilerplate library directly in the rewritten prompt unless the user requests it; rewrite mode restructures the prompt, it does not paste augment clauses.

---

## Reference files

- [`${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/boilerplate-library.md`](reference/boilerplate-library.md) — the single source for all hardening clause text and entry metadata (applicability, conflict, provenance). Augment branch reads clause text from here.
- [`${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/augment-heuristics.md`](reference/augment-heuristics.md) — augment-mode selection logic: prompt shape classification, context-awareness rule, conflict-suppression rule, output contract.
- [`${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/reference/rewrite-rubric.md`](reference/rewrite-rubric.md) — rewrite-mode structure: four required elements of an AI-ready prompt, the ambiguity test, interview branch rules, rewrite output contract.
