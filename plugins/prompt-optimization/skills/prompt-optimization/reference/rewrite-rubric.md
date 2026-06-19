# Rewrite Rubric and Ambiguity-Interview Trigger

This file is the single source of truth for rewrite mode in the `prompt-optimization` skill. It defines what a rewritten prompt must contain, the test that determines whether a source prompt is safe to rewrite, and the interview branch that fires when it is not. `SKILL.md` loads this file and delegates to it; this file does not duplicate clause content from `boilerplate-library.md` and does not contain mode-selection logic.

---

## 1. What an AI-ready rewritten prompt must contain

A rewritten prompt is AI-ready when it gives a model reader — cold, without access to the author's mental context — everything needed to produce a useful, on-target response. Four required structural elements:

### 1.1 Explicit goal

The *why* behind the ask: what outcome the prompt author actually wants to achieve, not just the surface task. A prompt that says "summarize this document" is incomplete; "summarize this document so I can decide whether it warrants a full read" states the goal and changes how the summary should be shaped.

A rewritten prompt makes the goal explicit in its opening sentence or first clause. If the goal was implicit in the source, the rewrite surfaces it — and the rationale notes what was inferred.

### 1.2 Success criterion

The standard against which a good response can be recognized. This is distinct from the goal: the goal says *what for*; the success criterion says *what done looks like*.

Examples of weak prompts missing this element: "write some tests for this function," "make this cleaner," "draft a response." Examples of success criteria: "three tests covering the normal path, the empty-input edge case, and the error path," "a version a non-technical reader can follow in under two minutes," "a response that declines the request without naming a reason."

The rewritten prompt states the success criterion explicitly, in a form the model can use to self-check its output.

### 1.3 Scope boundary (what is out of scope)

Unspecified scope is a common source of agent overreach and unhelpful over-answering. The rewritten prompt names at least one explicit out-of-scope constraint when the source prompt's scope is open-ended or when overreach is a foreseeable failure mode.

Not every rewrite requires a negative scope statement. A narrow, concrete prompt may not need one. When in doubt, include it: "Do not rewrite the existing tests; only add the missing cases."

### 1.4 Output contract

The shape of the expected response: format, length, medium, or structural elements the model should produce. Without this, models default to an average-case shape that may not fit the author's consumption context.

Examples: "Return a markdown table with columns X, Y, Z," "A single sentence," "A bulleted checklist, not prose," "Return only the revised paragraph — no preamble, no commentary," "A JSON object matching this schema."

The rewritten prompt states the output contract explicitly. If the source prompt implied a shape by example or by context, the rewrite makes it explicit and the rationale names the inference.

---

## 2. Ambiguity test

Rewrite mode runs this test before drafting. A source prompt fails the test — and the interview branch fires — when any of the following conditions holds:

**A. Goal absent and non-inferable.** The prompt states a task but gives no indication of the outcome the author wants. The goal cannot be inferred from context, domain, or the phrasing of the task itself with high confidence.

**B. Success criterion missing and multiple plausible standards exist.** The prompt does not specify what a good response looks like, and reasonable completions of the task would look substantially different depending on which standard applies (e.g., "review this code" could mean: find bugs only; find style violations too; rewrite it; rate it on a rubric — all are plausible without a criterion).

**C. Multiple incompatible readings of the core task.** The prompt's verb, object, or scope permits two or more readings that would produce substantially different outputs. "Improve the onboarding flow" could mean: rewrite the copy, redesign the UX, fix the code, or draft a proposal to redesign. These are not style variants; they are different tasks.

**D. Scope is so open that any response qualifies.** The prompt has no implicit or explicit constraint on topic, depth, format, or medium, and the domain is large enough that the model would have to make a significant narrowing choice to respond at all.

**E. An output contract is required but entirely absent and un-inferable.** The prompt's context provides no signal about what form the response should take, and the choice of form would materially affect usefulness (e.g., a data-heavy analysis where table vs prose vs code vs narrative each serve different downstream uses).

