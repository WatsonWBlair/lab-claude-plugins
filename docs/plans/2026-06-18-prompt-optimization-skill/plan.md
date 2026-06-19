# Prompt Optimization Skill — implementation plan

**Goal:** Ship a `prompt-optimization` plugin to the `lab-claude-plugins` marketplace: one skill, two modes (augment / rewrite), exposed as both `/optimize-prompt` and an auto-triggering skill, backed by a curatable boilerplate library.

**Spec:** [prd.md](./prd.md)

**Plan format note (lab-os convention):** tasks specify *what* the implementation must satisfy, not *how*. No literal code, no test code, no TDD walkthroughs. The only code blocks allowed are short shell commands in **Verification** lines.

**Path note:** paths below are repo-relative to the plugin root `plugins/prompt-optimization/` inside `lab-claude-plugins`, except `marketplace.json` and `README.md` which are repo-root. The packet is staged at `Development\_packets\lab-claude-plugins\prompt-optimization-skill\`; an implementing agent either authors in-place under the cloned `lab-claude-plugins` repo or copies the staged artifacts in. Verification commands are written to run from the plugin root (`plugins/prompt-optimization/`) unless noted, and use POSIX tools available under Git Bash on Windows.

---

## Execution profile

7 yes · 2 partial · 0 no (of 9 tasks)

Partial / no tasks (bounded human step):
- Task 7 (partial) — Watson reviews the public-marketplace registration before it goes live (PRD constraint: review before registering in the public `marketplace.json`).
- Task 8 (partial) — Watson reviews the user-facing public-tier README copy before publication (PRD public-tier doc bar).

Parallelism (from the Depends-on DAG):
- **Wave 1 (concurrent):** Task 1 and Task 3 — both have no dependencies; run in parallel.
- **Then serial:** Task 2 (needs 1) → Task 4 (needs 1, 2, 3) → Task 5 → Task 6 → Task 7 → Task 8 (linear chain 5→6→7→8) → Task 9 (needs 1–8).
- Only fan-out is the {1, 3} first wave; the rest of the graph is a single chain. A dynamic-workflow runner should launch 1 and 3 together, then serialize the remainder. The two `partial` checkpoints (7, 8) gate continuation: Task 8 waits on Task 7's review, and Task 9 waits on Task 8.

---

## Phase 1 — Library + reference foundation

### Task 1: Author the boilerplate library catalogue

**Files:**
- Create: `skills/prompt-optimization/reference/boilerplate-library.md`

**Depends on:** —
**Agent-suitable:** yes

**Spec:** [Scope → In scope](./prd.md#in-scope), [Success criteria](./prd.md#success-criteria)

Context: this catalogue is the single source for both the augment clauses and the curate-by-editing-one-file requirement; every clause the skill can apply lives here and nowhere else.

**Acceptance:**
- Each entry carries: a stable id, the clause text (the actual boilerplate inserted), a provenance tag of either `observed` (mined from Watson's global `CLAUDE.md`) or `generic` (prompt-engineering best-practice), an applicability note (what kind of prompt it fits), and a conflict note (what it must not be stacked with).
- The `observed` set covers, at minimum, the named Watson habits: confidence-gate (interview below ~90% confidence up to >95%), check-what-exists-first, tradeoffs-in-the-open, flag-contradictions-before-acting, no-sycophancy/pushback, reversibility-gate-before-destructive-ops.
- The `generic` set covers a baseline of model-agnostic best-practices distinct from the observed set (e.g. state the goal behind the task, give an explicit output contract, define out-of-scope, request worked steps for multi-step reasoning) — none duplicating an `observed` entry's intent.
- The file is structured so a curator can add or retire one entry by editing only this file; the entry schema is stated at the top so additions stay uniform.
- No entry references a Claude/Anthropic model id or version (the library is provider-stable per scope).

**Verification:**
```shell
test -f skills/prompt-optimization/reference/boilerplate-library.md && grep -qiE 'provenance|observed|generic' skills/prompt-optimization/reference/boilerplate-library.md && grep -qiE 'confidence|tradeoff|contradiction|sycophan|revers|exists' skills/prompt-optimization/reference/boilerplate-library.md && echo OK
```

**Commit:** `feat(prompt-optimization): seed curatable boilerplate library`

---

### Task 2: Author the augment-mode selection heuristics

**Files:**
- Create: `skills/prompt-optimization/reference/augment-heuristics.md`

**Depends on:** 1
**Agent-suitable:** yes

**Spec:** [Scope → In scope](./prd.md#in-scope), [Success criteria](./prd.md#success-criteria)

**Acceptance:**
- Documents how augment mode chooses which library entries to apply to a given prompt — keyed off the prompt's shape (build/implementation vs question vs review vs open-ended) and its existing instructions.
- States the context-awareness rule: a clause whose applicability note does not match the prompt's shape is not applied (e.g. no check-what-exists-first on a pure factual question).
- States the conflict-suppression rule: when two candidate clauses carry conflicting conflict-notes, or a clause would contradict an instruction already in the prompt, the clause is suppressed rather than stacked — and the suppression is reportable.
- Names `boilerplate-library.md` as its single source for clause text and metadata; contains no clause text of its own (links, does not duplicate).
- Specifies that augment output must enumerate which entries were applied and why (provenance + applicability match), so the user can audit the change.

**Verification:**
```shell
test -f skills/prompt-optimization/reference/augment-heuristics.md && grep -qiE 'boilerplate-library' skills/prompt-optimization/reference/augment-heuristics.md && grep -qiE 'conflict|suppress|contradict' skills/prompt-optimization/reference/augment-heuristics.md && echo OK
```

**Commit:** `feat(prompt-optimization): add augment selection heuristics`

---

### Task 3: Author the rewrite rubric and ambiguity-interview trigger

**Files:**
- Create: `skills/prompt-optimization/reference/rewrite-rubric.md`

**Depends on:** —
**Agent-suitable:** yes

**Spec:** [Success criteria](./prd.md#success-criteria), [Scope → Out of scope](./prd.md#out-of-scope)

**Acceptance:**
- Defines what an AI-optimal rewritten prompt must contain: explicit goal/intent behind the ask, a success criterion, a scope boundary (what's out), and an output contract (shape of the expected answer).
- Defines the ambiguity test: the concrete conditions under which the source prompt cannot be rewritten without guessing intent (e.g. missing goal, undefined success, multiple incompatible readings).
- Specifies the interview branch: when the ambiguity test trips, the mode asks bounded, specific clarifying questions rather than inventing intent; states the interview is normal conversational turn-taking, not an autonomous re-feed loop.
- Specifies the terminal behavior when the interview ceiling is reached: proceed with explicitly-stated assumptions, or hand back "too ambiguous — here is what I'd need," per the working assumption in [Open questions](./prd.md#open-questions) (interview ceiling — small bounded set, then proceed-with-assumptions; confirm at Phase 2 review before merge).
- Requires the rewrite output to include both the optimized prompt and a short rationale for the structural changes made.

**Verification:**
```shell
test -f skills/prompt-optimization/reference/rewrite-rubric.md && grep -qiE 'goal|success criterion|out of scope|output contract' skills/prompt-optimization/reference/rewrite-rubric.md && grep -qiE 'ambigu|interview|clarif' skills/prompt-optimization/reference/rewrite-rubric.md && echo OK
```

**Commit:** `feat(prompt-optimization): add rewrite rubric and interview trigger`

---

## Phase 2 — Skill definition

### Task 4: Author SKILL.md with mode selection and both procedures

**Files:**
- Create: `skills/prompt-optimization/SKILL.md`

**Depends on:** 1, 2, 3
**Agent-suitable:** yes

**Spec:** [Success criteria](./prd.md#success-criteria), [Plan → Phase 2](./prd.md#phase-2--skill-definition-both-modes)

Context: the SKILL.md is the auto-trigger surface and the brain — it routes to a mode and tells the agent which reference to load, but holds no library content itself (single-source).

**Acceptance:**
- Frontmatter has `name: prompt-optimization` and a `description` written as trigger guidance — fires when the user asks to optimize/improve/harden/tighten a prompt, when `/optimize-prompt` is invoked, and when a user hands over a rough prompt to be made AI-ready.
- States the mode-selection contract: an explicit flag (`--augment` / `--rewrite`) wins; absent a flag, intent is inferred from the request; the chosen mode is stated back to the user before any rewriting/augmenting work proceeds.
- Augment branch instructs the agent to load `reference/augment-heuristics.md` (and through it the library), apply the context-aware selection + conflict-suppression rules, and return the original prompt plus the applied clauses with an enumeration of what was added and why.
- Rewrite branch instructs the agent to load `reference/rewrite-rubric.md`, run the ambiguity test, conduct the bounded interview when it trips, and return the optimized prompt plus a rationale.
- Contains no inline copy of library clauses or rubric content — references are linked, not duplicated (single-source per `04-docs.md`).
- States the default mode for the genuinely-ambiguous-intent case, consistent with the working assumption in [Open questions](./prd.md#open-questions) (augment-as-default — least surprising, non-destructive — unless overridden; confirm at Phase 2 review before merge).
- Documents that this skill does not depend on a loop framework — the interview is a normal turn, not a ralph re-feed.

**Verification:**
```shell
test -f skills/prompt-optimization/SKILL.md && head -10 skills/prompt-optimization/SKILL.md | grep -qE '^name:[[:space:]]*prompt-optimization' && grep -qiE 'augment-heuristics|rewrite-rubric' skills/prompt-optimization/SKILL.md && grep -qiE 'augment|rewrite' skills/prompt-optimization/SKILL.md && echo OK
```

**Commit:** `feat(prompt-optimization): author SKILL.md with two-mode router`

---

## Phase 3 — Slash command + packaging

### Task 5: Author the /optimize-prompt slash command

**Files:**
- Create: `commands/optimize-prompt.md`

**Depends on:** 4
**Agent-suitable:** yes

**Spec:** [Success criteria](./prd.md#success-criteria), [Plan → Phase 3](./prd.md#phase-3--slash-command--packaging)

**Acceptance:**
- Frontmatter has a `description` and an `argument-hint` documenting the prompt argument and the mode flags (`--augment` / `--rewrite`).
- The command body routes to the `prompt-optimization` skill (pointing at `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/SKILL.md`) and passes through `$ARGUMENTS`.
- Specifies the input channel: the prompt is taken from the command argument when given, else falls back to the most recent user message, per the working assumption in [Open questions](./prd.md#open-questions) (slash-command input channel — argument-and-fallback; confirm at Phase 3 before merge).
- `allowed-tools` is scoped to what the command actually needs (read/reasoning surface); it does not grant unused write or shell scope.
- Does not reference `ralph-loop`, a setup script, or any loop state file (this plugin has none).

**Verification:**
```shell
test -f commands/optimize-prompt.md && grep -qE '^argument-hint:' commands/optimize-prompt.md && grep -qiE 'augment|rewrite' commands/optimize-prompt.md && grep -qiE 'SKILL.md|prompt-optimization' commands/optimize-prompt.md && echo OK
```

**Commit:** `feat(prompt-optimization): add /optimize-prompt slash command`

---

### Task 6: Author plugin.json

**Files:**
- Create: `.claude-plugin/plugin.json`

**Depends on:** 4, 5
**Agent-suitable:** yes

**Spec:** [Success criteria](./prd.md#success-criteria), [Constraints](./prd.md#constraints)

**Acceptance:**
- Valid JSON with `name: prompt-optimization`, a one-line `description` naming the two modes and the dual surface, a `version`, and an `author` block consistent with the sibling `pr-review-loop` manifest (`{ "name": "Watson Blair" }`).
- Omits the `dependencies` key entirely (or, if present, contains no `ralph-loop`/loop-framework entry) — the absence is intentional and consistent with the SKILL.md, and contrasts with `pr-review-loop`, which *does* declare `ralph-loop@claude-plugins-official`.
- Parses under a JSON validator.

**Verification:**
```shell
test -f .claude-plugin/plugin.json && jq -e '.name=="prompt-optimization" and (.description|test("augment";"i")) and ((.dependencies // []) | any(test("ralph"))|not)' .claude-plugin/plugin.json && echo OK
```

**Commit:** `feat(prompt-optimization): add plugin manifest`

---

### Task 7: Register the plugin in the marketplace

**Files:**
- Modify: `.claude-plugin/marketplace.json` (repo root)

**Depends on:** 6
**Agent-suitable:** partial — Watson reviews the public-marketplace registration before it goes live (PRD constraint: "Watson reviews before the plugin is registered in the public `marketplace.json`")

**Spec:** [Success criteria](./prd.md#success-criteria), [Plan → Phase 3](./prd.md#phase-3--slash-command--packaging)

**Acceptance:**
- Adds a `prompt-optimization` object to the `plugins` array with `name`, `source: ./plugins/prompt-optimization`, a `description`, and a `version` matching `plugin.json`.
- The existing `pr-review-loop` registration is preserved unchanged.
- The file remains valid JSON and the new `source` path points at a directory that exists.

**Verification:**
```shell
jq -e '.plugins | map(.name) | index("prompt-optimization") != null and index("pr-review-loop") != null' .claude-plugin/marketplace.json && jq -e '.plugins[] | select(.name=="prompt-optimization") | .source=="./plugins/prompt-optimization"' .claude-plugin/marketplace.json && echo OK
```
<!-- Run from repo root, not the plugin root. -->

**Commit:** `feat: register prompt-optimization in marketplace`

---

### Task 8: Document install and usage in the README

**Files:**
- Modify: `README.md` (repo root)

**Depends on:** 7
**Agent-suitable:** partial — public-tier copy; Watson reviews user-facing README copy before publication (PRD Constraints: public-tier doc bar, "Watson reviews before the plugin is registered in the public `marketplace.json`")

**Spec:** [Constraints](./prd.md#constraints), [Success criteria](./prd.md#success-criteria)

Context: public-tier surface — jargon-free, no codenames, overclaim-scrubbed, single-sourced per `04-docs.md`.

**Acceptance:**
- The Plugins table gains a `prompt-optimization` row describing the two modes and the dual command/auto-trigger surface in plain language.
- A usage block shows `/optimize-prompt` with the mode flags and a one-line description of augment vs rewrite, matching the command's `argument-hint`.
- States the plugin needs no loop-framework dependency (contrast with `pr-review-loop`), so a reader doesn't assume `ralph-loop` is required.
- No claim overstates behavior (it improves/hardens prompts; it does not "guarantee optimal" anything); no internal codename leaks.

**Verification:**
```shell
grep -qE 'prompt-optimization' README.md && grep -qiE 'optimize-prompt' README.md && grep -qiE 'augment|rewrite' README.md && echo OK
```
<!-- Run from repo root. -->

**Commit:** `docs: document prompt-optimization install and usage`

---

## Phase 4 — Validation pass

### Task 9: Validate both modes and library curatability

**Files:**
- Create: `skills/prompt-optimization/reference/validation-notes.md`

**Depends on:** 1, 2, 3, 4, 5, 6, 7, 8
**Agent-suitable:** yes

**Spec:** [Plan → Phase 4](./prd.md#phase-4--validation-pass), [Success criteria](./prd.md#success-criteria)

Context: the validation note is a committed walkthrough record, not a code test — the behaviours in the PRD success criteria are the test surface, exercised by hand against the authored artifacts.

**Acceptance:**
- Records an augment walkthrough on a representative ambiguous build prompt: shows the confidence-gate and check-what-exists clauses selected and named, and at least one inapplicable clause correctly suppressed.
- Records a rewrite walkthrough on a vague prompt that trips the ambiguity test: shows the bounded interview firing and the optimized prompt reflecting the (illustrative) answers.
- Records a library-curation walkthrough: adds one new entry to `boilerplate-library.md`, confirms it becomes selectable per the augment heuristics with no edit to `SKILL.md` or the heuristics file.
- Confirms the README usage example matches the observed command behaviour.
- Note is written as an ENG-tier record (skimmable, names the artifacts exercised); contains no participant data or secrets.

**Verification:**
```shell
test -f skills/prompt-optimization/reference/validation-notes.md && grep -qiE 'augment|rewrite' skills/prompt-optimization/reference/validation-notes.md && grep -qiE 'curat|new entry|selectable' skills/prompt-optimization/reference/validation-notes.md && echo OK
```

**Commit:** `report(prompt-optimization): record two-mode validation walkthrough`

---

## Execution Log

<!-- Altitude: plan-execution (see .claude/rules/03-logging.md §altitudes).
     Deviations from the plan, implementation-altitude calls, gate evidence.
     Load-bearing decisions → project_log.md. Status → PR comment. Narrative → PR body.
     Closes when the shipping PR merges; post-merge evidence → comment on that PR.

     Entry grammar (one line each):
     YYYY-MM-DD HH:MM · task N · <what happened / why / output> -->

<!-- entries below — newest at top -->

2026-06-19 03:17 · tasks 1-9 · Built via dynamic Workflow (22 agents; per task: author → consolidated outsider review (spec then quality) → source-validated remediation; controller owned all 9 commits). Wave-1 {T1,T3} parallel, rest serial. All 9 verification gates green via Git Bash, unpiped. Review caught + fixed real cross-file issues: T1 conflict notes were all `none` → encoded conditional, mutually-mirrored prose-vs-structured-contract conflicts (left genuinely-conflict-free entries alone — no invented rule); T2 heuristics tie-break resolved the one cross-tier conflict opposite to the library note → realigned so the library note wins + fixed a mislabeled suppression example; T9 interview walkthrough over-asked untripped conditions → cut to the two tripped questions + split candidate/ineligible tables. Controller post-pass (context the agents lacked): overclaim scrub `AI-optimal`→`AI-ready` on user-facing surfaces (plugin.json, marketplace.json, /optimize-prompt, SKILL.md, rewrite-rubric §1) to honor Task 8's "does not guarantee optimal anything" bar; README no-arg copy aligned to "most recent user message". All gate-safe.

2026-06-19 03:17 · design-lock · Watson approved the four prompt-optimization design defaults — augment-as-default · labelled append-block output · five-question interview ceiling then proceed-with-assumptions · argument-and-fallback input — at the overnight run's launch checkpoint. This is the Phase-2/3 confirmation that Tasks 3-5 acceptance + PRD §Open questions deferred to a human gate. Artifacts encode them as confirmed; PRD open questions 1-3 + 5 marked resolved; rewrite-rubric §3.3 flipped from "pending Phase-2" to confirmed.
