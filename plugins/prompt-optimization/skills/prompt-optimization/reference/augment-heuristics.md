# Augment Mode Selection Heuristics

Single source for how augment mode decides which library entries to apply to a given prompt.
Clause text and all entry metadata (applicability, conflict, provenance) live in
[`boilerplate-library.md`](./boilerplate-library.md) — this file contains no clause text of
its own and must never duplicate it. When the two files diverge, `boilerplate-library.md` wins.

---

## What augment mode does

Augment mode leaves the original prompt's wording intact and appends a labelled block of
hardening clauses drawn from the library. The output is:

1. The original prompt, unchanged.
2. A clearly labelled append-block — e.g. `## Augmentation` or `---\n<!-- augmented by
   prompt-optimization -->` — listing the clauses selected.
3. An enumeration of what was added and why (see [Output contract](#output-contract)).

Augment mode does **not** restructure, rephrase, or rewrite the original. That is rewrite
mode's responsibility.

---

## Prompt shape classification

Before selecting clauses, classify the prompt into one of the following shapes. The shape
governs which `applicability` notes are relevant.

| Shape | Identifying signals |
|---|---|
| **build / implementation** | "write", "create", "implement", "build", "add", "refactor", "fix", "migrate" + a codebase or artifact target |
| **question / lookup** | Single interrogative; expects a factual or definitional answer; no artifact produced |
| **review / evaluation** | "review", "evaluate", "audit", "assess", "check" + a thing to be reviewed |
| **decision / recommendation** | "should I", "recommend", "which", "compare", "advise" — expects a course of action |
| **open-ended / analysis** | Multi-part, exploratory, or research prompts that don't fit the above — the output shape is prose or structured findings |

A prompt may span two shapes (e.g. a build prompt that starts with a question). In that case,
classify by the **dominant output demand**: what is the primary artifact or answer the model
is expected to produce? If two shapes are genuinely equal weight, treat both as active when
evaluating applicability.

---

## Context-awareness rule

**A clause whose applicability note does not match the classified prompt shape is not applied.**

Procedure:

1. Classify the prompt shape (table above).
2. For each library entry, read its `applicability` note.
3. If the applicability note explicitly names the classified shape as applicable, or is broad
   enough to cover it (e.g. "any open-ended build, analysis, or decision task"), the clause
   is a **candidate**.
4. If the applicability note explicitly excludes the classified shape (e.g. "not applicable to
   pure factual questions"), the clause is **ineligible** and must not be applied, regardless
   of other signals.
5. When the note is silent on the shape, use judgment: does the clause serve the dominant
   output demand? If yes, treat as a candidate; if no, treat as ineligible.

**Example:** `check-what-exists-first` (applicability: "build, implementation, and tool-design
prompts ... Not applicable to pure factual questions, pure review tasks, or prompts that already
specify a novel implementation is required") is ineligible on a question-shape prompt and on a
review-shape prompt. It is ineligible on a build prompt that already says "write a new X from
scratch without referencing existing code."

Eligibility is evaluated independently for each entry. No eligible clause inherits ineligibility
from another clause.

---

## Conflict-suppression rule

When a candidate clause would conflict with another candidate or with an instruction already
present in the original prompt, the clause is **suppressed** rather than stacked. Suppression
is always reportable (see [Output contract](#output-contract)).

### Source 1 — Library conflict notes

Each library entry carries a `conflict` field naming any other entry by id and the condition
under which they collide. The conflict check is **symmetric**: if entry A names B in its
conflict note, and entry B also names A (as required by the library's mirroring convention),
suppression fires whichever direction the evaluator encounters first.

Procedure:

1. Collect the candidate set (entries that passed the context-awareness rule).
2. For each pair of candidates, check whether either entry's `conflict` note names the other.
3. If a conflict note fires:
   - Apply the condition stated in the note (conflicts are often conditional — e.g. "only when
     the output contract specifies prose-free shape"). If the condition is not met, no conflict.
   - If the condition is met, **suppress the entry the note directs you to suppress.** The
     library is the single source for the resolution (see the header: when the two files
     diverge, `boilerplate-library.md` wins), so honour the note's own instruction rather than
     imposing an external priority. In the seed library both mirrored notes for the one real
     cross-tier collision — `tradeoffs-in-the-open` (observed) vs `explicit-output-contract`
     (generic) under a prose-free contract — name the *prose-demanding* clause as the one to
     suppress (keeping the output contract intact, or widening it), so that is the resolution:
     suppress `tradeoffs-in-the-open`, not the contract. Provenance does **not** override the
     note; an `observed` clause is suppressed when the note says so.
   - Only when a note states the conflict but does not name which side to drop, fall back to:
     higher specificity (narrower applicability) outranks lower; when still tied, suppress the
     entry that was evaluated second.

### Source 2 — Contradiction with the original prompt

A candidate clause is also suppressed if applying it would directly contradict an instruction
already present in the original prompt.

What counts as a contradiction:

- The original prompt's instruction and the candidate clause give **incompatible commands**
  to the model — following one makes it impossible to follow the other.
- Examples:
  - Original says "do not ask clarifying questions; proceed with best guess." Adding
    `confidence-gate` (which instructs the model to ask targeted questions) contradicts this.
  - Original says "output only valid JSON, no prose." Adding `worked-steps-for-multi-step-reasoning`
    (which requires shown reasoning) contradicts the output contract.
- A clause that is merely **redundant** (the original already says the same thing) is suppressed
  as redundant, not as a conflict. Report it separately in the enumeration as "already present."

Procedure:

1. For each candidate, read the clause text in `boilerplate-library.md`.
2. Identify any instruction in the original prompt that the clause text would contradict.
3. If a contradiction exists, suppress the clause and mark it as "suppressed — contradicts
   prompt instruction at [brief location or quote]."

### No silent suppression

Every suppressed clause must appear in the output enumeration with the suppression reason. The
user can then decide whether to adjust the original prompt or request the clause anyway.

---

## Output contract

Every augment-mode response must include, after the labelled append-block:

### Applied clauses

For each applied clause, one line of:

```
- [<id>] (<provenance>) — <one-line applicability match reason>
```

Example:

```
- [confidence-gate] (observed) — build prompt with open-ended scope; misunderstanding goal
  would waste significant work.
- [check-what-exists-first] (observed) — implementation task; re-invention risk present.
```

### Suppressed clauses (if any)

For each suppressed clause, one line of:

```
- [<id>] suppressed — <reason: conflict with [other-id] / contradicts prompt instruction
  "[brief quote or location]" / already present in original / ineligible for [shape] prompts>
```

Example:

```
- [worked-steps-for-multi-step-reasoning] suppressed — contradicts prompt instruction
  "output only valid JSON, no prose" (Source 2: the original prompt already forbids the
  shown reasoning this clause would add).
- [tradeoffs-in-the-open] suppressed — ineligible for question-shape prompts.
```

### Audit signal

The enumeration is not optional. Its purpose is to let the user verify:

1. Which library entries were selected and on what grounds (applicability match).
2. Which entries were considered and rejected and why (suppression reason).
3. The provenance of each applied clause (`observed` vs `generic`), so the user knows whether
   the clause encodes a Watson-specific habit or a generic best-practice.

A user who disagrees with a selection or suppression can adjust the original prompt and re-run
augment, or switch to rewrite mode for a full restructure.

---

## Interaction with mode selection

Augment heuristics are consulted **only after the mode has been selected** — either by an
explicit `--augment` flag or by the SKILL.md mode-selection contract. This file does not govern
mode selection; that is SKILL.md's responsibility. When intent is genuinely ambiguous (~50/50),
the default is augment — that decision is documented in SKILL.md and is not re-stated here.

The heuristics are also independent of the interview. Augment mode does not conduct a
clarifying-question interview; the user may supply a flag or their current prompt and augment
runs. If the prompt is so under-specified that no library entry is applicable, the response
states that and suggests rewrite mode instead.

---

## Quick-reference decision flow

```
1. Classify prompt shape
         |
         v
2. For each library entry:
   applicability matches shape? --> YES --> candidate
                                --> NO  --> ineligible (report as suppressed)
         |
         v (candidate set)
3. For each candidate pair:
   conflict note fires AND condition met? --> suppress the entry the note names (report)
         |
         v (surviving candidates)
4. For each survivor:
   contradicts an original-prompt instruction? --> suppress (report)
         |
         v (applied set)
5. Append clauses from boilerplate-library.md (clause text only)
6. Output: original prompt + labelled append-block + enumeration
```

Clause text is always taken verbatim from `boilerplate-library.md`. Do not rephrase or
paraphrase clauses in the append-block; the verbatim text is what the library guarantees.
