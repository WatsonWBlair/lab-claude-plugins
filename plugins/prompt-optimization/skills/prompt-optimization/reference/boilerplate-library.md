# Boilerplate Library Catalogue

Single source for every hardening clause the `prompt-optimization` skill can apply. A curator
adds, edits, or retires an entry by editing **only this file** — no change to `SKILL.md`,
`augment-heuristics.md`, or any other skill logic is required.

---

## Entry schema

Every entry must carry all five fields below. Do not add fields; do not omit fields.

```
**id:** <kebab-case stable identifier — never reuse a retired id>
**provenance:** observed | generic
**clause:**
> <the exact text inserted into or appended to the prompt>
**applicability:** <what prompt shapes / contexts this clause fits>
**conflict:** <what it must not be stacked with, or "none">
```

- `observed` — mined from Watson's global `CLAUDE.md`; reflects habits already baked into
  his sessions and most likely to be missing from one-off or exported prompts.
- `generic` — model-agnostic prompt-engineering best-practice; does not duplicate an
  `observed` entry's intent.
- Clause text is quoted verbatim when applied; write it as an imperative instruction directed
  at the model, unless it is framing (in which case it can be a statement).
- Applicability and conflict notes are curator-read; they are also what `augment-heuristics.md`
  uses for context-aware selection and conflict suppression.
- The `conflict:` field is load-bearing, not decorative. `none` is a positive assertion — this
  clause has been checked against the rest of the library and stacks cleanly with all of it.
  When a conflict exists, name the other entry by `id` and the condition under which they
  collide; conflicts are often **conditional** (only when a third constraint is present, e.g.
  a strict output shape) and **directional notes are mirrored** — if A conflicts with B, B's
  entry names A too, so the suppression rule sees it from whichever clause it evaluates first.

---

## Observed entries

Mined from Watson's global `CLAUDE.md` — these encode habits that fire reliably only when
the global rules cascade is loaded. When a prompt will be used outside that context (one-off
briefs, subagent handoffs, prompts for other lab members), these clauses restore the intent.

---

**id:** confidence-gate
**provenance:** observed
**clause:**
> Before acting, assess your confidence in your understanding of this task. If you are below
> ~90% confident that you have correctly understood the goal and constraints, ask targeted
> clarifying questions until you reach >95% confidence. Do not invent assumptions silently;
> state any assumptions you are making explicitly.

**applicability:** Any open-ended build, analysis, or decision task where misunderstanding
the goal wastes significant work. Most useful on implementation asks, review requests, and
multi-step plans. Less useful on narrow factual lookups.
**conflict:** none

---

**id:** check-what-exists-first
**provenance:** observed
**clause:**
> Before proposing or building a new solution, search the relevant codebase, repo history, and
> installed tooling for existing work that addresses the same need. If something close-enough
> exists, propose extending it rather than building from scratch; name what you found and why
> it does or does not meet the need.

**applicability:** Build, implementation, and tool-design prompts where re-invention is a
real risk. Not applicable to pure factual questions, pure review tasks, or prompts that
already specify a novel implementation is required.
**conflict:** none

---

**id:** tradeoffs-in-the-open
**provenance:** observed
**clause:**
> For every recommendation or design choice, state the tradeoffs explicitly: what this
> approach costs, what alternatives were considered, and what is foreclosed by choosing it.
> Do not bury the tradeoff in a caveat at the end — surface it alongside the recommendation.

**applicability:** Design decisions, architecture choices, recommendations where a reader
needs to weigh options. Less useful on pure lookup or pure execution tasks.
**conflict:** Contradicts `explicit-output-contract` when that contract specifies a prose-free
or structure-only output shape — surfacing tradeoffs "alongside the recommendation" requires
prose the contract forbids. Suppress this clause, or widen the contract to include a tradeoffs
field, rather than stacking both. No conflict when the contract admits prose.

---

**id:** flag-contradictions-before-acting
**provenance:** observed
**clause:**
> If any part of this request conflicts with prior decisions, existing constraints, or
> instructions already in scope (including earlier parts of this prompt), surface the
> contradiction explicitly and ask which wins before proceeding. Do not silently resolve
> ambiguity by picking one side.

**applicability:** Any prompt given in a context with existing constraints, logged decisions,
or a prior instruction set (e.g. a session with a CLAUDE.md, a project with established
conventions, a multi-turn conversation). Less useful for fully standalone one-shot prompts
with no prior context.
**conflict:** none

