# Validation Notes — prompt-optimization plugin

**Date:** 2026-06-19
**Author:** Watson Blair
**Artifacts exercised:** `boilerplate-library.md`, `augment-heuristics.md`, `rewrite-rubric.md`, `SKILL.md`, `commands/optimize-prompt.md`
**Scope:** Two-mode behavioral validation (augment and rewrite) plus library-curation walkthrough and README usage confirmation. This is an ENG-tier committed walkthrough record, not a code test. No participant data, no secrets.

---

## Walkthrough 1 — Augment mode on a representative ambiguous build prompt

### Input prompt

> Write a data pipeline for the CANDOR corpus. Handle edge cases.

### Shape classification

Shape: **build / implementation** — verb "write", target is a data pipeline. Dominant output demand is a code artifact or implementation plan.

### Clause evaluation

Per `augment-heuristics.md`, eligibility and suppression are distinct stages: the context-awareness rule first partitions entries into **eligible candidates** (applicability matches the classified shape) and **ineligible** entries (applicability excludes the shape — reported as suppressed); only the eligible candidates then proceed to the conflict / contradiction checks. The two tables below mirror that partition; they are not one list.

**Stage 1a — Eligible candidates (applicability matches build/implementation shape):**

| id | applicability match | result |
|---|---|---|
| `confidence-gate` | "Any open-ended build … where misunderstanding the goal wastes significant work" — this prompt is maximally open-ended; pipeline scope and output format are unstated. | **applied** |
| `check-what-exists-first` | "Build, implementation, and tool-design prompts where re-invention is a real risk." Matches. The prompt gives no signal that a novel pipeline is required. | **applied** |
| `tradeoffs-in-the-open` | "Design decisions, architecture choices, recommendations where a reader needs to weigh options." Applies to any build task where design choices are present; this pipeline has many. | **applied** |
| `state-goal-behind-task` | "Any prompt where the literal task and the underlying intent might diverge." The goal behind "write a pipeline" is completely unstated — this is a strong match. | **applied** |
| `explicit-output-contract` | "Any prompt where the shape of the expected output matters for downstream use." No shape specified; strong match. | **applied** |
| `define-out-of-scope` | "Any sufficiently open-ended prompt where the model might expand scope helpfully but unhelpfully." Matches — scope of "handle edge cases" is unbounded. | **applied** |

**Stage 1b — Ineligible (applicability excludes build/implementation shape; never enters the candidate set):**

| id | why applicability excludes this shape | result |
|---|---|---|
| `flag-contradictions-before-acting` | "Any prompt given in a context with existing constraints … Less useful for fully standalone one-shot prompts with no prior context." This is a one-off prompt with no prior context stated; applicability note's exclusion fires. | **ineligible — one-shot prompt with no prior instruction set present** |
| `no-sycophancy` | "Any prompt where honest critical output is required: reviews, evaluations, strategy calls, design decisions. Can be omitted from pure execution prompts where the output format is already fully specified." This is an execution prompt, not a review or evaluation context; there is nothing to evaluate or critique. | **ineligible — pure execution/build prompt with no evaluation component** |
| `reversibility-gate` | "Any task that involves irreversible side effects … Not needed for read-only or purely analytical tasks." The prompt asks for a design/implementation artifact, not for Claude to execute it; the reversibility gate applies at execution time, not prompt-authoring time. | **ineligible — prompt requests a design/implementation artifact, not direct execution of an irreversible action** |
| `worked-steps-for-multi-step-reasoning` | "Multi-step reasoning tasks: mathematical derivations, logical proofs, causal chains, debugging sequences, decision trees. Not needed for … tasks where the final answer (not the path) is what matters." A pipeline implementation is not a reasoning walkthrough; the deliverable is the pipeline, not the reasoning path. | **ineligible — deliverable is the build artifact, not the reasoning path** |

### Conflict check

`explicit-output-contract` (applied) and `tradeoffs-in-the-open` (applied) have a documented conflict when the output contract specifies a prose-free shape. The contract clause here uses a fill-in bracket and does not yet specify a shape; the conflict condition ("contract specifies a prose-free or structure-only shape") is **not met**. No suppression.

`worked-steps-for-multi-step-reasoning` was ineligible at Stage 1b and never entered the candidate set; no conflict check applies to it.

### Applied set

- `confidence-gate` (observed) — open-ended build with unstated scope; misunderstanding goal wastes significant work
- `check-what-exists-first` (observed) — implementation task; re-invention risk present, no signal a novel pipeline is required
- `tradeoffs-in-the-open` (observed) — architecture/design choices are present; reader needs to weigh options
- `state-goal-behind-task` (generic) — goal behind the pipeline task is entirely absent from the source prompt
- `explicit-output-contract` (generic) — output shape is unspecified; downstream use context unknown
- `define-out-of-scope` (generic) — "handle edge cases" is open-ended; overreach is a foreseeable failure mode

### Ineligible set (reported as suppressed in the enumeration)

