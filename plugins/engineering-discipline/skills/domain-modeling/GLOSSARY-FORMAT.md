# GLOSSARY.md Format

`GLOSSARY.md` is the repo's ubiquitous-language glossary — a first-read AI-tier doc (`.claude/rules/04-docs.md`). The repo's `CLAUDE.md` carries a one-line pointer to it so it loads during coding. It is a glossary and nothing else: no implementation details, no decisions (those go through `/log` to `project_log.md`).

## Structure

```md
# {Repo or subsystem name} — Glossary

{One or two sentence description of what this glossary covers.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does. The glossary is first-read and unbudgeted *only because* its format keeps it lean — don't let it sprawl into prose.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.

## CLAUDE.md pointer

When you first create `GLOSSARY.md`, add a one-line pointer in the repo's `CLAUDE.md` so agents load it as a first-read:

```md
Domain glossary: `GLOSSARY.md` (first-read — load before naming things).
```

## Single vs multi-subsystem repos

**Single glossary (most repos):** one `GLOSSARY.md` at the repo root.

**Multiple subsystems:** keep a root `GLOSSARY.md` for shared, repo-wide terms, and a subsystem `GLOSSARY.md` beside each subsystem's README for terms local to that subsystem (subsystem READMEs are already a named lab-os doc type — `04-docs.md`). The root glossary lists the subsystem glossaries and how the subsystems relate:

```md
## Subsystem glossaries

- [Ordering](./src/ordering/GLOSSARY.md) — receives and tracks customer orders
- [Billing](./src/billing/GLOSSARY.md) — generates invoices and processes payments

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced`; Fulfillment consumes it to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched`; Billing consumes it to generate invoices
```

Infer which glossary applies from the topic; if unclear, ask. Create subsystem glossaries lazily, only when a subsystem accrues its own terms.
