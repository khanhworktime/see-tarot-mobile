# Harness Backlog

Use this file when an agent discovers a missing harness capability but should
not change the operating model immediately.

## Template

```md
## Missing Harness Capability

### Title

Short name.

### Discovered While

Task or story that exposed the gap.

### Current Pain

What was hard, repeated, ambiguous, or unsafe?

### Suggested Improvement

What should be added or changed?

### Risk

Tiny, normal, or high-risk.

### Status

proposed | accepted | implemented | rejected
```

## Items

## Missing Harness Capability

### Title

Cross-repo backend dependency contract

### Discovered While

See Tarot mobile spec intake / E01 iOS foundation. The mobile app depends on
`api.seetarot.com`, whose source lives in a separate (not-yet-available)
monorepo/repo.

### Current Pain

Harness source hierarchy assumes product truth lives in this repo. There is no
defined home for a contract owned by another repo/team that this repo only
consumes. Mitigated for now: the BE repo ships a derived doc
(`see-tarot-be/docs/api-reference-mobile-swift.md`) that `api-conventions.md`
points to as upstream source of truth — but the general harness convention is
still undefined.

### Suggested Improvement

Add a harness convention for external/cross-repo dependency contracts: a
standard doc shape (owner, status verified|assumed, endpoints, open questions)
and an intake rule that flags work blocked on an unverifiable external contract.

### Risk

normal

### Status

proposed

## Missing Harness Capability

### Title

No project validation script (`validate:quick`)

### Discovered While

E01 iOS foundation, phases 01–07.

### Current Pain

`docs/HARNESS.md` defines a Future Validation Ladder but no runnable entry
point exists. Every phase re-derived the same `swift test` / `xcodebuild` /
`swiftlint` commands by hand; the verification phase had to hand-document them
into the story `validation.md`. Repeated manual reasoning + drift risk.

### Suggested Improvement

Add a repo validation entry point (e.g. `scripts/validate-quick.sh` or a
documented command list) that runs per-package `swift test`, the iOS
`xcodebuild`, and `swiftlint`, so phases reference one command instead of
re-deriving. Wire into the harness validation ladder.

### Risk

tiny

### Status

proposed