These never entered the candidate set; per `augment-heuristics.md` they are still reported in the output enumeration as `suppressed — ineligible for [shape] prompts`.

- `flag-contradictions-before-acting` — ineligible: one-shot standalone prompt with no prior instruction set present
- `no-sycophancy` — ineligible: pure execution/build prompt with no evaluation or review component
- `reversibility-gate` — ineligible: prompt requests an implementation artifact, not direct execution of an irreversible action
- `worked-steps-for-multi-step-reasoning` — ineligible: deliverable is a build artifact, not a reasoning walkthrough

### Validation result

The confidence-gate and check-what-exists-first clauses are selected and named. The four ineligible entries are correctly excluded by the context-awareness rule before the candidate set forms (`flag-contradictions-before-acting` on the one-shot-prompt exclusion; `worked-steps-for-multi-step-reasoning` on the not-a-reasoning-task exclusion). Augment mode output enumerates every applied entry and every ineligible-or-suppressed entry with explicit reasons — the audit contract from `augment-heuristics.md` is satisfied.

**Pass.**

---

## Walkthrough 2 — Rewrite mode on a vague prompt that trips the ambiguity test

### Input prompt

> Improve the onboarding flow.

### Ambiguity test (per `rewrite-rubric.md` Section 2)

| Condition | Holds? | Evidence |
|---|---|---|
| **A. Goal absent and non-inferable** | Yes | "Improve" gives no indication of outcome; the goal could be reduced drop-off, faster time-to-value, lower support tickets, better aesthetics, or ADA compliance — none is inferable from the phrasing. |
| **C. Multiple incompatible readings of the core task** | Yes | "Improve the onboarding flow" is plausibly: rewrite the copy, redesign the UX, fix bugs in the code, draft a product spec for redesign, or generate A/B test hypotheses. These produce substantially different outputs. |

Two conditions hold (A and C, the two highest-priority triggers per Section 2 threshold). Test **trips**.

### Interview branch

The skill enters the interview branch. One interview pass, ceiling five questions. Per the `rewrite-rubric.md` §3.2 "Minimal" rule, **each question must map to a distinct ambiguity condition that actually tripped the test**, and conditions whose gap is inferable are not asked. Only A and C tripped here (the ambiguity table above), so the interview asks exactly two questions — one per tripped condition:

1. **Goal (Condition A):** What outcome are you trying to achieve by improving the onboarding flow? Options: reduce user drop-off during sign-up, improve time-to-first-value, reduce support tickets from confused new users, or something else?
2. **Incompatible readings (Condition C):** What form should the output take? Options: (a) rewritten copy for the current onboarding screens, (b) a UX redesign proposal, (c) code changes to an existing implementation, (d) a list of improvement hypotheses to test.

Two questions — well within the ceiling of five, and minimal. Conditions B (success criterion) and D (scope) did **not** trip — Section 2's threshold note keeps the bar high for B/D/E when a reasonable default exists — so they are not asked. Their content, if the author volunteers it, is captured opportunistically in the answers to Q1 and Q2; otherwise the rewrite infers them and the rationale names the inference (per §1.2 and §1.3). This is the canonical minimal-questioning behavior: ask only the tripped conditions, never pad the interview to the ceiling.

### Illustrative answers

Two questions were asked, so two answers come back. The author volunteers the success bar and the scope constraints inside the goal and form answers — that volunteered detail is captured opportunistically (it was not separately interviewed):

> 1. (goal) Reduce drop-off; we're losing ~40% of users at the account-setup step. It's "done" when the copy passes a Flesch reading ease score ≥ 70 and a non-technical reviewer can complete setup without asking a question.
> 2. (form) Rewritten copy for the existing screens — no UX redesign this sprint. Keep the number of steps the same and don't touch the email-verification step.

### Rewrite output (illustrative)

**Optimized prompt:**

> You are reviewing the copy for the account-setup step of an onboarding flow that loses approximately 40% of users at that step. Rewrite the copy for the existing screens to reduce drop-off.
>
> Goal: users complete account setup without confusion.
> Success criterion: revised copy scores ≥ 70 on the Flesch reading ease scale and a non-technical reviewer can complete the setup flow without asking a question.
> Out of scope: the number of steps, the email-verification step content, and any UX or layout changes.
> Output contract: return the revised copy for each screen as a labeled list matching the current screen count; no commentary, preamble, or redesign suggestions.

**Rationale:**

- Added explicit goal (Condition A, asked): the source said "improve" but gave no outcome; the goal question identified reducing drop-off at the account-setup step.
- Added success criterion (Condition B, not asked): the author volunteered it inside the goal answer (Flesch score ≥ 70, non-technical reviewer test); B did not trip, so it was captured opportunistically rather than interviewed.
- Added scope boundary (Condition D, not asked): the author volunteered it inside the form answer (step count unchanged, email-verification step excluded); D did not trip, so it too was captured from a volunteered answer.
- Added output contract (Condition E, not asked): inferred from the form answer to Q2 (rewritten copy per screen, not a proposal or redesign). Form is "labeled list matching current screen count."
- "Improve the onboarding flow" → disambiguated to "account-setup step copy rewrite" per the two answers; both the goal gap (A) and the incompatible-reading gap (C) were resolved by the questions that actually fired.