---

**id:** no-sycophancy
**provenance:** observed
**clause:**
> Do not open with compliments ("great question," "that's a good idea") or close with filler
> ("let me know if you need anything else"). If the request has a hole or a better path
> exists, name it — do not execute a flawed plan to be agreeable. Disagreement is load-bearing
> signal; suppress it only if it is genuinely irrelevant.

**applicability:** Any prompt where honest critical output is required: reviews, evaluations,
strategy calls, design decisions. Can be omitted from pure execution prompts where the
output format is already fully specified and there is nothing to evaluate.
**conflict:** none

---

**id:** reversibility-gate
**provenance:** observed
**clause:**
> Before performing any destructive or hard-to-reverse action (deleting files, overwriting
> data, force-pushing, sending external communications, executing financial transactions, or
> making bulk changes), show the plan, mark what is irreversible, and wait for explicit
> confirmation before proceeding. Do not treat silence as approval.

**applicability:** Any task that involves irreversible side effects: file operations, git
history changes, API calls with write effects, external communications, or bulk modifications.
Not needed for read-only or purely analytical tasks.
**conflict:** none

---

## Generic entries

Model-agnostic prompt-engineering best-practices. None duplicates the intent of an observed
entry above.

---

**id:** state-goal-behind-task
**provenance:** generic
**clause:**
> The goal behind this task is: [FILL IN]. This context matters because it determines which
> trade-offs are acceptable and what "done" looks like — optimize for the goal, not just
> literal completion of the task description.

**applicability:** Any prompt where the literal task and the underlying intent might diverge
— especially when the model might optimize for the letter of the instruction rather than
its spirit. Fill in the bracketed text before using.
**conflict:** none

---

**id:** explicit-output-contract
**provenance:** generic
**clause:**
> Output format: [FILL IN — e.g. a bulleted list, a JSON object with fields X and Y, a
> prose paragraph under 200 words, a code file with no prose commentary]. Do not include
> content not specified in this contract; do not omit required fields.

**applicability:** Any prompt where the shape of the expected output matters for downstream
use — API responses, structured documents, code generation, report generation. Less critical
for open-ended conversational prompts.
**conflict:** When the filled-in contract specifies a prose-free or structure-only shape
(e.g. "a JSON object", "a code file with no prose commentary", "output ONLY the value"), this
clause's "do not include content not specified in this contract" directly contradicts any
clause that demands additional prose in the same output: `worked-steps-for-multi-step-reasoning`
(reasoning shown before the conclusion) and `tradeoffs-in-the-open` (tradeoffs stated alongside
the answer). Suppress the prose-demanding clause, or relax the contract to admit a reasoning
field, rather than stacking both. No conflict when the contract itself permits prose (e.g. a
prose paragraph, a report).

---

**id:** define-out-of-scope
**provenance:** generic
**clause:**
> The following is explicitly out of scope for this task: [FILL IN]. Do not attempt to
> address out-of-scope items, even if they seem relevant. Flag if you believe an out-of-scope
> item must be addressed before the in-scope work can succeed.

**applicability:** Any sufficiently open-ended prompt where the model might expand scope
helpfully but unhelpfully — research, design, implementation tasks with adjacent concerns.
Fill in the bracketed text before using.
**conflict:** none

---

**id:** worked-steps-for-multi-step-reasoning
**provenance:** generic
**clause:**
> For this task, show your reasoning step by step before stating your conclusion. Do not
> compress intermediate steps into a single assertion. If a step relies on an assumption,
> name the assumption at that step rather than holding it for a later caveat.

**applicability:** Multi-step reasoning tasks: mathematical derivations, logical proofs,
causal chains, debugging sequences, decision trees. Not needed for single-step lookups or
tasks where the final answer (not the path) is what matters.
**conflict:** Contradicts `explicit-output-contract` when that contract specifies a prose-free
or structure-only output shape (JSON-only, code-only, value-only) — shown reasoning is exactly
the extra prose such a contract forbids. When both are candidates, suppress this clause or have
the contract carve out a dedicated reasoning field. No conflict with a contract that permits
prose.

---

## Retired entries

Record retired entries here rather than deleting them, so their ids are never reused.
Format: id, date retired, reason.

<!-- none yet -->
