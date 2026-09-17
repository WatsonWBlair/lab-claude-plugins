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
| `domain-modeling` | `skills/engineering/domain-modeling` | rewired — glossary → `GLOSSARY.md`; ADRs → the main-bundle decision register. Format files renamed: `CONTEXT-FORMAT.md` → `GLOSSARY-FORMAT.md`, `ADR-FORMAT.md` → `DECISION-FORMAT.md` |
| `handoff` | `skills/productivity/handoff` | 1-line edit (ADRs → the decision register) |
| `diagnosing-bugs` | `skills/engineering/diagnosing-bugs` | 1-line edit (CONTEXT.md → GLOSSARY.md, ADRs → the decision register); incl. `scripts/hitl-loop.template.sh` verbatim |
| `codebase-design` | `skills/engineering/codebase-design` | `SKILL.md`, `DEEPENING.md` verbatim; `DESIGN-IT-TWICE.md` 1-line edit |
| `improve-codebase-architecture` | `skills/engineering/improve-codebase-architecture` | `SKILL.md` rewired; `HTML-REPORT.md` 1-line edit |

Not vendored (Matt's process layer that competes with lab-os conventions):
`to-prd`, `to-issues`, `setup-matt-pocock-skills`, `ask-matt`, `prototype`, and the rest of
his repo.

## Lab-os rewire

Matt's skills assume two doc types this lab does not use — `CONTEXT.md` (a per-repo domain
glossary) and `docs/adr/` (Architecture Decision Records). The adaptation maps both onto
surfaces lab-os owns — decisions go straight into the scope's main-bundle decision register
rather than through a separate logging system:

| Matt's construct | Rewired to | Authority |
|---|---|---|
| ADR (record so not re-litigated) | a `§<id>` section in the main-bundle decision register (`_specs/<scope>/main/spec.md`), or the in-flight bundle's `spec.md` if scoped there | `DECISION-FORMAT.md` |
| `docs/adr/` (read before touching area) | the main-bundle decision register at `_specs/<scope>/main/spec.md` | `DECISION-FORMAT.md` |
| "Offer an ADR" | write the `§<id>` section directly, per `DECISION-FORMAT.md` | `domain-modeling` skill |
| `CONTEXT.md` domain glossary | **`GLOSSARY.md`** at repo root — a first-read AI-tier doc, pointed to from `CLAUDE.md` | `.claude/rules/04-docs.md` |
| `CONTEXT-MAP.md` (bounded contexts) | root `GLOSSARY.md` + per-subsystem `GLOSSARY.md` beside subsystem READMEs | `.claude/rules/04-docs.md` |

Matt's ADR three-test (*hard to reverse · surprising without context · result of a real
trade-off*) is carried over unchanged in `DECISION-FORMAT.md`, so the decision-recording
rewire is a destination change, not a behavior change.

### Rules change this adoption required

Choosing a dedicated `GLOSSARY.md` (over folding the glossary into `CLAUDE.md`) required one
line in **`<DEV_ROOT>/.claude/rules/04-docs.md`** registering `GLOSSARY.md` as a first-read
AI-tier doc (domain vocabulary, if present; unbudgeted, kept lean by its format). `04-docs.md`
lives in the dev-home repo, not this plugin repo, so that companion change shipped
separately — dev-home PR #49 (merged).

### Exact edits

- **`domain-modeling/SKILL.md`** — rewritten "Where the model lives" section (glossary →
  `GLOSSARY.md` with a `CLAUDE.md` pointer; decisions → the main-bundle decision register);
  all `CONTEXT.md` references swapped to `GLOSSARY.md`; "Offer ADRs" → "Offer to record
  decisions" per `DECISION-FORMAT.md`.
- **`domain-modeling/GLOSSARY-FORMAT.md`** (was `CONTEXT-FORMAT.md`) — renamed; `CONTEXT.md`
  → `GLOSSARY.md`; DDD "bounded context / `CONTEXT-MAP.md`" framing → lab-os "subsystem
  READMEs"; added the `CLAUDE.md` first-read pointer convention.
- **`domain-modeling/DECISION-FORMAT.md`** (was `ADR-FORMAT.md`) — renamed; `docs/adr/`
  numbering/template → the main-bundle decision register (`_specs/<scope>/main/spec.md`);
  "between contexts" → "between subsystems".
- **`grill-with-docs/SKILL.md`** — description updated (glossary/decisions wording); body
  verbatim.
- **`improve-codebase-architecture/SKILL.md`** — rewritten: intro, Step 1, Step 2
  ("Decision-register conflicts"), Step 3 (offers to record the decision per
  `DECISION-FORMAT.md` instead of an ADR; new domain terms route to `GLOSSARY.md` with the
  lazy-create `CLAUDE.md` pointer, matching `/domain-modeling`). Domain-vocabulary read lists
  across the intro and Steps 1–2 include `GLOSSARY.md` (if present).
- **`improve-codebase-architecture/HTML-REPORT.md`** — "ADR callout" → "decision-register
  callout (… citing the entry by its `§<id>` header)".
- **`codebase-design/DESIGN-IT-TWICE.md`** — brief: "CONTEXT.md vocabulary" → "the repo's
  own domain vocabulary (from its `GLOSSARY.md` if present, `CLAUDE.md`, subsystem READMEs,
  and any active `_specs/` bundle)".
- **`diagnosing-bugs/SKILL.md`** — explore step: `CONTEXT.md` → `GLOSSARY.md`, "check ADRs"
  → "check the main-bundle decision register".
- **`handoff/SKILL.md`** — "don't duplicate … ADRs …" → "… the decision register …".
