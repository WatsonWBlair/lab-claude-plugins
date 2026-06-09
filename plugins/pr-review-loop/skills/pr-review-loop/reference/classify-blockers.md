# Blocker classification — mechanical vs design-pin

The per-cycle fix loop walks each Blocker through this decision tree to decide whether to auto-fix via `Edit` or to interrupt with `AskUserQuestion`. Conservative default applies: ambiguous Blockers are treated as design pins (false-ask is cheaper than false-auto).

## Decision tree

```
For each Blocker:

  1. Is there a hard rule violation with a single text-level fix?
     (e.g. "commit subject 84 chars, rule says ≤72" → trim subject)
     YES → MECHANICAL
     NO  → continue

  2. Is the Blocker a missing path / missing edge / wording typo / count-of-N inconsistency?
     (e.g. "Files lists handler.py but Acceptance asserts validator.py too"
       → add the missing path)
     YES → MECHANICAL
     NO  → continue

  3. Does the Blocker enumerate 2+ resolution options?
     YES → continue to (4)
     NO  → if a clear simplest-defensible fix exists → MECHANICAL; else DESIGN-PIN

  4. Among the enumerated options, is there one that is OBVIOUSLY the simplest
     AND has no downstream redesign implications?
     YES → MECHANICAL (apply the simplest option)
     NO  → DESIGN-PIN (interrupt with AskUserQuestion)

  5. If still ambiguous → DESIGN-PIN (conservative fall-through)
```

## Mechanical markers

A Blocker is mechanical when any of these apply:

- Hard rule violation with a single text-level fix (commit length, file size limit, anchor format)
- Missing Files path that Acceptance explicitly asserts
- Dead Spec / cross-reference anchor that resolves to a clearly-renamed target
- Missing Depends-on edge that's already discoverable from other declared edges
- Wording typo (singular/plural, count-of-N off by one, repeated word)
- Future-tense reference to a closed item ("closes #N" → "closed-out by #N")
- Section heading level wrong (`##` vs `###`) where the format pins the level
- Two enumerated options where one is the simplest-defensible fix with no downstream redesign

## Design-pin markers

A Blocker is a design pin when any of these apply:

- Option A vs Option B framing where both options have meaningfully different downstream implications (consumer surface change, performance characteristic, CI topology change, schema-shape change)
- "Pin a shape" framing — a vague type or field signature needs to be made concrete and the choice affects multiple consumers
- Conflicting spec interpretations the plan inherited and the spec doesn't pre-resolve
- Acceptance ambiguity affecting more than one task or downstream PR
- Missing consent surface (the fix is "ask the user X" but X is a real choice, not a rubber-stamp)
- The Blocker's prose explicitly says "pick one and make it explicit" or "either X or Y — implementer's choice with downstream impact"

## Conservative fall-through

When in doubt, treat as design-pin. The cost of a false-ask is one `AskUserQuestion` round-trip. The cost of a false-auto is a wrong-fix that the next review pass catches (best case) or that ships silently (worst case). The asymmetry favors asking.

## Worked examples

### Example 1: Mechanical — hard rule, single fix

> "12 of 19 `**Commit:**` subjects exceed the 72-char cap from the commit-message rule. Longest is 84 chars. The rule is unambiguous: 'Under 72 characters.' Mechanical fix — trim adjectives or scope."

**Decision tree walk:**
1. Hard rule with single text-level fix? → YES (rule: ≤72 chars; fix: trim subjects).
2. → MECHANICAL.

**Action:** apply `Edit` to each over-cap commit subject, trimming to ≤72 chars while preserving the load-bearing terms.

**What this teaches the classifier:** when the review prose itself names the fix as "mechanical fix", trust it.

### Example 2: Mechanical — despite three-option framing

> "Task 5 requires a `max_retries` field on the config schema class, but Task 1 doesn't declare it and Task 5 doesn't list `config/models.py` as Modify. Either add `max_retries` to Task 1's schema acceptance, or list `Modify: config/models.py` in Task 5, or remove the field option from Task 5 (and require the params-key route)."

**Decision tree walk:**
1. Hard rule with single text-level fix? → NO (no single rule violated; structural inconsistency between two tasks).
2. Missing path / edge / typo? → CLOSE (missing field declaration is path-adjacent).
3. 2+ resolution options? → YES (three listed).
4. Simplest-defensible with no downstream redesign? → YES (option 1: add the field to Task 1 — additive, no downstream change; option 3 would force the params-key route and rework Task 5's prose, downstream redesign).
4. → MECHANICAL (apply option 1).

**Action:** add `max_retries: int | None = None` to Task 1's schema field list via `Edit`. Reconcile Task 5's Acceptance prose to reference the now-declared field.

**What this teaches the classifier:** don't let "either X or Y or Z" prose fool you when one option is obviously additive and the others require rework. Walk all enumerated options and ask: is there a simplest-defensible one?

### Example 3: Design-pin — options touch a user-facing surface

> "Task 5 Acceptance asserts CI check names that the current `pr.yml` ships differently — and the plan doesn't tell the implementer to split them. Either fix Acceptance to enumerate the three existing jobs + the two new ones (and drop `gitleaks` / `file-size` as separately-named), or explicitly require the split in Acceptance + Files."

**Decision tree walk:**
1. Hard rule with single text-level fix? → NO.
2. Missing path / edge / typo? → NO.
3. 2+ resolution options? → YES.
4. Simplest-defensible with no downstream redesign? → NO. Option 1 (fix Acceptance language) is mechanical-shaped but changes the user-facing CI gate count from 6 to 5. Option 2 (mandate the split) changes CI topology (3 jobs → 5 jobs) and the CI billing surface. Both have downstream implications; neither is clearly safer.
4. → DESIGN-PIN.

**Action:** `AskUserQuestion` with 2-3 defensible options, "(Recommended)" tag on the one matching the existing `pr.yml` topology (option 1).

**What this teaches the classifier:** when the resolution options touch user-facing surfaces (CI topology, consumer API, schema shape), even seemingly-mechanical fixes are design pins.