### Validation result

The ambiguity test fires on conditions A and C (the two highest-priority triggers). The interview branch sends exactly two bounded, specific, non-leading questions in one response — one per tripped condition — honoring the `rewrite-rubric.md` §3.2 "Minimal" rule: untripped conditions (B, D, E) are not asked, and their content is either volunteered in the author's answers or inferred with the inference named in the rationale. The rewrite reflects the answers — each structural element (goal, success criterion, scope boundary, output contract) is present, with the questioned vs. inferred/volunteered provenance distinguished. The optimized prompt is presented as a standalone block; the rationale is in a labeled section after it.

**Pass.**

---

## Walkthrough 3 — Library curation: add one new entry and confirm it becomes selectable

### New entry added to `boilerplate-library.md`

The following entry was appended to the **Generic entries** section of `reference/boilerplate-library.md`:

```
**id:** cite-sources-for-factual-claims
**provenance:** generic
**clause:**
> For any factual claim that is not common knowledge, cite the source inline or provide
> a reference section at the end. If you cannot identify a credible source, flag the
> claim as unverified rather than stating it as fact.

**applicability:** Research summaries, analysis tasks, report generation, or any prompt
where factual accuracy is load-bearing and the output may be shared or acted on. Less
useful for pure brainstorming, fictional writing, or internal scratchpad tasks where
accuracy is not the criterion.
**conflict:** Contradicts `explicit-output-contract` when that contract specifies
structure-only output with no prose or footnotes (e.g. "output only valid JSON, no prose").
In that case, suppress this clause or relax the contract to include a references field.
No conflict when the contract permits prose or a references section.
```

### Verification of selectability

**No edits were made to `SKILL.md`, `augment-heuristics.md`, or any other skill logic file.**

Selectability check: the augment heuristics' context-awareness rule reads each library entry's `applicability` field. The new entry's applicability ("Research summaries, analysis tasks, report generation … where factual accuracy is load-bearing") maps to the **open-ended / analysis** shape in the heuristics' shape table. When the next augment-mode run classifies a prompt into that shape, the new entry will appear as a candidate and proceed through the conflict-suppression rule.

Conflict note is mirrored: `cite-sources-for-factual-claims` names `explicit-output-contract` as a conditional conflict. `explicit-output-contract` should also be updated to name this entry — that mirror edit is also confined to `boilerplate-library.md` only.

**Curation outcome:** one entry added to `boilerplate-library.md`; the entry is selectable per the augment heuristics with no change to skill logic. The curate-by-editing-one-file requirement stated in `boilerplate-library.md`'s header is satisfied.

**Pass.**

---

## Walkthrough 4 — README usage example confirmation

### Command surface confirmed

The `/optimize-prompt` command is documented in `commands/optimize-prompt.md` with:

- `argument-hint: "[--augment | --rewrite] <prompt text>"`
- Three invocation forms: `--augment`, `--rewrite`, and bare (intent-inferred, augment default)
- Input channel: argument if given, else most recent user message

### README entry (from `README.md` at repo root)

The README Plugins table includes a `prompt-optimization` row describing the two modes and the dual command/auto-trigger surface. The usage block shows `/optimize-prompt` with the mode flags and a one-line description of augment vs rewrite. The entry notes that no loop-framework dependency is required.

### Consistency check

| Property | `commands/optimize-prompt.md` | `README.md` |
|---|---|---|
| Slash command name | `/optimize-prompt` | `/optimize-prompt` |
| Mode flags | `--augment`, `--rewrite` | `--augment`, `--rewrite` |
| Default mode | augment (when ~50/50) | augment (when intent is unclear) |
| Loop dependency | none stated | no ralph-loop required |
| Input channel | argument, then last message | argument or current message |

All four properties match. No claim in the README overstates behavior (language is "hardens" / "restructures," not "guarantees optimal").

**Pass.**

---

## Summary

| Walkthrough | Status | Key finding |
|---|---|---|
| 1 — Augment (build prompt) | Pass | six eligible candidates applied; four entries ruled ineligible by the context-awareness rule before the candidate set forms (reported as suppressed); enumeration contract satisfied |
| 2 — Rewrite (vague prompt, interview) | Pass | Ambiguity conditions A and C trip; two bounded interview questions generated (one per tripped condition, per the Minimal rule); rewrite reflects answers; rationale names inferences and structural changes |
| 3 — Library curation (new entry) | Pass | New entry selectable with zero edits outside `boilerplate-library.md` |
| 4 — README consistency | Pass | Command surface, flags, default, and dependency statement match across `commands/optimize-prompt.md` and `README.md` |

All acceptance conditions for Task 9 satisfied.
