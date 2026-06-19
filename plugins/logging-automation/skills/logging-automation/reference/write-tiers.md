# Write Tiers — Status/Event Auto-Draft vs Decision Gate

Source of truth for immutability rules and gate rationale: `lab-os/.claude/rules/03-logging.md`.
This file defines the two-tier write contract this skill enforces. Do not treat this file as authoritative over the source.

---

## Overview

Every loggable moment falls into exactly one write tier. The tier determines whether the skill may apply a draft autonomously or must hold it for explicit human approval before any write occurs.

---

## Tier 1 — Status/Event (auto-draft; MAY apply without a decision gate)

Applies to: **bare status facts** and **irreversible/external events** (Trigger 2 from `trigger-classification.md`).

### Sub-case A: Bare status

A bare status fact ("merged, smoke passed"; "CI green"; "branch cleaned up") is routed to a **PR comment**, not the project log. The wrong-surface guard in `trigger-classification.md` § BARE STATUS GUARD holds at write time — no autonomy mode overrides it.

- The draft is a **PR-comment artifact**: freeform prose suitable for posting as a comment on the relevant PR.
- The draft is **NOT applied to any project/lab log**.
- The skill MAY apply the PR-comment artifact without a decision gate, but the surface is always a PR comment — never a log entry.

### Sub-case B: Irreversible/external event (Trigger 2)

An irreversible or external event (release published, migration executed, secret rotated, org/repo change, data published) is routed to the correct project or lab log.

- The draft is a **full project/lab entry** in the canonical format (see `entry-format.md`).
- **No Standing Decisions index line is emitted.** Trigger 2 events do not produce index lines; only Trigger 1 and Trigger 3 entries do.
- The skill MAY apply this entry without a decision gate. The entry is inserted top-of-entries, preceded by `---` and a blank line, per the ordering rules in `entry-format.md` § 2.

---

## Tier 2 — Load-Bearing Decision or Direction Change (draft only; HELD for explicit human approval)

Applies to: **load-bearing decisions** (Trigger 1) and **direction changes/re-scopes** (Trigger 3) from `trigger-classification.md`.

### Hard invariant

> **A load-bearing-decision entry is NEVER written to a project/lab log until the human explicitly approves the drafted text.**

No autonomy mode, no act-then-report mode, and no inline continuation bypasses this gate. This is a hard invariant, not a preference. It derives from Watson's global approval-gate posture on hard-to-reverse and immutable artifacts: once an entry's PR merges, the entry is immutable — reversal requires a new superseding entry, not an edit (`03-logging.md` § Immutability & supersession). Writing a bad entry is hard to reverse; the gate exists to prevent that.

### What the draft must contain

A Tier 2 draft presents two things before any write occurs:

1. **Byte-valid entry text** — the complete entry in canonical format (`entry-format.md` § 1), including:
   - Header: `## YYYY-MM-DD HH:MM — <subject>` with U+2014 EM DASH, spaces before and after
   - All required fields (`**Decision:**`, `**Why:**`, optional `**Alternatives:**` if real alternatives were weighed, `**Refs:**`)
   - No `Status:` field
   - Entry budget: ≤ 1,500 bytes
   - The matching **Standing Decisions index line** (for Trigger 1 and Trigger 3): `- YYYY-MM-DD HH:MM — <subject> · #<PR>` — date+subject verbatim matching the header, U+00B7 MIDDLE DOT separator

2. **Exact write target** — the skill names:
   - The **exact file path** it would write to on approval (e.g. `C:/Users/watso/Development/LSCA/project_log.md`)
   - The **exact insertion point**: top-insert at the head of the `## Entries` section, below the file title and Standing Decisions index, preceded by `---` on its own line, then a blank line, then the `## YYYY-MM-DD` header

The draft writes nothing. The entry is held pending the human's explicit "go" or approval of the presented text.

### Example draft presentation

```
DRAFT — held for approval before any write:

---

## 2026-06-18 14:30 — switched log serialiser from JSON to CBOR

**Decision:** logging-automation skill uses CBOR for plan-execution one-liners; JSON for full entries.
**Why:** CBOR halves byte cost for timestamp-heavy payloads; full entries stay human-readable.
**Alternatives:** MessagePack rejected — no native Python stdlib support without a third-party wheel.
**Refs:** #47, C:/Users/watso/Development/lab-claude-plugins/plugins/logging-automation/SKILL.md

---

Standing Decisions index line (add to ## Standing Decisions):
- 2026-06-18 14:30 — switched log serialiser from JSON to CBOR · #47

---

Target file:  C:/Users/watso/Development/lab-claude-plugins/project_log.md
Insertion:    Top of ## Entries section, preceded by `---` + blank line

Approve to write, or revise the text above before proceeding.
```

---

## Summary table

| Tier | Trigger class | Surface | Index line? | Gate required? |
|---|---|---|---|---|
| Status/Event | Bare status (else-route) | PR comment only; NOT project log | No | No — but surface is always PR comment |
| Status/Event | Trigger 2 — irreversible/external event | Project or lab log | No | No |
| Decision | Trigger 1 — load-bearing decision | Project or lab log | Yes | **Yes — hard invariant** |
| Decision | Trigger 3 — direction change/re-scope | Project or lab log | Yes | **Yes — hard invariant** |
