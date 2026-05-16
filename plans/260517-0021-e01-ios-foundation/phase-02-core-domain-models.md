# Phase 02 — Core Domain Models

Context: `plan.md`, BE doc §5, `docs/product/{api-conventions,readings}.md`.

## Overview

Priority: P0. Status: pending.
Pure `Codable` domain types in `SeeTarotCore` mirroring the BE contract.
No UI, no networking. Fully unit-tested.

## Key Insights

- API is camelCase — single `JSONDecoder.api` with DEFAULT key strategy
  (no `.convertFromSnakeCase`).
- `oracleRemaining`: `null` on wire ⇒ unlimited. Model as optional; expose a
  computed `isUnlimited`.
- Error envelope is consistent: `{ error, message?, issues? }`.

## Requirements

Types (per BE doc §5): `SessionUser` (incl `tier`, `subscriptionStatus`,
`subscriptionRenewsAt`, `kofiEmail`, `birthDate`, `timezone`,
`preferredIntent`, `onboardedAt`), `ReadingInput` (Kind/Spread/Intent enums),
`Reading`, `ReadingCard`, `Reflection`, `Quota`, `HistoryPage`/`Row`,
`APIErrorEnvelope` (+ `issues`), `SSEEvent` (name + raw data), SSE payloads
(`SSECard`, `SSEDelta`, `SSEDone`, `SSEError`).

## Architecture

- All `Codable`, `Sendable` where possible, value types.
- Enums use `String` raw values matching BE exactly; add unknown-case tolerance
  for `intent`/`tier` (decode-fallback to avoid breakage on BE additions).
- `JSONDecoder.api` / `JSONEncoder.api` static factories in Core.

## Related Code Files

Create:
- `ios/Packages/SeeTarotCore/Sources/SeeTarotCore/Models/SessionUser.swift`
- `.../Models/Reading.swift` (Reading, ReadingCard)
- `.../Models/Reflection.swift`
- `.../Models/Quota.swift`
- `.../Models/History.swift`
- `.../Models/ReadingInput.swift` (enums)
- `.../Models/APIError.swift` (envelope + issues)
- `.../Models/SSEEvent.swift`
- `.../Coding/JSONCoders.swift`
- `ios/Packages/SeeTarotCore/Tests/SeeTarotCoreTests/*` (round-trip tests)

## Implementation Steps

1. Define enums with raw values + safe unknown fallback.
2. Define structs; keep each file <200 lines (split Models by concern).
3. `JSONCoders.swift`: `.api` decoder/encoder, default keys, ISO8601 where dates
   are strings (BE returns ISO strings — keep as `String`, parse at edges).
4. Unit tests: encode/decode fixtures from BE doc samples; assert
   `oracleRemaining: null` ⇒ `quota.isUnlimited == true`; assert envelope decode
   with/without `message`/`issues`; enum unknown-case fallback.

## Todo List

- [ ] Enums (Kind/Spread/Intent/tier) with unknown fallback
- [ ] All model structs (files <200 lines)
- [ ] `JSONDecoder.api` / `JSONEncoder.api`
- [ ] Round-trip + edge unit tests green

## Success Criteria

`swift test` in `SeeTarotCore` passes; fixtures from BE doc decode; null-quota
and envelope edge cases covered.

## Risk Assessment

- BE wire shape uncertainty (e.g. `subscriptionRenewsAt` type) → model optional,
  tolerate null; note assumptions in test comments; verify in Phase 05/07.

## Security Considerations

- No persistence/secrets here. Models carry no credentials.

## Next Steps

Phase 03 consumes these via the networking layer.
