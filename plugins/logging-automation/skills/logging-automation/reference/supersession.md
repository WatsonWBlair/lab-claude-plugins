# Supersession and Immutability Reference

Source of truth: `lab-os/.claude/rules/03-logging.md` § Immutability & supersession.
This file restates those rules operationally for the logging-automation skill. Verify
ambiguities against the owning source above.

---

## 1. Immutability rule

Entries are immutable once their PR merges. At the **project altitude** (a repo with git/CI),
immutability is triggered by the PR merge. At the **lab altitude**
(`<DEV_ROOT>/project_log.md`, no CI), immutability begins once a newer entry exists — there
is no PR/merge event to anchor to.

The skill **never proposes an in-place edit of a merged or immutable entry.** If the user
asks to correct or revise an existing entry body, the skill refuses and routes to the
appropriate path below.

---

## 2. Supersession procedure (reversal or revision of meaning)

When a prior decision is reversed or a prior direction-change entry is superseded:

1. **Draft a new entry** using the standard entry grammar (see `entry-format.md` §1).
2. Include the `Supersedes:` field with the superseded entry's header date+subject
   **verbatim** — exact string match, including the em-dash and spacing:

   ```
   **Supersedes:** 2026-03-01 09:00 — chose sqlite over postgres
   ```

3. **In the same change** (same PR at project altitude; same edit at lab altitude), remove
   the superseded entry's line from the **Standing Decisions index**. The entry body itself
   is never touched — only the index line is removed. History keeps both.

4. The skill **refuses to edit the existing entry body.** If asked, it explains this rule
   and offers to draft the new superseding entry instead.

Sharp distinction:

| Situation | Path |
|---|---|
| Reversal or revision of meaning | New entry with `Supersedes:` + remove old index line |
| Factual typo fix (e.g. wrong PR#) | `log-lint:override` route — see §3 |

---

## 3. Factual-fix path (`log-lint:override`)

A typo-only correction (e.g. a wrong PR number in a `**Refs:**` line) is **not** a silent
edit and **not** a new superseding entry — it is neither a reversal of meaning nor a
structural change.

The correct path is a labeled PR:

- PR branch contains only the typo correction in the entry body.
- PR carries the `log-lint:override` label.
- PR body explains the reason (e.g. "corrects PR# in Refs: from #42 to #43; squash SHA was
  used in error, replacing with correct PR#").

The skill surfaces this path and explains it when a factual-only fix is requested. It does
**not** silently apply the correction. It does not draft a new `Supersedes:` entry for a
factual fix — that path is reserved for reversals of meaning.

---

## 4. What the skill does and refuses

| Request | Skill behavior |
|---|---|
| Draft a superseding entry for a reversed decision | Drafts new entry with `Supersedes:` field; flags index-line removal |
| Edit an existing immutable/merged entry body | Refuses; explains immutability; offers to draft a superseding entry |
| Silently correct a typo in a merged entry | Refuses; explains the `log-lint:override` PR route |
| Remove a superseded index line | Performs — only as part of step 3 of the supersession procedure (§2); never as a standalone action |
