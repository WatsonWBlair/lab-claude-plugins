# Entry Format and Standing-Decisions Index Reference

Source of truth: `lab-os/.claude/rules/03-logging.md` § Entry format / § File structure &
overflow, and `lab-os/templates/project_log.template.md` (normative — `log-lint` parses it).
This file restates those grammars operationally. Do not treat this file as authoritative;
verify ambiguities against the owning sources above.

---

## 1. Full project/lab entry grammar

```
## YYYY-MM-DD HH:MM — <subject, one line>

**Decision:** <what was decided/happened>
**Why:** <load-bearing rationale>
**Alternatives:** <only when real ones weighed>
**Supersedes:** <YYYY-MM-DD HH:MM — subject>   <!-- superseding entries only -->
**Refs:** #<PR>, <absolute paths or URLs>
```

Field rules:

- Header delimiter is U+2014 EM DASH (`—`), not a hyphen or en-dash. The exact sequence is
  `## YYYY-MM-DD HH:MM — <subject>` with a space before and after the em-dash.
- `Alternatives:` — omit the field entirely if no real alternatives were weighed; do not write
  "N/A" or leave it blank.
- `Supersedes:` — present only on entries that replace an earlier entry. Format the value as
  the earlier header's date+subject verbatim (e.g. `2026-03-01 09:00 — chose sqlite over
  postgres`). The same PR that adds this entry removes the superseded line from the
  Standing Decisions index.
- `Refs:` — PR# is the durable ref at project/lab altitude. Never use a squash SHA. At lab
  altitude (no CI), use absolute paths or URLs instead of PR#.
- No `Status:` field. Currency is tracked in the Standing Decisions index, not in entries.
- Whole-entry budget: ≤ 1,500 bytes. Content beyond that belongs in the PR body or spec.
- Count-free: no counts that will restale (e.g. "3 alternatives", "2 files changed").

### Concrete synthetic example

```
## 2026-06-18 14:30 — switched log serialiser from JSON to CBOR

**Decision:** logging-automation skill uses CBOR for plan-execution one-liners; JSON for full entries.
**Why:** CBOR halves byte cost for timestamp-heavy payloads; full entries stay human-readable.
**Alternatives:** MessagePack rejected — no native Python stdlib support without a third-party wheel.
**Refs:** #47, C:/Users/watso/Development/lab-claude-plugins/plugins/logging-automation/SKILL.md
```

---

## 2. Ordering and separator rules

- Entries are **reverse-chronological, top-insert**: the newest entry appears first under
  `## Entries`.
- A PR's new entries form **one contiguous block** at the head of the Entries region,
  internally date-ordered (non-strict descending; same-timestamp ties permitted).
- Each entry is preceded by `---` on its own line, then a blank line, then the `## YYYY-MM-DD`
  header. The separator and blank line are load-bearing lint anchors.
- Merge conflicts in the Entries region: keep both blocks, reorder by header timestamp.

Separator pattern (verbatim):

```
---

## YYYY-MM-DD HH:MM — <subject>
```

---

## 3. Standing Decisions index line grammar

The `## Standing Decisions` section holds one line per still-binding decision — hot window
and archive alike. It is the "what is still true" surface; read it before the entries.

Line grammar (exact; `—` is U+2014, `·` is U+00B7 MIDDLE DOT):

```
- YYYY-MM-DD HH:MM — <subject> · #<PR-or-archive-link>
```

Rules:

- Date + subject must match the corresponding entry header **verbatim**. `log-lint` keys index
  lines to entry headers on this string; any mismatch is a lint error.
- Add the index line **in the same PR** as its decision entry. Do not add it in a follow-up PR.
- **Events and plan-execution entries get NO index line.** Only entries triggered by a
  load-bearing decision (trigger 1) or direction change/re-scope (trigger 3) emit an index line;
  irreversible/external events (trigger 2) and all plan-execution one-liners do not.
- When a superseding entry is merged, the same PR removes the superseded line from the index.
  The entry body itself is never edited — only the index line is removed.

Example index line:

```
- 2026-06-18 14:30 — switched log serialiser from JSON to CBOR · #47
```

---

## 4. Plan-execution one-liner grammar

Plan-execution entries live in the `## Execution Log` section of a plan document, not in
`project_log.md`. They use a distinct, compact grammar:

```
YYYY-MM-DD HH:MM · task N · <what happened / why / output>
```

- Delimiter between fields is U+00B7 MIDDLE DOT (`·`), not an em-dash.
- `task N` refers to the plan task number (e.g. `task 3`).
- No `**Decision:**` / `**Why:**` fields — free prose after `task N ·`.
- **No Standing Decisions index line is emitted** for plan-execution entries.
- The plan-execution log closes with the PR that ships the plan; post-merge evidence (deploy
  green, runtime checks, branch cleanup) goes to a PR comment, not a trailing entry.

Example:

```
2026-06-18 15:02 · task 5 · authored entry-format.md; all acceptance bullets verified
```

---

## 5. File cap and overflow (context only)

Whole-file cap: **15 KB**. An entry that pushes the file over cap triggers a CI warning —
it never blocks the PR. Overflow is resolved by a dedicated `chore: archive log overflow` PR
that moves the oldest entries (byte-identical modulo EOL) to `project_log_archive.md`,
prepended as a block, order preserved. The archive is grep-only and cap-exempt; still-binding
archived decisions keep their index lines, re-pointed to the archive location.

This skill surfaces the cap warning as context. Authoring the archive PR is out of scope.

---

## 6. Immutability (summary)

Entries are immutable once their PR merges. Revision = new entry with `Supersedes:`; never
edit the old entry. Factual fixes (e.g. typo'd PR#) require a PR with a `log-lint:override`
label and the reason in the PR body — never a silent edit. Full supersession detail is covered
in the companion reference file for that topic (Task 9).
