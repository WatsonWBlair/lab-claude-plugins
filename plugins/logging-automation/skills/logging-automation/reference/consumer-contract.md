# Consumer Contract — `logging-automation` Skill

This file is the stable seam between the `logging-automation` skill and its consumers,
specifically Mission Control (MC) Phase 6. A consumer (MC or any other caller) sources
the classification logic, routing rules, entry format, and gate behavior from this skill's
reference files. When `lab-os/.claude/rules/03-logging.md` changes, this skill's reference
files are updated here — the consumer absorbs the change by re-reading this contract (or by
re-syncing the vendored files), not by patching its own logic.

Do not restate this contract in MC. Link or reference it; consume the outputs named below.

---

## 1. Inputs

| Input | Required | Description |
|---|---|---|
| `candidate_moment` | Required | The raw text describing the moment to evaluate: a decision, event, direction change, or status fact. Free-form prose; the skill interprets it through the trigger-classification procedure. |
| `target_repo` | Optional | The lab repo the entry should be associated with (name or absolute path). Defaults per `altitude-routing.md` § Invocation-context resolution. If omitted and the context does not resolve a repo unambiguously, the skill asks once or drafts without applying. |

No other inputs are required. A consumer passes these two values; the skill handles all
classification, altitude resolution, format assembly, and gate determination internally.

---

## 2. Outputs

The skill emits exactly one of two verdict shapes, plus (on a loggable verdict) a draft
artifact and write-target package.

### 2a. Verdict — loggable

```
verdict:    loggable
trigger:    <1 | 2 | 3>        # which trigger fired (trigger-classification.md)
altitude:   <lab | project | plan-execution>   # altitude-routing.md
```

Accompanied by:

- **Draft artifact** — byte-valid entry text in the surface-correct format:
  - Altitude `lab` or `project`: full entry in the `## YYYY-MM-DD HH:MM — <subject>` grammar
    plus (for Trigger 1 and Trigger 3 only) the matching Standing Decisions index line.
    See `entry-format.md` §§ 1–3 for the exact grammar.
  - Altitude `plan-execution`: one-liner in the `YYYY-MM-DD HH:MM · task N · <prose>` grammar.
    See `entry-format.md` § 4. No Standing Decisions index line is emitted.
- **Write target** — exact file path + insertion point:
  - File path: e.g. `C:/Users/watso/Development/LSCA/project_log.md`
  - Insertion point: top-insert at the head of the `## Entries` section, preceded by `---` on
    its own line, then a blank line, then the `## YYYY-MM-DD` header.
  - For plan-execution altitude: append to the `## Execution Log` section of the named plan doc.
- **Gate flag**: `requires_approval: true` (Trigger 1 and Trigger 3) or `false` (Trigger 2).

### 2b. Verdict — else-route

```
verdict:    else-route
home:       <PR comment | plan-execution log | TROUBLESHOOTING.md or GitHub issue |
             GitHub issue | PR body | auto-memory>
```

The output depends on which else-route home is named:

**Bare-status (home = PR comment):** The skill emits a **PR-comment draft artifact** — freeform
prose suitable for posting as a comment on the relevant PR. No project/lab log write target is
named. The skill MAY apply this draft without a decision gate; the surface is always a PR comment,
never a log entry. (Consistent with `write-tiers.md` § Tier 1 Sub-case A.)

**All other else-route homes** (plan deviation → plan-execution log; gotcha → TROUBLESHOOTING.md
or GitHub issue; follow-up → GitHub issue; session narrative → PR body; preference-fact →
auto-memory): No draft artifact is produced; no write target is named. The caller routes the
moment to the named home.

See `trigger-classification.md` § Else-routes table for the exact mapping.

---

## 3. Ownership line

This skill owns:

- **What to log** — trigger classification (loggable vs else-route; which trigger fired).
- **Where to log it** — altitude resolution (lab / project / plan-execution) and the exact
  target file path and insertion point.
- **Exact format** — byte-valid draft text conforming to the canonical grammar.
- **Gate determination** — whether the draft requires explicit human approval before any write
  (Tier 2: Trigger 1 and Trigger 3 are always gated; Tier 1: Trigger 2 auto-applies).

Mission Control (MC) owns:

- **The approve-UI** — the editable preview pane and [Approve] / [Reject] controls that
  present the skill's draft to Watson and collect his decision. This is MC's surface realization
  of the gate; the gate itself is this skill's rule.
- **The SQLite `log_entries` store** — MC's queryable capture record. On approval, MC writes a
  `log_entries` row (see field mapping, § 5). SQLite is the canonical store; `project_log.md`
  is the synced human-readable export. On divergence, SQLite wins.
- **The optional `project_log.md` append** — MC performs the file-append side-effect on
  approval, using the write target and insertion point this skill names. The append is optional
  and atomic; `log_entries.file_appended` records whether it succeeded.
- **The `last_appended_hash` dual-store divergence tripwire** — MC stores a sha256 of the
  file-tail at the last successful append on the most-recent `log_entries` row for each target.
  Before any new append, MC verifies the live file-tail matches the stored hash. On mismatch
  (manual edits outside MC), MC surfaces a divergence warning and holds the run in
  `awaiting_approval` rather than silently overwriting. This tripwire is MC's responsibility;
  the skill does not perform it.

This skill does NOT own: the approve-UI, the SQLite store, the file-append execution, or the
divergence tripwire. It produces the draft and the gate flag; MC does the rest.

