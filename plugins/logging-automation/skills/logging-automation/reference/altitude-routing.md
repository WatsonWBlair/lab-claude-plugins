# Altitude Routing Reference

Source of truth: `lab-os/.claude/rules/03-logging.md` § Log altitudes. This file restates that section operationally for the `logging-automation` skill. Do not treat this file as authoritative — verify changes against the owning source.

---

## Altitude table

| Altitude | Anchor file | Contents |
|---|---|---|
| Lab | `<DEV_ROOT>/project_log.md` | Cross-repo: tooling, infra, conventions, lab formation |
| Project | `<repo>/project_log.md` | Decisions outliving any one plan; irreversible/external events; direction changes |
| Plan-execution | `## Execution Log` section in the plan doc | Plan deviations, implementation calls, gate evidence; archives with the plan |

`<DEV_ROOT>` = `C:/Users/watso/Development`

---

## Decision test (apply in order)

1. **Cross-repo?** (event touches more than one repo, or concerns lab-wide tooling/infra/conventions) → **lab** altitude.
2. **Matters after the plan ships?** (load-bearing decision, irreversible event, direction change) → **project** altitude.
3. **Only how the plan ran?** (deviation from approved plan, implementation call, gate evidence) → **plan-execution** altitude (`## Execution Log` in the plan doc).

These tests are mutually exclusive in priority order: cross-repo supersedes the other two; plan-execution applies only when the event has no life beyond the plan itself.

---

## Invocation-context resolution

Given an invocation, the skill determines which file to write as follows:

### 1. Inside a known lab repo (CWD resolves to a repo under `<DEV_ROOT>`)

- Default altitude: **project** → write `<repo>/project_log.md`.
- Override to **lab** if the event is cross-repo → write `<DEV_ROOT>/project_log.md`.
- Override to **plan-execution** if a specific plan doc is in scope AND the event is plan-only (deviation, implementation call, gate evidence) → append to the `## Execution Log` section in that plan doc. An event that outlives the plan routes to project or lab per the decision test — not to the Execution Log.

### 2. Executing a plan (a plan doc path is explicitly identified)

- Apply the decision test first. If the event is plan-only (deviation, implementation call, gate evidence) → write to the `## Execution Log` section of that plan doc. If the event matters after the plan ships (load-bearing decision, irreversible/external event, direction change) → route to **project** altitude (or **lab** if cross-repo); do NOT write to the Execution Log. There is no dual-write.

### 3. Explicitly named target repo

- An explicit `--repo <path>` argument or a named repo in the invocation overrides CWD for altitude resolution.
- Cross-repo test still applies: if the event spans the named repo and another → **lab**.

### 4. Bare session (CWD is not under a known lab repo, and no repo is named)

- Derive `<DEV_ROOT>` from known context (`C:/Users/watso/Development`).
- If altitude resolves to **lab**: write `<DEV_ROOT>/project_log.md`.
- If altitude resolves to **project** but no repo is identifiable: ask once for the target repo path, then write `<repo>/project_log.md`. If the answer is unavailable, draft the entry without applying it and surface the draft to the user.

---

## Lab-altitude caveat

The lab log (`<DEV_ROOT>/project_log.md`) has no git/CI enforcement. The following rules apply and must be enforced by the skill on the honor system:

- **Immutability begins once a newer entry exists.** Entries cannot be edited after a newer entry has been prepended; reversal requires a new entry with `Supersedes:`.
- **Refs are absolute paths/URLs — never a PR#.** The lab log has no associated git history, so PR numbers are meaningless as durable references. Use absolute filesystem paths or full URLs.
- **Archive when adding over cap.** Cap is 15 KB. When the log would exceed cap, oldest entries move to `<DEV_ROOT>/project_log_archive.md` (prepended, order preserved) before the new entry is written.

These constraints differ from project-altitude logs, where PR# is the durable ref and git/CI guards the cap and immutability.

---

## Quick-reference

```
Event cross-repo?           → lab    → <DEV_ROOT>/project_log.md
Matters after plan ships?   → project → <repo>/project_log.md
Only how the plan ran?      → plan-execution → ## Execution Log in plan doc
```

Named repo overrides CWD. Bare session: derive DEV_ROOT or ask once, then draft without applying if still unresolvable.
