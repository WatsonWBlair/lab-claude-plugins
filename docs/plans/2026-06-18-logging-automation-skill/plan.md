# Logging Automation Skill — implementation plan

**Goal:** Ship a portable `logging-automation` plugin in the `lab-claude-plugins`
marketplace that detects loggable events per `03-logging.md`, routes them to the correct
altitude and format, auto-drafts the status/event tier, and gates load-bearing-decision
writes behind human approval — and have Mission Control's Phase 6 `log:` flow consume it.

**Spec:** [prd.md](./prd.md) (this packet has no separate design.md; the PRD carries the
problem, scope, and phased plan. The authoritative *rules* this skill automates live in
`lab-os/.claude/rules/03-logging.md` — cited per task.)

**Plan format note (lab-os convention):** tasks specify *what* the implementation must
satisfy, not *how*. No literal code, no test code, no TDD walkthroughs. The
**Acceptance** bullets are the test surface. The only code blocks are short shell
commands in **Verification** lines.

**Path convention:** all plugin files live under `plugins/logging-automation/` in the
`lab-claude-plugins` repo. Paths in **Files** blocks are repo-relative to the
lab-claude-plugins root.

**Verification preamble (run once before any task's Verification command):** the
Verification lines reference two absolute-path anchors. Export them first so each command
runs cold against the right repo (an unset var would make `cd "" && …` run in the wrong
CWD):

```shell
export LAB_CLAUDE_PLUGINS="C:/Users/watso/Development/lab-claude-plugins"
export MISSION_CONTROL="C:/Users/watso/Development/mission-control"
```

---

## Execution profile

12 yes · 0 partial · 0 no (of 12 tasks)

No partial or no tasks: every task creates or modifies markdown inside repos that
already exist (`lab-claude-plugins`, `mission-control`, with `lab-os` as the cited
source) and verifies with `grep`/`test -f`/`claude plugin validate` — no credentials,
external identity, system install, or operator-only action is required. The
human-approval *gate* that Tasks 8–10 specify is **content the reference docs describe**,
not a build-time human step; authoring and verifying those docs is fully autonomous.

**Parallelism (from the Depends-on DAG):**
- **Wave 1 (serial head):** Task 1 → Task 2. Task 1 has no deps; Task 2 depends on 1.
- **Wave 2 (fan-out — run concurrently):** Tasks 3, 4, 5 each depend only on Task 2 and
  touch disjoint new files (`reference/trigger-classification.md`, `altitude-routing.md`,
  `entry-format.md`) — safe to parallelize.
- **Wave 3+ (serial tail):** Task 6 (joins 3+4+5) → 7 → 8 → 9 → 10 → 11 → 12, a strict
  chain (each depends on the prior; Tasks 8 and 9 also modify shared files SKILL.md /
  entry-format.md, reinforcing serialization). No further fan-out.

---

## Phase A — Canonical logic + packaging skeleton

### Task 1: Scaffold the `logging-automation` plugin and register it

**Files:**
- Create: `plugins/logging-automation/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Depends on:** —
**Agent-suitable:** yes

**Spec:** [prd.md § Scope (In scope)](./prd.md#in-scope) · [prd.md § Plan — Phase 1](./prd.md#phase-1--canonical-logic--packaging-skeleton)

Context: mirror the `pr-review-loop` packaging exactly so the marketplace stays uniform — `plugin.json` shape, a `marketplace.json` plugins-array entry, a README table row.

**Acceptance:**
- `plugin.json` declares `name: logging-automation`, a `description` matching the auto-trigger intent (drafts and routes audit-trail log entries per the lab logging rules), a `version`, and `author` Watson Blair — same field shape as `plugins/pr-review-loop/.claude-plugin/plugin.json`.
- The plugin declares **no external plugin dependency** (unlike `pr-review-loop`'s `ralph-loop`) — it is self-contained.
- `marketplace.json` gains one entry in `plugins[]` with `name`, `source: ./plugins/logging-automation`, a one-line `description`, and `version`; existing entries and top-level keys are untouched.
- `README.md` gains one row in the Plugins table describing the skill, and an install line `/plugin install logging-automation@lab-claude-plugins`.
- The README row / plugin description states the skill **applies** `03-logging.md` and does not redefine it (source-of-truth relationship visible to a reader).

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && claude plugin validate ./plugins/logging-automation && python -c "import json,sys; d=json.load(open('.claude-plugin/marketplace.json')); assert any(p['name']=='logging-automation' for p in d['plugins']); print('registered')"
```

**Commit:** `feat(logging-automation): scaffold plugin and register in marketplace`

---

### Task 2: Author SKILL.md with the auto-trigger description and overview

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/SKILL.md`

**Depends on:** 1
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) · [prd.md § Problem](./prd.md#problem)

Context: the SKILL.md frontmatter `description` is the auto-trigger surface — it must fire when a session reaches a loggable moment, mirroring how `pr-review-loop`'s description triggers on review moments.

**Acceptance:**
- Frontmatter carries `name: logging-automation` and a `description` whose trigger phrasing covers: a load-bearing decision being reached mid-session, an irreversible/external event occurring (release, migration, secret rotation, org/repo change, data published), a direction change / re-scope, and an explicit `/log` invocation.
- The Overview states the skill turns a loggable moment into a correctly-routed, correctly-formatted entry, and names `lab-os/.claude/rules/03-logging.md` as the source of truth for the rules it applies.
- A "When to use / When NOT to use" pair distinguishes loggable events from the `03-logging.md` else-routes cases (bare status, plan deviation, gotcha, follow-up, preference-fact) so the host session does not over-fire.
- SKILL.md links to its bundled reference files using the `${CLAUDE_PLUGIN_ROOT}` runtime-resolved portability pattern (paths resolvable when installed in any repo). Note: this packet has **no `setup.sh`/`PROMPT.md`**, so the `@@PLUGIN_ROOT@@` sed-expanded placeholder that `pr-review-loop` carries in PROMPT.md does **not** apply here — there is no expander; use `${CLAUDE_PLUGIN_ROOT}` directly.
- A top note records that this skill **supersedes** the Open-Threads "Logging / Convention Skills / Rules" thread.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && test -f plugins/logging-automation/skills/logging-automation/SKILL.md && grep -q "03-logging.md" plugins/logging-automation/skills/logging-automation/SKILL.md && head -5 plugins/logging-automation/skills/logging-automation/SKILL.md | grep -q "description:"
```

**Commit:** `feat(logging-automation): add SKILL.md with auto-trigger description`

---

### Task 3: Author the trigger-classification reference

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/trigger-classification.md`

**Depends on:** 2
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (trigger detection) · [prd.md § Scope (In scope)](./prd.md#in-scope)

Context: this is the operational restatement of `03-logging.md` § "Entry triggers" — restate the grammar deterministically, cite the rationale, do not become a second source.

**Acceptance:**
- Enumerates the three entry triggers verbatim in intent (load-bearing decision with real alternatives; irreversible/external event; direction change / re-scope) and the disqualifying "else-routes" table (deviation → plan Execution Log; gotcha → TROUBLESHOOTING/issue; open work/follow-up → issues; bare status → PR comment; session narrative → PR body; preference-fact → auto-memory).
- Gives the host session a decision procedure that outputs exactly one verdict: **loggable** (with which trigger) or **else-route** (with which home) — never ambiguous.
- States explicitly that a bare status fact (e.g. "merged, smoke passed") is NOT a project-log entry, to prevent the observed wrong-surface failure.
- Names `lab-os/.claude/rules/03-logging.md` § Entry triggers as the owning source; the file is robust to wording changes there (cites it rather than claiming authority).

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/trigger-classification.md && test -f "$f" && grep -qi "load-bearing" "$f" && grep -qi "else-route" "$f" && grep -q "03-logging.md" "$f"
```

**Commit:** `docs(logging-automation): add trigger-classification reference`

---

### Task 4: Author the altitude-routing reference

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/altitude-routing.md`

**Depends on:** 2
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (altitude routing) · [prd.md § Constraints](./prd.md#constraints) (repo-agnostic resolution)

**Acceptance:**
- Maps each altitude to its anchor: lab → `<DEV_ROOT>/project_log.md`; project → `<repo>/project_log.md`; plan-execution → `## Execution Log` in the plan doc — matching the `03-logging.md` altitude table.
- Encodes the `03-logging.md` decision test: cross-repo → lab; matters after the plan ships → project; only how the plan ran → plan-execution.
- Specifies repo/altitude resolution from invocation context (CWD, an explicitly named repo, or `<DEV_ROOT>`) so the skill works in any lab repo and in a bare session — not a hard-coded path.
- Records the **lab-altitude caveat**: no git/CI, honor-system immutability, and Refs are absolute paths/URLs (never a PR#) at the lab altitude.
- Names `03-logging.md` § Log altitudes as the owning source.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/altitude-routing.md && test -f "$f" && grep -q "Execution Log" "$f" && grep -qi "DEV_ROOT" "$f" && grep -qi "paths/URLs\|paths or URLs\|absolute path" "$f"
```

**Commit:** `docs(logging-automation): add altitude-routing reference`

---

### Task 5: Author the entry-format and Standing-Decisions index reference

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/entry-format.md`

**Depends on:** 2
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (format is byte-valid against log-lint)

Context: output must pass `log-lint` (parsed against `lab-os/templates/project_log.template.md`), so the format grammar must be reproduced operationally, not paraphrased loosely.

**Acceptance:**
- Reproduces the project/lab entry grammar: `## YYYY-MM-DD HH:MM — <subject>` header (— is U+2014), the `Decision:` / `Why:` / `Alternatives:` / `Supersedes:` / `Refs:` field set, ≤1,500-byte budget, count-free, no `Status:` field, PR# as the durable ref (squash SHA forbidden).
- Reproduces the ordering/separator rules: entries reverse-chron, top-insert, each preceded by `---` on its own line then a blank line; a PR's new entries form one contiguous internally-date-ordered block at the head.
- Reproduces the **Standing-Decisions index** line grammar (`- YYYY-MM-DD HH:MM — <subject> · #<PR-or-archive-link>`, date+subject matching the entry header verbatim) and states the rule: a new standing decision emits an index line in the same change; **events and plan-execution entries get NO index line**.
- Reproduces the **plan-execution** one-line grammar separately: `YYYY-MM-DD HH:MM · task N · <what happened / why / output>` (distinct from the full entry format).
- States the 15 KB whole-file cap and that an over-cap entry warns (never blocks), routing overflow to a `chore: archive log overflow` PR — as context the skill surfaces, not work it performs.
- Names `03-logging.md` § Entry format / § File structure & overflow and `project_log.template.md` as owning sources.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/entry-format.md && test -f "$f" && grep -q "1,500" "$f" && grep -q "Standing Decisions\|Standing-Decisions" "$f" && grep -q "task N" "$f"
```

**Commit:** `docs(logging-automation): add entry-format and index reference`

---

### Task 6: Phase-A integration — dry classification of three sample moments

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/examples.md`

**Depends on:** 3, 4, 5
**Agent-suitable:** yes

**Spec:** [prd.md § Plan — Phase 1 checkpoint](./prd.md#phase-1--canonical-logic--packaging-skeleton)

Context: the Phase-1 checkpoint is a dry run — narrated routing for three sample moments with no writes — so the references compose into one coherent decision. The examples file is the captured demonstration of that.

**Acceptance:**
- Walks three worked samples end-to-end through classification → altitude → surface, with the verdict named: (a) a load-bearing decision → loggable → project (or lab if cross-repo) altitude, full entry + index line, **write gated**; (b) a bare status ("merged, smoke passed") → else-route → PR-comment draft, **no project-log write**; (c) a plan deviation → else-route → plan-execution one-line entry.
- Each sample shows the exact target surface and the exact format shape that would be produced (header line / index line / one-liner) without performing any file write.
- The samples use synthetic content only (no gated-dataset text, no re-identifying paths) per `02-data-protection.md`.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/examples.md && test -f "$f" && grep -qi "merged, smoke passed\|bare status" "$f" && grep -qi "gated\|no write\|not.*project.log\|PR comment" "$f" && claude plugin validate ./plugins/logging-automation
```

**Commit:** `docs(logging-automation): add worked routing examples`

---

## Phase B — Tiered write + supersession/immutability

### Task 7: Add the `/log` slash command driving the capture flow

**Files:**
- Create: `plugins/logging-automation/commands/log.md`

**Depends on:** 6
**Agent-suitable:** yes

**Spec:** [prd.md § Scope (In scope)](./prd.md#in-scope) (explicit `/log` command) · [prd.md § Plan — Phase 2](./prd.md#phase-2--tiered-write--supersessionimmutability)

Context: mirror `plugins/pr-review-loop/commands/pr-review-loop.md` shape — frontmatter `description` + `argument-hint`, body that hands the host session into the skill flow via `${CLAUDE_PLUGIN_ROOT}` reference paths.

**Acceptance:**
- Frontmatter declares a `description` and an `argument-hint` covering an optional target repo and the decision/event text (e.g. `[<repo>] <what happened>`); optional flags for forcing a tier are documented if introduced.
- The command body directs the session to run the classify → route → draft flow defined in `SKILL.md` and its references, resolving reference paths via `${CLAUDE_PLUGIN_ROOT}`.
- Invoking `/log` with no arguments captures the most recent loggable moment from session context (on-demand capture), not an error.
- The command performs no commit/push/PR-post itself (drafts only; consistent with the comms gate).

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/commands/log.md && test -f "$f" && grep -q "argument-hint:" "$f" && grep -q "CLAUDE_PLUGIN_ROOT" "$f" && claude plugin validate ./plugins/logging-automation
```

**Commit:** `feat(logging-automation): add /log slash command`

---

### Task 8: Specify the two-tier write contract (status auto-draft vs decision gate)

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/write-tiers.md`
- Modify: `plugins/logging-automation/skills/logging-automation/SKILL.md`

**Depends on:** 7
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (the write tier is enforced) · [prd.md § Scope — Out of scope](./prd.md#out-of-scope) (no write-decisions-without-approval mode)

**Acceptance:**
- Defines two tiers: **status/event** (bare status, releases/events surfaced as facts) → auto-draft to the correct surface (PR comment for bare status; project/lab entry for an irreversible/external *event*, which carries no index line) and **may be applied** without a decision-gate; **load-bearing decision** → draft only, **held for explicit human approval** before any write to an immutable surface.
- States the gate as a hard invariant: a load-bearing-decision entry is never written to a project/lab log until the human approves the drafted text — there is no autonomy mode that bypasses this (cross-references the global approval-gate posture).
- The status tier still routes correctly: a bare status fact is drafted as a PR-comment artifact and is NOT applied to the project log (the wrong-surface guard from Task 3 holds at write time).
- SKILL.md is updated to reference `write-tiers.md` and to state the gate in its overview.
- The draft for an immutable-surface decision presents the byte-valid entry (Task 5 format) for review, and names the exact file + insertion point it *would* write on approval.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/write-tiers.md && test -f "$f" && grep -qi "approval\|gate" "$f" && grep -qi "PR comment" "$f" && grep -q "write-tiers" plugins/logging-automation/skills/logging-automation/SKILL.md
```

**Commit:** `feat(logging-automation): add tiered write contract`

---

### Task 9: Specify supersession and immutability handling

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/supersession.md`
- Modify: `plugins/logging-automation/skills/logging-automation/reference/entry-format.md`

**Depends on:** 8
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (supersession never mutates history)

**Acceptance:**
- A reversal/revision of a prior decision drafts a **new** entry carrying `Supersedes: <YYYY-MM-DD HH:MM — subject>` and stages removal of the superseded Standing-Decisions index line **in the same change** — and the skill refuses to edit the existing entry body.
- States the immutability rule: entries are immutable once their PR merges (lab altitude: once a newer entry exists); the skill never proposes an in-place edit of a merged/immutable entry.
- A factual-only fix (e.g. a typo'd PR#) is surfaced as the **`log-lint:override`** route (a labeled PR with a reason in the body), explicitly NOT a silent edit — the skill explains this path rather than performing a silent correction.
- `entry-format.md` cross-links the `Supersedes:` field semantics so the format and supersession references agree.
- Names `03-logging.md` § Immutability & supersession as the owning source.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/supersession.md && test -f "$f" && grep -q "Supersedes" "$f" && grep -q "log-lint:override" "$f" && grep -qi "never edit\|refuse\|not.*silent" "$f"
```

**Commit:** `feat(logging-automation): add supersession and immutability handling`

---

### Task 10: Phase-B integration — gated-decision, status-draft, and reversal demonstrations

**Files:**
- Modify: `plugins/logging-automation/skills/logging-automation/reference/examples.md`

**Depends on:** 9
**Agent-suitable:** yes

**Spec:** [prd.md § Plan — Phase 2 checkpoint](./prd.md#phase-2--tiered-write--supersessionimmutability)

**Acceptance:**
- Adds a worked **decision** sample: produces a byte-valid entry + matching index line and **refuses to write** until approval is given (the gate visibly fires).
- Adds a worked **status** sample: drafts a PR-comment-shaped artifact and applies nothing to the project log.
- Adds a worked **reversal** sample: drafts a `Supersedes:` entry and stages the superseded index-line removal **without** editing the old entry; shows the `log-lint:override` explanation for a contrasting typo-fix case.
- Adds a **lab-altitude** sample: Refs use an absolute path/URL, not a PR#.
- All samples remain synthetic per `02-data-protection.md`.

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/examples.md && grep -q "Supersedes" "$f" && grep -qi "refuse\|until approval\|gated" "$f" && grep -q "log-lint:override" "$f" && claude plugin validate ./plugins/logging-automation
```

**Commit:** `docs(logging-automation): add tiered-write and supersession examples`

---

## Phase C — Mission Control consumption contract

### Task 11: Export the consumption contract for MC Phase 6

**Files:**
- Create: `plugins/logging-automation/skills/logging-automation/reference/consumer-contract.md`

**Depends on:** 10
**Agent-suitable:** yes

**Spec:** [prd.md § Success criteria](./prd.md#success-criteria) (Mission Control consumes, does not duplicate) · [prd.md § Plan — Phase 3](./prd.md#phase-3--mission-control-consumption-contract)

Context: MC Phase 6's `log:` flow (`mission-control/docs/superpowers/specs/2026-05-29-phase-6-hermes-skills-design.md`) must source its drafting/routing/format from here so a `03-logging.md` change is absorbed once — this file is the stable seam it consumes.

**Acceptance:**
- Documents the stable interface this skill exposes to a consumer: the inputs (a candidate moment + optional target repo) and the outputs (a routing **verdict** — loggable+trigger+altitude OR else-route+home — plus a **draft artifact** in the surface-correct format, plus the target file + insertion point for an applicable write).
- Draws the ownership line: this skill owns *what / where / format*; MC owns the **approve-UI**, the **SQLite `log_entries` store**, the **optional `project_log.md` append**, and the **dual-store divergence tripwire** (`last_appended_hash`) — names these as MC's, not this skill's.
- States the three consumption mechanisms under consideration (invoke the installed skill in MC's session / vendor the reference files into `hermes-skills/log-capture/` / consume this contract document) and flags that the choice is pinned at MC's Phase-6 install spike — consistent with the PRD open question.
- Maps this skill's draft to MC's `log_entries` fields (`entry_date`, `topic`, `body_md`) and to the lab `## YYYY-MM-DD — <topic>` append shape, so the seam is concrete.
- Confirms the gate alignment: this skill's load-bearing-decision gate corresponds to MC's structural `awaiting_approval` step for action skills (the two gates agree; MC's is the UI realization).

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && f=plugins/logging-automation/skills/logging-automation/reference/consumer-contract.md && test -f "$f" && grep -qi "log_entries" "$f" && grep -qi "approve\|awaiting_approval\|gate" "$f" && grep -qi "Phase 6\|phase-6" "$f"
```

**Commit:** `docs(logging-automation): export Mission Control consumption contract`

---

### Task 12: Cross-reference the contract from MC Phase 6 and finalize README

**Files:**
- Modify: `mission-control/docs/superpowers/specs/2026-05-29-phase-6-hermes-skills-design.md`
- Modify: `README.md` (lab-claude-plugins root)

**Depends on:** 11
**Agent-suitable:** yes

**Spec:** [prd.md § Plan — Phase 3 checkpoint](./prd.md#phase-3--mission-control-consumption-contract) · [prd.md § Constraints](./prd.md#constraints) (consumed by MC Phase 6)

Context: the MC spec currently describes the `log:` flow's format/routing inline; add a pointer (do not rip out MC's design) so MC's flow is declared a **consumer** of `logging-automation` rather than an independent reimplementation. The cross-repo nature of this wiring is itself a lab-altitude log event at consolidation.

**Acceptance:**
- The MC Phase 6 spec gains an explicit note that the `log:` capture flow's drafting/routing/format logic is **sourced from the `logging-automation` plugin** (source of truth: this packet + `03-logging.md`), with MC retaining its approve-UI, `log_entries` store, file-append, and divergence tripwire.
- The note links to the `logging-automation` consumer-contract reference and does not duplicate the routing/format rules into the MC spec.
- The lab-claude-plugins `README.md` names **mission-control Phase 6** as the first consumer of this skill.
- No MC implementation behavior is changed by this packet (the wiring is a reference/contract addition; MC's own Phase-6 plan adopts the mechanism at its install spike).

**Verification:**
```shell
cd "$LAB_CLAUDE_PLUGINS" && grep -qi "mission-control Phase 6\|mission-control phase-6\|first consumer" README.md && grep -qi "logging-automation" "$MISSION_CONTROL/docs/superpowers/specs/2026-05-29-phase-6-hermes-skills-design.md"
```

**Commit:** `docs(logging-automation): wire Mission Control Phase 6 as first consumer`

---

## Execution Log

<!-- Altitude: plan-execution (see lab-os/.claude/rules/03-logging.md § altitudes).
     What belongs here: deviations from this plan, implementation-altitude calls, gate
     evidence (the verification output that proved a task done).
     What does NOT belong here: load-bearing decisions (→ the lab project_log.md, since
     this is a cross-repo plugin), bare status (→ PR comment), session narrative (→ PR body).
     This log closes when the shipping PR merges — post-merge evidence goes to a comment
     on that PR, not a trailing entry.

     Entry grammar (one line each):
     YYYY-MM-DD HH:MM · task N · <what happened / why / output> -->

<!-- entries below — newest at top -->
