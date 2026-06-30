# Attribution

The skills in this plugin are adapted from **Matt Pocock's "Skills For Real Engineers"**
(<https://github.com/mattpocock/skills>), MIT-licensed (see `LICENSE` — copyright (c) 2026
Matt Pocock). The MIT license is preserved per its terms.

## Vendored skills

| Skill | Origin path in mattpocock/skills | Changed? |
|---|---|---|
| `grill-me` | `skills/productivity/grill-me` | verbatim |
| `grilling` | `skills/productivity/grilling` | verbatim |
| `grill-with-docs` | `skills/engineering/grill-with-docs` | description aligned to lab-os; body verbatim (delegates to `/grilling` + `/domain-modeling`) |
| `domain-modeling` | `skills/engineering/domain-modeling` | rewired — glossary → `GLOSSARY.md`; ADRs → `/log`. Format files renamed: `CONTEXT-FORMAT.md` → `GLOSSARY-FORMAT.md`, `ADR-FORMAT.md` → `DECISION-FORMAT.md` |
| `handoff` | `skills/productivity/handoff` | 1-line edit (ADRs → project_log/spec-log) |
| `diagnosing-bugs` | `skills/engineering/diagnosing-bugs` | 1-line edit (CONTEXT.md → GLOSSARY.md, ADRs → Standing Decisions); incl. `scripts/hitl-loop.template.sh` verbatim |
| `codebase-design` | `skills/engineering/codebase-design` | `SKILL.md`, `DEEPENING.md` verbatim; `DESIGN-IT-TWICE.md` 1-line edit |
| `improve-codebase-architecture` | `skills/engineering/improve-codebase-architecture` | `SKILL.md` rewired; `HTML-REPORT.md` 1-line edit |

Not vendored (Matt's process layer that competes with lab-os conventions):
`to-prd`, `to-issues`, `setup-matt-pocock-skills`, `ask-matt`, `prototype`, and the rest of
his repo.

## Lab-os rewire

Matt's skills assume two doc types this lab does not use — `CONTEXT.md` (a per-repo domain
glossary) and `docs/adr/` (Architecture Decision Records). The adaptation maps both onto
surfaces lab-os owns and delegates decision-recording to the existing `/log` skill
(`logging-automation`):

| Matt's construct | Rewired to | Authority |
|---|---|---|
| ADR (record so not re-litigated) | **Standing Decision** in `project_log.md`, or spec-log entry if bundle-scoped | `.claude/rules/03-logging.md` |
| `docs/adr/` (read before touching area) | **Standing Decisions** index at top of `project_log.md` | `.claude/rules/03-logging.md` |
| "Offer an ADR" | Invoke `/log` — classifies + routes to the right altitude | `logging-automation` skill |
| `CONTEXT.md` domain glossary | **`GLOSSARY.md`** at repo root — a first-read AI-tier doc, pointed to from `CLAUDE.md` | `.claude/rules/04-docs.md` |
| `CONTEXT-MAP.md` (bounded contexts) | root `GLOSSARY.md` + per-subsystem `GLOSSARY.md` beside subsystem READMEs | `.claude/rules/04-docs.md` |

Matt's ADR three-test (*hard to reverse · surprising without context · result of a real
trade-off*) maps almost exactly onto `03-logging.md` trigger #1 (load-bearing decision), so
the decision-recording rewire is a routing change, not a behavior change.

### Rules change this adoption required

Choosing a dedicated `GLOSSARY.md` (over folding the glossary into `CLAUDE.md`) required one
line in **`<DEV_ROOT>/.claude/rules/04-docs.md`** registering `GLOSSARY.md` as a first-read
AI-tier doc (domain vocabulary, if present; unbudgeted, kept lean by its format). `04-docs.md`
lives in the dev-home repo, not this plugin repo, so that companion change shipped
separately — dev-home PR #49 (merged).

### Exact edits

- **`domain-modeling/SKILL.md`** — rewritten "Where the model lives" section (glossary →
  `GLOSSARY.md` with a `CLAUDE.md` pointer; decisions → `/log`); all `CONTEXT.md` references
  swapped to `GLOSSARY.md`; "Offer ADRs" → "Offer to log decisions" via `/log`.
- **`domain-modeling/GLOSSARY-FORMAT.md`** (was `CONTEXT-FORMAT.md`) — renamed; `CONTEXT.md`
  → `GLOSSARY.md`; DDD "bounded context / `CONTEXT-MAP.md`" framing → lab-os "subsystem
  READMEs"; added the `CLAUDE.md` first-read pointer convention.
- **`domain-modeling/DECISION-FORMAT.md`** (was `ADR-FORMAT.md`) — renamed; `docs/adr/`
  numbering/template → `/log` routing to `project_log.md` Standing Decisions / spec-log;
  "between contexts" → "between subsystems".
- **`grill-with-docs/SKILL.md`** — description updated (glossary/decisions wording); body
  verbatim.
- **`improve-codebase-architecture/SKILL.md`** — rewritten: intro, Step 1, Step 2
  ("Standing-Decision conflicts"), Step 3 (offers `/log` instead of an ADR; new domain terms
  route to `GLOSSARY.md` with the lazy-create `CLAUDE.md` pointer, matching `/domain-modeling`).
  Domain-vocabulary read lists across the intro and Steps 1–2 include `GLOSSARY.md` (if present).
- **`improve-codebase-architecture/HTML-REPORT.md`** — "ADR callout" → "Standing-Decision
  callout (… citing the entry by its `YYYY-MM-DD HH:MM — subject` header)".
- **`codebase-design/DESIGN-IT-TWICE.md`** — brief: "CONTEXT.md vocabulary" → "the repo's
  own domain vocabulary (from its `CLAUDE.md`, subsystem READMEs, and any active `_specs/`
  bundle)".
- **`diagnosing-bugs/SKILL.md`** — explore step: `CONTEXT.md` → `GLOSSARY.md`, "check ADRs"
  → "check the `project_log.md` Standing Decisions index".
- **`handoff/SKILL.md`** — "don't duplicate … ADRs …" → "… `project_log.md`/spec-log
  entries …".
