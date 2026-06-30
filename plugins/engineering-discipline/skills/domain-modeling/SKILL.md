---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record a load-bearing decision, or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* `GLOSSARY.md` for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## Where the model lives (lab-os conventions)

Two surfaces, both governed by lab-os rules — this skill does not invent a parallel doc system:

- **Glossary → `GLOSSARY.md`** at the repo root: the ubiquitous-language glossary, a first-read AI-tier doc (`.claude/rules/04-docs.md`). The repo's `CLAUDE.md` carries a one-line pointer to it so it loads during coding. Format: [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).
- **Load-bearing decisions → `/log`**: do **not** create a `docs/adr/` tree. When a decision is worth recording, invoke the `/log` skill, which routes it to the `project_log.md` **Standing Decisions** index (durable, repo-level) or the active spec-log (`_specs/<repo>/<DATE>-<handle>/log.md`, bundle-scoped) and applies the `03-logging.md` entry format. When to offer: [DECISION-FORMAT.md](./DECISION-FORMAT.md).

Create files lazily — only when you have something to write. If no `GLOSSARY.md` exists, create one when the first term is resolved, and add the one-line pointer to `CLAUDE.md` at the same time. For multi-subsystem repos, see [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `GLOSSARY.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update GLOSSARY.md inline

When a term is resolved, update `GLOSSARY.md` right there. Don't batch these up — capture them as they happen. Use the format in [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md). If you are creating `GLOSSARY.md` for the first time, add a one-line pointer to it from the repo's `CLAUDE.md` so it loads as a first-read.

`GLOSSARY.md` should be totally devoid of implementation details. Do not treat it as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer to log decisions sparingly

Only offer to record a load-bearing decision (via `/log`) when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

This mirrors `03-logging.md` trigger #1 (load-bearing decision). If any of the three is missing, skip it. See [DECISION-FORMAT.md](./DECISION-FORMAT.md).