---

## 4. Consumption mechanisms

Three mechanisms are under consideration. The choice is pinned at MC's Phase-6 install spike
— it is an open question, not decided here.

1. **Invoke the installed skill in MC's session.** MC drives the `logging-automation` skill
   installed into the Hermes skill directory via the spike-pinned install seam (CLI command or
   programmatic file-sync over the DV31 WSL shell-out). The skill runs via `claude -p` and
   returns the verdict + draft as structured output. MC's log-capture Hermes skill (`log-capture`
   in `hermes-skills/`) wraps this invocation.

2. **Vendor the reference files into `hermes-skills/log-capture/`.** MC copies this skill's
   reference files (`trigger-classification.md`, `altitude-routing.md`, `entry-format.md`,
   `write-tiers.md`) into its in-repo skill source directory. The `log-capture` skill's prompt
   sources these files directly rather than invoking the installed skill. Updates to the
   canonical files require a re-sync step.

3. **Consume this contract document.** MC's `log-capture` skill sources only this file —
   treating it as the stable seam — and implements the classification and format logic inline
   using the contract's output specification. No vendored files; no install dependency.

The tradeoffs: (1) keeps a single authoritative skill artifact but introduces an install-seam
dependency; (2) decouples from the install mechanism but requires a sync discipline; (3)
minimizes dependencies but risks the inline implementation drifting from this skill's reference
files. Pin the choice during the Phase-6 install spike.

---

## 5. Field mapping

### Skill draft → MC `log_entries` fields

The skill's draft artifact maps to MC's `log_entries` table as follows (field names from the
Phase-6 spec):

| `log_entries` field | Source in skill output |
|---|---|
| `entry_date` | The `YYYY-MM-DD` portion of the draft's `## YYYY-MM-DD HH:MM — <subject>` header |
| `topic` | The `<subject>` portion of the draft's header (after the em-dash) |
| `body_md` | The full entry body text (from `**Decision:**` through `**Refs:**`); excludes the `## YYYY-MM-DD` header line itself |
| `target_repo` | Resolved from the `target_repo` input + altitude routing; MC's default is `mission-control` |
| `file_appended` | Set by MC after the optional `project_log.md` append attempt; not produced by this skill |
| `skill_run_id` | FK to the `skill_run` row that invoked the log-capture skill; set by MC |
| `last_appended_hash` | sha256 of file-tail after successful append; computed and stored by MC |

Note: `entry_date` is not unique — multiple entries on the same date are expected. MC sorts by
`created_at` for stable ordering within a day.

Note: MC's Phase-6 `body_md` column note ("decision / why / alternatives / status") predates the
no-`Status:` rule in `03-logging.md`. The canonical field set this skill emits is
**Decision / Why / Alternatives / Refs** — there is no `Status:` line (currency lives in the
Standing Decisions index, per `entry-format.md` § 1). Do not reintroduce a `Status:` field on the
MC side when mapping `body_md`.

### Skill draft → `project_log.md` append shape

The lab canonical append format is:

```
---

## YYYY-MM-DD HH:MM — <topic>

**Decision:** <body>
**Why:** <rationale>
**Alternatives:** <if weighed>
**Refs:** #<PR or path>
```

The skill's draft artifact is byte-valid for direct insertion into the `## Entries` section.
MC appends the skill's draft text verbatim (no transformation) at the top-insert position named
in the write target output. The `---` separator and blank line precede the header, per
`entry-format.md` § 2.

---

## 6. Gate alignment

This skill's Tier 2 gate (load-bearing-decision hard invariant in `write-tiers.md` § Tier 2)
and MC's `awaiting_approval` step for action skills (Phase-6 spec, `skill_run` lifecycle) are
the same gate — they agree. The skill determines that a draft requires approval and sets
`requires_approval: true`. MC's skill executor sees an `action`-kind `skill_run` and
structurally routes it through `awaiting_approval` before any write (a framework requirement
for all action skills, Watson-locked 2026-05-29 per the Phase-6 spec).

The two constraints are not redundant — they enforce the gate at different layers:

- **This skill's rule** (classification layer): a Trigger 1 or Trigger 3 draft is never
  auto-applied; the gate flag is a hard invariant independent of MC's executor.
- **MC's structural gate** (executor layer): every `action`-kind `skill_run` passes through
  `awaiting_approval` regardless of `autonomy_mode` value; the executor refuses to advance an
  action run to `executed` except through `/approve`.

MC's `awaiting_approval` step is the UI realization of the same gate this skill declares.
A future autonomy-mode enable (`act-then-report`) in MC's registry does not override this
skill's hard invariant — Tier 2 drafts are held regardless of the executor's autonomy setting.

---

## Reference files in this skill

| File | What it owns |
|---|---|
| `trigger-classification.md` | The three-trigger decision procedure (loggable vs else-route; verdict + trigger number) |
| `altitude-routing.md` | Altitude resolution (lab / project / plan-execution) and target-file derivation |
| `entry-format.md` | Full entry grammar, ordering rules, Standing Decisions index line grammar, plan-execution one-liner grammar |
| `write-tiers.md` | Two-tier write contract: Tier 1 (auto-draft) vs Tier 2 (held for explicit approval; hard invariant) |
| `supersession.md` | Immutability rules and the supersession procedure |
| `examples.md` | Worked examples for all trigger classes and altitude combinations |
