# Prompt Optimization Skill — PRD

<!-- Living document at a stable path. Update by amendment; never archive.
     Decisions made while executing this PRD live in lab-claude-plugins project_log.md (or the
     lab log for cross-repo calls) — never embedded here. -->

**Status:** draft <!-- draft | active | paused | complete -->
**Date:** 2026-06-18 · **Repo:** lab-claude-plugins (packet staged at `Development\_packets\lab-claude-plugins\prompt-optimization-skill\`)

> **Supersedes:** the "Prompt Optimization Skill" thread in `Development\Open-Threads.md` (topic #4) and its locked-decision capture in `Development\Open-Threads-Intake.md` §P8. Those are ingested here as source-of-truth inputs; on merge of this packet's first slice, mark the Open-Threads entry as superseded (single-source per `04-docs.md`).

> **Decisions live in the project log, not here.** When a decision is reached while executing this PRD, log it per `.claude/rules/03-logging.md` entry triggers. Link from Open Questions if useful; the PRD itself stays decision-free.

---

## Problem

Watson applies a recurring set of prompt-hardening habits by hand — the confidence-gate ("if under ~90% confident, interview me up to >95% before acting"), "check what exists first," "tradeoffs in the open," "flag contradictions before acting," "no sycophancy." These live in his global `CLAUDE.md` and fire reliably only when the working agent has that file loaded. For one-off prompts, ad-hoc subagent briefs, prompts written in repos without the global rules cascade, or prompts handed to other lab members, the hardening is applied inconsistently or forgotten. The result is avoidable rework: agents charge ahead on ambiguous asks, rebuild things that already exist, or bury the tradeoff that would have changed the decision.

Separately, a raw prompt is often under-specified for an AI reader even when it is clear to the human who wrote it — missing the goal behind the ask, the success criterion, the explicit out-of-scope, or the output contract. There is currently no lab tool that takes a rough prompt and either (a) bolts on the right robustness boilerplate or (b) rewrites it into an AI-optimal brief, interviewing the author when the prompt is too ambiguous to rewrite safely.

This is a tooling gap for: **Watson primarily** (his habits, his library seed), and **lab members secondarily** (the marketplace is public; the same skill installs anywhere).

---

## Success criteria

- A single installed plugin exposes prompt optimization **both** as a slash command (`/optimize-prompt`) **and** as an auto-triggering skill, with no second install step for either surface.
- Invoking the tool on a prompt selects between two modes — **augment** (add boilerplate) and **rewrite** (full AI-optimal rewrite) — by an explicit flag when given, and by detected intent when not; the selection is stated back to the user before work proceeds.
- **Augment mode** returns the original prompt plus context-appropriate hardening clauses drawn from a named library; it does not silently add clauses that contradict the prompt's own instructions, and it names which library entries it applied and why.
- The boilerplate library is a **file-backed, human-readable catalogue** seeded from Watson's observed `CLAUDE.md` patterns unioned with generic prompt-engineering best-practices; a curator can add, edit, or retire an entry by editing one reference file, with no change to skill logic.
- **Rewrite mode** produces a restructured prompt with an explicit goal, success criterion, scope boundary, and output contract; when the source prompt is too ambiguous to rewrite without guessing, the mode **interviews** the user (bounded, specific questions) instead of inventing intent, and the rewrite reflects the answers.
- A user can tell, from the tool's output alone, what changed and why — augment names the clauses added; rewrite shows the optimized prompt and a short rationale for the structural changes.
- The plugin packages cleanly under the `lab-claude-plugins` marketplace convention (registered in `marketplace.json`; `.claude-plugin/plugin.json` + `commands/` + `skills/<name>/SKILL.md` + the skill's own `skills/<name>/reference/` catalogue present) and installs without pulling a loop-framework dependency it does not need.

---

## Scope

### In scope

- One plugin, `prompt-optimization`, added to the `lab-claude-plugins` marketplace.
- One skill with two modes (augment / rewrite); one slash command (`/optimize-prompt`) that drives the same skill.
- Mode selection: explicit flag (e.g. `--augment` / `--rewrite`) overrides; absent a flag, the skill infers intent and states its choice.
- A seed boilerplate library, file-backed and curatable, with two provenance classes: **observed** (mined from Watson's global `CLAUDE.md`) and **generic** (prompt-engineering best-practice).
- Context-awareness in augment mode: clauses are selected to fit the prompt (e.g. don't add a "check what exists first" clause to a pure-question prompt), and conflicting clauses are suppressed rather than stacked.
- Rewrite mode's ambiguity interview: a bounded clarifying-question pass when the prompt cannot be safely rewritten as-is.
- A `reference/` set: the library catalogue, the augment selection heuristics, and the rewrite rubric.
- README + marketplace registration so the plugin is installable.

### Out of scope

- Automatic mining of new patterns from live session transcripts. The seed library is hand-curated from `CLAUDE.md`; a transcript-mining harness that *proposes* new library entries is a deferred follow-up (see Open Questions), not this packet.
- Persisting or learning per-user preference profiles. The library is one shared catalogue; there is no per-user weighting in v1.
- A ralph-style autonomous re-feed loop. The rewrite interview is a normal bounded conversational turn, not a stop-hook-driven multi-cycle loop; this plugin does **not** depend on `ralph-loop`.
- Optimizing prompts for non-Claude models, or model-specific token-budget tuning.
- Editing the prompts already embedded in other lab skills/plugins. This tool optimizes a prompt handed to it; it does not crawl the repo rewriting existing prompt assets.
- Enforcing that Watson *uses* the tool (no hook that auto-rewrites every prompt). Auto-trigger means the skill is *available* to fire on intent, not that it intercepts all input.

---

## Constraints

- **Budget:** Inference runs on Claude Max via the normal Claude Code session (Max-via-subprocess posture); no direct Anthropic API spend attributable to this tool. No cloud spend. Authoring this packet is documentation work.
- **Timeline:** No hard deadline. Sequenced within the Open-Threads consolidation as packet P8; greenfield, statically planned.
- **Data / access:** No gated-dataset exposure. The library seed is mined from Watson's own `CLAUDE.md` (his content, safe to restate). No participant data, no secrets.
- **Infra:** Claude Code with plugin support. No GitHub App, no CI service dependency beyond the marketplace repo's existing checks. Cross-platform: reference files and skill logic must not assume a shell (the skill is markdown-driven; any helper script must work under Git Bash on Windows and POSIX sh).
- **Approvals:** Public marketplace repo — README and any user-facing copy fall under the public-tier doc bar (`04-docs.md`: jargon-free, no codenames, overclaim-scrubbed, single-sourced). Watson reviews before the plugin is registered in the public `marketplace.json`.
- **Dependencies:** Packaging template is the existing `plugins/pr-review-loop` plugin (structure only; this plugin does not reuse its ralph dependency). No dependency on other Open-Threads packets. P9 (Logging Automation Skill) ships to the same marketplace but is independent.

---

## Plan (phased)

High-level phases; per-task detail in [plan.md](./plan.md).

### Phase 1 — Library + reference foundation

**Goal:** Stand up the curatable boilerplate library and the two heuristic references (augment selection, rewrite rubric) as the source-of-truth the skill reads.
**Deliverables (all under `skills/prompt-optimization/reference/`):** `boilerplate-library.md` (seeded: observed ∪ generic, each entry tagged with provenance, applicability, and a conflict note), `augment-heuristics.md` (how clauses are selected and conflicts suppressed), `rewrite-rubric.md` (what an AI-optimal prompt must contain + the ambiguity-interview trigger).
**Checkpoint:** The library is internally consistent — every entry has provenance + applicability; the seed covers the named Watson habits and a baseline of generic best-practices; the references cite the library as their single source.

### Phase 2 — Skill definition (both modes)

**Goal:** Author the SKILL.md that implements mode selection, augment, and rewrite-with-interview, reading the Phase 1 references.
**Deliverables:** `skills/prompt-optimization/SKILL.md` with frontmatter trigger description (auto-trigger surface), the mode-selection contract, the augment procedure, and the rewrite procedure including the ambiguity-interview branch.
**Checkpoint:** The skill, read cold, tells an agent how to pick a mode, which reference to load for each, and how to present what changed — with no embedded library content (it links to the reference).

### Phase 3 — Slash command + packaging

**Goal:** Expose the skill as `/optimize-prompt`, register the plugin in the marketplace, and document install/usage.
**Deliverables:** `commands/optimize-prompt.md` (frontmatter: description, argument-hint with the mode flags, scoped allowed-tools), `.claude-plugin/plugin.json`, marketplace registration in the repo-root `.claude-plugin/marketplace.json`, README entry.
**Checkpoint:** A clean install from the marketplace exposes both the command and the auto-trigger skill; the command's argument-hint documents the flags; the plugin declares no `ralph-loop` dependency.

### Phase 4 — Validation pass

**Goal:** Confirm the two modes behave on representative prompts and the library is genuinely curatable.
**Deliverables:** A short validation note (in the packet, not a committed test file) walking: an augment on an ambiguous build prompt (confidence-gate + check-what-exists clauses applied, named), a rewrite on a vague prompt that triggers the interview, and a library edit (add one entry, confirm it becomes selectable with no skill-logic change).
**Checkpoint:** All three walkthroughs pass against the authored artifacts; the README usage example matches observed behavior.

---

## Open questions

> **Resolved 2026-06-19** (Watson sign-off at the overnight-run launch checkpoint; see the plan's Execution Log): mode-selection default = **augment-as-default**; augment output shape = **labelled append-block**; interview ceiling = **five questions, then proceed-with-stated-assumptions**; slash-command input = **argument-and-fallback**. The transcript-mining item stays deferred (post-Phase-4).

- [ ] **Mode-selection default when intent is genuinely 50/50** — does the skill default to augment (lighter touch, preserves author's wording) or to rewrite (stronger optimization)? Leaning augment-as-default (least surprising, non-destructive). Owner: Watson · due: Phase 2 review.
- [ ] **Augment output shape** — does augment append the clauses as a labelled block after the original prompt, or weave them inline at the relevant points? Append-block is simpler and clearer about provenance; inline reads better but obscures what was added. Owner: Watson · due: Phase 2 review.
- [ ] **Interview ceiling** — how many clarifying questions may rewrite mode ask before it either proceeds with stated assumptions or hands back "too ambiguous, here's what I'd need"? Proposed default: small bounded set, then proceed-with-assumptions. Owner: Watson · due: Phase 2 review.
- [ ] **Transcript-mining follow-up** — deferred out of scope here; file as a separate backlog item if/when the seed library proves too static. Owner: Watson · due: post-Phase 4.
- [ ] **Slash-command input channel** — does `/optimize-prompt` take the prompt as the command argument, or operate on the preceding message / a referenced file? Argument-and-fallback (argument if given, else most recent user message) is the working assumption. Owner: Watson · due: Phase 3.
