# Logging Automation Skill — PRD

> **Supersedes** the scattered "Logging / Convention Skills / Rules" thread in
> `C:\Users\watso\Development\Open-Threads.md` (Topic: *"I want logging AI-facing
> logging, particularly items required for audit trails, to automatically be added
> to the appropriate log files."*). That thread is reduced to a single backlog line
> pointing here; this PRD is the source of truth for the logging-automation capability.
>
> **Does NOT supersede** `lab-os/.claude/rules/03-logging.md` — that document remains
> the authoritative *rules* (altitudes, entry triggers, format, immutability). This
> skill **automates** those rules; it never redefines them. Where the two ever
> disagree, `03-logging.md` wins and this skill is the bug.

**Status:** draft
**Date:** 2026-06-18 · **Repo:** `lab-claude-plugins` (new plugin: `logging-automation`)
**Packet:** P9 (Open-Threads consolidation) · **Route:** lab-claude-plugins marketplace

> **Decisions live in `project_log.md`, not here.** Load-bearing calls made while
> executing this PRD are logged at the lab altitude
> (`C:\Users\watso\Development\project_log.md`) per `03-logging.md` entry triggers —
> not embedded in this document.

---

## Problem

Audit-trail logging is a **rule Watson follows by hand, in every repo, in every
session** — and it decays exactly when it matters most. `03-logging.md` already
defines, precisely, *what* must be logged (three entry triggers), *where* it goes
(three altitudes: lab / project / plan-execution), and *how* (a fixed entry format,
a Standing-Decisions index, an immutability contract). But the rules are inert: an
AI session has to remember they exist, classify the moment correctly, pick the right
file, match the format byte-for-byte, and update the index — under the cognitive load
of the actual work. The failure modes are predictable and observed:

- **Missed events.** A load-bearing decision gets made mid-session and never logged,
  because nothing prompted the capture at the moment it happened.
- **Wrong surface.** A bare status fact ("merged, smoke passed") gets written into the
  project log as if it were a decision, bloating the "what is still true" surface that
  `03-logging.md` reserves for durable decisions — when it belonged in a PR comment.
- **Format drift.** Hand-written entries miss the `Supersedes:` line, skip the
  Standing-Decisions index update, use a squash SHA where a PR# is required, or break
  the `## YYYY-MM-DD HH:MM — subject` anchor that `log-lint` parses.
- **No portability.** The logging discipline is identical across ~12 lab repos and
  every ad-hoc Claude session, yet there is no shared, invokable implementation of it —
  each session re-derives the rules from the always-loaded `03-logging.md` text.

This maps directly to one of Watson's named pain points: *documentation upkeep falling
behind the work.* The lab needs the logging rules to be **executable**, not just
**readable** — a portable capability any Claude session in any repo can call to turn a
loggable moment into a correctly-routed, correctly-formatted entry, with a human gate
on the entries that are immutable and load-bearing.

**For whom:** every AI session operating in a lab repo (Watson's primary driver today;
the overnight-agent workflow and the bots P10/P11 tomorrow), plus Mission Control's
Phase 6 `log:` capture flow, which needs this logic but must not reinvent it.

---

## Success criteria

- **Trigger detection matches the rules.** Given a session moment, the skill classifies
  it against the three `03-logging.md` entry triggers (load-bearing decision /
  irreversible-or-external event / direction change) and correctly distinguishes a
  loggable event from an "else-routes" case (bare status, deviation, follow-up,
  gotcha, preference-fact) — with the chosen route named back to the user.
- **Altitude routing is correct.** The skill resolves the right altitude — lab
  (`<DEV_ROOT>/project_log.md`), project (`<repo>/project_log.md`), or plan-execution
  (`## Execution Log` in the plan doc) — using the `03-logging.md` decision test
  (cross-repo → lab; matters after the plan ships → project; only how the plan ran →
  plan-execution), and writes to that surface, not a default.
- **Format is byte-valid against `log-lint`.** A generated project/lab entry uses the
  exact `## YYYY-MM-DD HH:MM — <subject>` header, the Decision/Why/Alternatives
  /Supersedes/Refs field grammar, the `---`+blank-line separator, top-insert ordering,
  and ≤1,500-byte budget; a new standing decision additionally emits a matching
  Standing-Decisions index line (date+subject verbatim). A plan-execution entry uses the
  one-line `YYYY-MM-DD HH:MM · task N · …` grammar instead.
- **The write tier is enforced.** Bare status/event facts auto-**draft** to the correct
  surface (often a PR comment, never assumed to be the project log) and can be applied
  without a decision-gate; a **load-bearing decision** is never written to an immutable
  log surface until the human has reviewed and approved the drafted entry.
- **Supersession never mutates history.** When a decision reverses a prior one, the
  skill drafts a *new* entry carrying `Supersedes:` and stages removal of the superseded
  Standing-Decisions index line in the same change — and refuses to edit the existing
  entry body. A factual-fix path (typo'd PR#) is surfaced as the `log-lint:override`
  route, not a silent edit.
- **It is portable and repo-agnostic.** The same installed skill produces correct output
  in any lab repo and in a bare Claude session, resolving altitude anchors from the
  invocation context (CWD / named repo / `<DEV_ROOT>`) rather than hard-coded paths,
  and honoring the lab caveat (no PR# at the lab altitude — Refs are absolute paths/URLs).
- **Mission Control consumes, does not duplicate.** The Phase 6 `log:` capture flow's
  drafting + routing + format logic is sourced from this skill (invoked, vendored, or
  referenced by contract — pinned at plan time), such that a change to `03-logging.md`
  is absorbed in one place. MC owns its approve-UI and its dual-store write; this skill
  owns the *what/where/format* decision.
- **Packaged to the marketplace convention.** Installs via
  `/plugin install logging-automation@lab-claude-plugins`, exposes a slash command and
  an auto-trigger description, and `claude plugin validate` passes.

---

## Scope

### In scope

- **A new `logging-automation` plugin** in the `lab-claude-plugins` marketplace,
  packaged per the `pr-review-loop` template (`.claude-plugin/plugin.json`, a
  `commands/` slash command, a `skills/logging-automation/SKILL.md` with bundled
  reference files, an entry in root `marketplace.json`, a README row).
- **Trigger-detection logic** that classifies a candidate moment against the three
  `03-logging.md` entry triggers and the "else-routes" table, and names the verdict.
- **Altitude + format routing** that selects lab / project / plan-execution and emits
  the surface-correct artifact: a full lab-format entry (+ index line for standing
  decisions) for project/lab; a one-line execution-log entry for plan-execution; a
  PR-comment-shaped draft for bare status/events.
- **The tiered write contract:** auto-draft for status/event facts (apply allowed);
  human-approval gate before any write of a load-bearing decision to an immutable
  surface. The gate is a hard requirement, not a preference.
- **Supersession + immutability handling:** new-entry-with-`Supersedes:`,
  same-change index-line removal, refusal to edit merged/immutable entries, and the
  `log-lint:override` surfacing for factual fixes.
- **An auto-trigger affordance** (skill description) so a session *notices* a loggable
  moment without an explicit slash invocation, plus the explicit `/log` command for
  on-demand capture.
- **The Mission-Control consumption contract:** a documented, stable interface (the
  draft-shape + the routing decision the skill returns) that MC's Phase 6 flow calls,
  with this packet naming MC Phase 6 as the first consumer.
- **A README + SKILL.md** that state the supersession of the Open-Threads thread and
  the source-of-truth relationship to `03-logging.md`.

### Out of scope

- **Re-defining the logging rules.** Altitudes, triggers, format, immutability,
  budgets, and the index grammar are owned by `03-logging.md` / `04-docs.md` /
  `project_log.template.md`. This skill reads and applies them; it never forks them.
  A rules change is a lab-os PR, not a change here.
- **Building `log-lint` or a CI gate.** Enforcement tooling (the parser, the
  byte-budget warn/fail, the overflow `chore: archive` automation) is separate lab-os
  /CI work. This skill *targets* `log-lint`'s grammar so its output passes, but does
  not implement or invoke it. (If a `log-lint` binary exists at run time, calling it as
  a post-draft check is a plan-time nicety, not a deliverable.)
- **Auto-committing or auto-pushing.** The skill drafts and (for status-tier) applies
  file edits; it does not open PRs, commit, push, or post to GitHub. Posting a PR
  comment is drafted for the human/automation to send, consistent with the comms
  approval gate.
- **The Mission Control approve-UI, SQLite store, file-append side-effect, and
  divergence tripwire.** Those are MC's Phase 6 deliverables (`log_entries` table,
  `last_appended_hash`, the dual-store canonical-read direction). This skill supplies
  the upstream draft + routing; it does not own MC's persistence or UI.
- **Prompt optimization** (that is P8, a sibling plugin) and **PR-review** (the
  existing `pr-review-loop` plugin).
- **Auto-deciding the autonomy posture for load-bearing decisions.** There is no
  "draft-and-write-decisions-without-approval" mode; the decision gate is fixed on.
  (An `act-then-report` posture, if ever wanted, is MC/Phase-5 territory and explicitly
  not introduced here.)

---

## Constraints

- **Budget:** Zero metered spend by construction — the skill is instructions + bundled
  reference files executed by the host Claude session (Max-via-subprocess posture); no
  API key, no per-invocation cost. Well under the $300/mo flag.
- **Timeline:** No hard deadline. Sequenced after the Open-Threads interview pass; a
  sibling of P8 (prompt-optimization) in the same marketplace, so packaging conventions
  are shared and should land consistently.
- **Data / access:** None. Operates on lab markdown logs only. Must honor
  `02-data-protection.md` indirectly — the skill never embeds raw gated-dataset
  content in a drafted entry (entries are decision/event prose, not data dumps), and it
  must not surface paths/stem-names that re-identify a clip when summarizing data work.
- **Infra:** Claude Code with plugin support. No runtime services. Reference files must
  resolve via `${CLAUDE_PLUGIN_ROOT}` (the `pr-review-loop` portability pattern), since
  the skill ships inside an installed plugin and runs in arbitrary repos.
- **Authority / source-of-truth:** `03-logging.md` is authoritative for the rules;
  this skill is a derived applier and must visibly cite it (`04-docs.md` single-source:
  "source of truth: `lab-os/.claude/rules/03-logging.md`"). The skill's reference files
  restate the rules *operationally* but must stay robust to `03-logging.md` changes and
  name it as owner — they are not a second source.
- **Approvals:** The human-approval gate on load-bearing-decision writes is a
  product constraint (mirrors Watson's global approval-gate posture on
  hard-to-reverse / immutable artifacts). No drafted PR comment is *posted* under
  Watson's name by the skill — drafting only; sending is gated comms.
- **Dependencies:** Consumed by **mission-control Phase 6** (`2026-05-29-phase-6-
  hermes-skills-design.md` — the `log:` capture flow). This packet is the canonical
  logic that flow references. Sibling packaging with **P8** (prompt-optimization).
  No hard upstream code dependency (unlike `pr-review-loop`'s `ralph-loop`); this is a
  self-contained skill.

---

## Plan (phased)

High-level phases; per-task detail lives in `plan.md`. Each phase ships a usable
increment and ends at a checkpoint Watson can sign off.

### Phase 1 — Canonical logic + packaging skeleton

**Goal:** A self-contained, installable `logging-automation` plugin whose reference
files operationalize the `03-logging.md` triggers, altitudes, and format — repo-agnostic.
**Deliverables:** plugin scaffold (`plugin.json`, `marketplace.json` row, README row);
`SKILL.md` with the auto-trigger description; bundled reference files (trigger
classification, altitude routing, entry-format/index grammar) that cite `03-logging.md`
as owner; portability via `${CLAUDE_PLUGIN_ROOT}`.
**Checkpoint:** `claude plugin validate` passes; a dry classification of three sample
moments (a decision, a bare status, a plan deviation) routes each to the correct
altitude/surface in narration, no writes yet.

### Phase 2 — Tiered write + supersession/immutability

**Goal:** The skill drafts and, for the status/event tier, applies; the load-bearing
tier is gated; supersession and immutability are honored.
**Deliverables:** the `/log` slash command driving the capture flow; the two-tier
behavior (status/event auto-draft+apply to the right surface; decision draft held for
explicit human approval before any immutable-surface write); supersession path
(new entry + `Supersedes:` + same-change index-line removal, never an edit);
factual-fix surfaced as the `log-lint:override` route; lab-altitude caveat (no PR#,
paths/URLs as Refs).
**Checkpoint:** on a decision sample the skill produces a byte-valid entry + index line
and **refuses to write** until approval; on a status sample it drafts a PR-comment-shaped
artifact and applies nothing to the project log; on a reversal it drafts a `Supersedes:`
entry and stages the index removal without touching the old entry.

### Phase 3 — Mission Control consumption contract

**Goal:** MC Phase 6's `log:` flow sources its drafting/routing/format from this skill
instead of duplicating it.
**Deliverables:** a documented, stable contract (the routing verdict + draft shape this
skill returns) for MC to call; a note in the MC Phase 6 design (or its plan, at
consolidation) that the `log:` capture flow consumes `logging-automation`; the README
naming MC Phase 6 as the first consumer.
**Checkpoint:** the contract is written and referenced from MC Phase 6; a walkthrough
shows an MC `log: <repo> <decision>` invocation producing the same routing verdict +
draft this skill would, with MC owning only the approve-UI and dual-store write.

---

## Open questions

- [ ] **MC consumption mechanism** — does Phase 6 *invoke* this installed skill in its
  WSL/Hermes session, *vendor* the reference files into `hermes-skills/log-capture/`, or
  consume a *contract document* this packet exports? Affects how a `03-logging.md` change
  propagates to MC. — owner: Watson · due: before Phase 3 / aligns with MC Phase-6 install spike
- [ ] **Auto-trigger aggressiveness** — should the skill proactively interrupt the host
  session the moment it detects a loggable decision, or only surface a capture prompt at
  natural checkpoints (domain switch, pre-compaction, PR-open)? Over-eager interruption
  is friction; under-eager misses the moment. — owner: Watson · due: Phase 1 description-tuning
- [ ] **Reference-file restatement vs link** — how much of `03-logging.md` does the skill
  restate operationally (for deterministic in-session application) vs link to? Restating
  risks a second source drifting; linking risks the host session not loading it. Lean
  restate-the-grammar, cite-the-rationale. — owner: Watson · due: Phase 1 ref-file authoring
- [ ] **Repo/altitude resolution in a bare session** — outside a known lab repo, how does
  the skill resolve `<DEV_ROOT>` and the project-log path? Proposed: derive from CWD /
  ask once / fall back to drafting without applying. — owner: Watson · due: Phase 2
- [ ] **`log-lint` post-check coupling** — if a `log-lint` exists at run time, should the
  skill self-verify its draft against it before presenting? Nicety, not a deliverable;
  decide whether to wire it opportunistically. — owner: Watson · due: Phase 2 verification design
- [ ] **Standing-Decisions index for plan-execution entries** — confirmed none (events
  and plan-execution lines get no index line per `03-logging.md`); flagged only so the
  implementing agent does not add one. — owner: Watson · due: Phase 1 (confirm, then drop)
