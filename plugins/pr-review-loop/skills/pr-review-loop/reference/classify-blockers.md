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

## Structural-tag findings (code-quality rubric)

On code-touching PRs the review subagent tags structural findings (`code-quality-rubric.md`). The tag — plus the finding's **age** from the Step 6.5 ledger — refines the mechanical-vs-design-pin call:

### `[regression]` — classify through the tree above, unchanged

A `[regression]` is a hard Blocker every cycle until fixed and carries **no age logic** — feed it straight through the decision tree at the top of this file. A regression with a single text-level fix is mechanical; one whose fix has multiple defensible shapes with downstream cost is a design-pin. The tag only marks it a hard Blocker for the gate; it does **not** add a special classification path.

### `[simplification]` at age 0 — mechanical iff the simpler shape is obvious

The first cycle a simplification is seen it is a Blocker (Step 6.5). Classify it:

- **Obvious extraction / inline / dedup** — a single defensible mechanical move with no downstream redesign (inline a thin wrapper; replace a near-duplicate with the existing canonical helper; extract a repeated block into one helper). → **MECHANICAL** (auto-fix via `Edit`).
- **Real restructure** — reframing a state model, resequencing a flow, collapsing a layer multiple callers traverse: more than one defensible shape, downstream implications. → **DESIGN-PIN** → **exactly one** `AskUserQuestion` (pin b): offer "apply the restructure now" vs "defer it" (+ a middle option if one is clearly defensible). Whatever the answer, the loop does **not** interview this simplification again — if deferred it ages out (Important, then issue).

### `[simplification]` at age ≥ 1 — never interviewed, never auto-refactored

Once a simplification has recurred (age ≥ 1) it has **left the gate** (Step 6.5 demoted it to Important). It is **not** processed by the Step 8 fix loop and **not** picked up by close-out Step 7.2 / 7.3 — it lives only in the `deferred_simplifications` ledger and is **routed to issue filing** at a terminal. Do not classify, interview, or `Edit` it. This is the backoff's "step aside" half: one cycle of real push at age 0, then a tracked issue.

## Worked examples — structural tags

### Example 4: `[simplification]`-trivial → mechanical (age 0)

> "[simplification] `client.ts` — `getUser()` is a one-line wrapper around `api.fetch('/user')` that adds no validation, caching, or error mapping. Inline it; callers can hit `api.fetch` directly."

**Walk:** tag `[simplification]`, age 0 → is the simpler shape obvious? YES — inline a thin wrapper, one defensible move, no downstream redesign. → MECHANICAL.

**Action:** `Edit` to inline the wrapper at its call sites; record in `cycle_fix_log`.

**What this teaches:** an identity abstraction with a single call shape is a mechanical delete, not a pin.

### Example 5: `[simplification]`-restructure → design-pin, then defer (age 0)

> "[simplification] `reducer.ts` — the `pending` / `loading` / `inFlight` booleans this PR adds encode one three-state machine; modeling them as a single `status: 'idle' | 'loading' | 'done'` enum would delete the cross-field invariants the PR now has to defend."

**Walk:** tag `[simplification]`, age 0 → simpler shape obvious? NO — a state-model reframe, multiple call sites read the booleans, more than one defensible target shape. → DESIGN-PIN → one `AskUserQuestion`: "collapse to a `status` enum now" (Recommended if low-risk) vs "defer (file as a follow-up)".

**Action:** apply the chosen option, or — if deferred — make no edit; the entry ages next pass and is **never re-interviewed**.

**What this teaches:** a structural reframe is a pin, not an auto-fix — but it gets **one** ask, not one per cycle. The backoff, not repeated interviews, carries it the rest of the way.

### Example 6: `[simplification]` at age ≥ 1 → issue, no interview

> The same `reducer.ts` finding as Example 5, recurring on pass 2 after the user deferred it.

**Walk:** tag `[simplification]`, age 1 → already demoted to Important by Step 6.5; out of the gate. → **No classification.** It is not fixed and not interviewed; it stays in the ledger and is filed as a `P2-backlog` issue at the next terminal.

**What this teaches:** age, not just tag, decides handling — a recurring simplification is a tracked follow-up, never a fresh interrupt.

### Example 7: `[regression]` → existing tree, unchanged

> "[regression] `pipeline.ts` — this PR routes the export-CSV special case through the shared `serialize()` used by every output format; the `if (format === 'csv')` branch now sits in the canonical path."

**Walk:** tag `[regression]` → feed through the top-of-file tree. Single text-level fix? The fix is "lift the csv branch back to the export-CSV caller" — one structural move, no competing defensible shapes. → MECHANICAL. (Had the fix been "pick one of three places to put it, each with downstream cost", it would be DESIGN-PIN — the same tree as any Blocker.)

**What this teaches:** `[regression]` adds no special path; the tag only marks it a hard Blocker for the gate. Classification stays the ordinary tree.
