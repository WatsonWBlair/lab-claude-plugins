# Recording a load-bearing decision

lab-os has no `docs/adr/` tree. Architecture and domain decisions are recorded per `.claude/rules/08-bundles.md` §Bundle lifecycle & the main bundle (the register):

- **Durable, repo-level decision** → the scope's **main-bundle decision register** (`_specs/<scope>/main/spec.md` — the ADR-equivalent surface, "what is still true," read first).
- **Scoped to an in-flight planning bundle** → that bundle's `spec.md`, the design authority while it is open; it reaches the register at the fold if it outlives the slice.

The register's shape owns the entry format: a `## Decision summary` row (`# | Question | Resolution | Status`) plus a `### §<id>: <resolution, stated current-state>` section carrying **Why.** (rationale, alternatives rejected), **Contract impact:** (what this binds), and **Landed:** `PR #<n>`. A reversal rewrites the section to the current answer and names what it replaced — there is no frozen row to annotate. Your job is to recognise *when* a decision is worth offering, and to write it in that form with what was decided and why.

## When to offer

All three must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it — you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between subsystems.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer subsystem; other subsystems reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.

## Writing the section

```md
### §<id>: <resolution, stated current-state>
<the resolution — what is true now>
**Why.** <rationale, alternatives rejected>
**Contract impact:** <what this binds>
**Landed:** PR #<n>
```

Add the matching row to the `## Decision summary` table (`| <id> | <question> | <resolution one-liner> | **DECIDED** (§<id>) |`). `<id>` is assigned at the point of recording and is never reused.
