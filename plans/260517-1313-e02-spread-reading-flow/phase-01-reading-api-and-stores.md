# Phase 01 — Reading API Surface + Stores

Context: `plan.md`, BE doc §3.2–3.3 §4 §5, `docs/product/readings.md`.

## Overview

Priority: P0. Status: pending.
Extend the API client with reading methods and add `@Observable` flow stores
for Daily and Oracle. No UI yet. Stub-driven unit tests.

## Requirements

- Extend `APIClientProtocol` (+ Live + Stub):
  - `dailyToday() async throws -> Reading?` (`204` ⇒ nil)
  - `drawDaily(tz: String) async throws -> Reading`
  - `quota() async throws -> Quota`
  - `generate(_ input: ReadingInput) -> AsyncThrowingStream<SSEEvent,Error>`
    (reuse E01 `stream` over `POST readings/generate`)
- `DailyReadingStore` (`@Observable`): states
  `idle → loading → loaded(Reading) → blocked(code) → failed(retryable)`.
  Flow: dailyToday; nil ⇒ drawDaily(tz=TimeZone.current.identifier);
  map `403 daily_already_drawn` → blocked; `502 ai_failed|ai_empty` → failed.
- `OracleReadingStore` (`@Observable`): states
  `composing → validating → revealing([ReadingCard]) → streaming(text) →
  done(readingId) → failed(retryable) → blocked(code)`.
  Flow: client-validate `ReadingInput`; consume SSE: append `card` events to
  revealed list, accumulate `delta` into interpretation, finish on `done`;
  `error` payload `retryable` → failed. Cancel: hold the `Task`, cancel on
  `stop()` (view dismiss) → stream termination aborts gen.
- `QuotaStore` or computed: expose tier + chips; `oracleRemaining == nil` ⇒
  unlimited (hide count).

## Related Code Files

Create (SeeTarotFeatures/Reading/):
- `ReadingAPI.swift` (protocol extension default impls / endpoint builders)
- `DailyReadingStore.swift`
- `OracleReadingStore.swift`
Modify:
- `SeeTarotNetworking/APIClientProtocol.swift` (+ methods)
- `LiveAPIClient.swift` (+ daily/quota), `StubAPIClient.swift` (+ fixtures)
Tests:
- `SeeTarotFeaturesTests/DailyReadingStoreTests.swift`
- `SeeTarotFeaturesTests/OracleReadingStoreTests.swift`

## Implementation Steps

1. Add protocol methods; Live impls (daily-today handles 204 via empty-body
   check; generate reuses `stream`). Stub fixtures + configurable SSE script.
2. `DailyReadingStore` state machine.
3. `OracleReadingStore` SSE consumer + cancellation.
4. Unit tests: daily 204→draw→loaded; 403→blocked; 502→failed; oracle invalid
   input; SSE card→delta→done sequence; error retryable; cancel stops stream.

## Todo List

- [ ] APIClientProtocol reading methods (Live + Stub)
- [ ] DailyReadingStore + tests
- [ ] OracleReadingStore (SSE + cancel) + tests
- [ ] Quota exposure (null⇒unlimited)
- [ ] `swift test` SeeTarotFeatures green; app still builds

## Success Criteria

`swift test` green; stub SSE drives oracle store to `done`; daily edge codes
mapped; no UI required; iOS build SUCCEEDED.

## Risk / Security

- SSE shape risk → parse defensively, decode payloads via Core types; STOP if
  BE diverges from §4. No secrets; tokens via existing TokenStoring.

## Next

Phase 02 builds the real card flip animation.