**Threshold:** a single condition is sufficient to trip the test. Partial ambiguity — where one element is weak but the rest are clear — is a judgment call; when the missing element is A (goal) or C (incompatible readings), the bar is lower and the interview should fire. When only D or E is missing and a reasonable default exists, the rewrite may proceed with the default stated in the rationale rather than interviewing.

---

## 3. Interview branch

When the ambiguity test trips, the skill enters the interview branch rather than inventing intent.

### 3.1 Character of the interview

The interview is a **normal conversational turn**: the skill surfaces a small, bounded set of specific questions in a single response and waits for the author's reply. It is not an autonomous re-feed loop, a ralph-style multi-cycle harness, or a chained series of sequential questions one at a time. This plugin has no loop-framework dependency; the interview is a single exchange, not a multi-turn protocol.

### 3.2 Question discipline

Questions must be:

- **Specific and bounded.** Each question names the gap it targets (goal, success criterion, scope, output contract, or incompatible reading) and offers concrete options where options exist. Vague questions ("can you say more?") are not permitted.
- **Minimal.** Ask only what is needed to unblock the rewrite. If the success criterion is clear and the output contract is inferable, do not ask about them. Each question must map to a distinct ambiguity condition from Section 2.
- **Non-leading.** The question names the ambiguity without suggesting a preferred answer that the author might accept out of convenience rather than accuracy.
- **Ceiling-bound.** No more than five questions per interview pass. If five questions would not resolve the ambiguity, prioritize the conditions in this order: A (goal) → C (incompatible readings) → B (success criterion) → D (scope) → E (output contract).

### 3.3 Interview ceiling and terminal behavior

The interview ceiling is **five questions in one pass**. When the ceiling is reached:

**If the author replies and the replies are sufficient:** proceed to the rewrite using the author's answers.

**If the ceiling is reached and replies are still insufficient, or if the author explicitly declines to answer:** proceed with explicitly-stated assumptions. The rewrite output labels each assumption clearly ("Assuming: the goal is X, because Y" for each unresolved gap). This is the **confirmed v1 default** (Watson signed off the four prompt-optimization design defaults on 2026-06-19; see the plan's Execution Log). A future version may offer a "too ambiguous — here is what I need" handoff instead.

**The "hand-back" option** (returning "too ambiguous — here is what I'd need" without a rewrite attempt) is reserved for cases where the ambiguity is so severe that a rewrite with stated assumptions would be actively misleading rather than merely imperfect. This is the exception, not the default. When choosing hand-back, state explicitly what information would unblock the rewrite.

---

## 4. Rewrite output contract

Every rewrite output contains two parts, always both present:

### 4.1 The optimized prompt

The rewritten prompt, presented as a standalone block the author can copy and use directly. It must satisfy all four elements from Section 1 (goal, success criterion, scope boundary, output contract). It should not be longer than necessary: economy of language is part of being AI-ready.

### 4.2 The rationale

A short explanation of the structural changes made, written to serve the author's understanding rather than to justify the rewrite. The rationale:

- Names each structural element that was added or changed and why (e.g., "Added an explicit goal because the source prompt named the task but not the intended outcome").
- Names any goal, success criterion, scope, or output contract that was inferred from context — and states what context supported the inference. This is the author's check against misread intent.
- Notes any assumption made when the interview ceiling was reached (per Section 3.3).
- Is brief: a few sentences to a short bulleted list is the target. It is not a lecture on prompt engineering.

The rationale is presented as a labeled section after the optimized prompt, not woven into the prompt itself. The boundary between the optimized prompt and the rationale must be visually clear so the author can extract the prompt without editing.

---

## 5. Scope constraint (single-source note)

This file owns the rewrite rubric and the ambiguity-interview rules. It does not own:

- The boilerplate clause library — that is `reference/boilerplate-library.md`.
- The augment-mode selection heuristics — that is `reference/augment-heuristics.md`.
- The mode-selection contract (augment vs rewrite, default behavior, flag handling) — that is `skills/prompt-optimization/SKILL.md`.

If a rewrite would benefit from boilerplate clauses (e.g., adding an output contract that matches an existing library entry), the skill may reference the library, but this file does not duplicate library content.
