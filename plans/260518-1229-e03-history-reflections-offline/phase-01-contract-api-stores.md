# Phase 01 — Contract Reconcile + API Surface + Stores

## Context Links

- Story: `docs/stories/epics/E03-history-reflections-offline.md`
- Plan: `plan.md`
- Decisions: `0005-be-contract-reconciliation.md`, `0006-bearer-only-no-cookie-client.md`
- Seams: `ios/Packages/SeeTarotNetworking/Sources/SeeTarotNetworking/APIClientProtocol.swift`,
  `LiveAPIClient.swift`, `LiveAPIClient+Readings.swift`, `StubAPIClient.swift`,
  `ios/Packages/SeeTarotCore/Sources/SeeTarotCore/Models/{Reflection,History,Reading,APIError}.swift`
- Store pattern: `SeeTarotFeatures/.../Reading/DailyReadingStore.swift`

## Overview

- **Priority:** P1 (blocks Phase 03; defines all data flow)
- **Status:** planned
- Reconcile Core `Reflection` to the live contract, extend `APIClientProtocol`
  with the 5 E03 methods (Live + Stub), and build the 3 `@Observable` stores
  with pagination/validation state machines + unit tests.

## Key Insights

- **Contract drift (hard):** Core `Reflection` has REQUIRED `readingId` +
  `userId`; live contract `Reflection = {id, body, mood?, createdAt}`. Decoding
  `GET /readings/{id}/reflections` would currently fail. `Reading.reflections`
  is `[Reflection]?` (E02) — reconciliation must not break E02 decode.
- **`HistoryPage` already matches** `HistoryResponse`/`HistoryRow` — reuse, no
  model change. `Reading` already matches `GET /readings/{id}` (E02).
- `LiveAPIClient.send<T>` + `perform` + `ResponseHandler` already map errors
  (incl. 401→`onUnauthorized` sign-out seam, entitlement, http). Reuse — do not
  add bespoke error handling.
- `StubAPIClient.send` is responder-driven but typed reading fixtures are
  fields; extend with deterministic E03 fixtures + per-method result hooks.

## Requirements

Functional:
1. Fetch (FIRST, via tarot-contract MCP `get_schema`) exact shapes of
   `ReflectionCreateResponse` and `ReadingVisibilityResponse`. Record in this
   file before coding.
2. Reconcile `Reflection` to `{id, body, mood?, createdAt}`. Remove `readingId`
   + `userId` (or make optional ONLY if a fetched schema needs them — default:
   remove, per story). Keep `Codable, Identifiable, Equatable, Sendable`.
3. Extend `APIClientProtocol`:
   - `history(cursor: String?, limit: Int) async throws -> HistoryPage`
   - `reading(id: String) async throws -> Reading`
   - `setVisibility(id: String, isPublic: Bool) async throws -> Bool`
   - `addReflection(id: String, body: String, mood: String?) async throws -> String`
   - `reflections(id: String) async throws -> [Reflection]`
4. `LiveAPIClient` impl in new `LiveAPIClient+History.swift` (mirror
   `LiveAPIClient+Readings.swift` pattern; use `send`/`perform`).
5. `StubAPIClient` deterministic fixtures + result hooks for all 5.
6. Stores: `HistoryStore`, `ReadingDetailStore`, `ReflectionsStore`.

Non-functional: files <200 lines; bearer-only (already); newest-first;
client validation mirrors BE.

## Architecture

Data flow (history):
```
HistoryStore.loadFirst()  → client.history(cursor:nil, limit:20)
  → HistoryPage{items,nextCursor} → state=.loaded(rows, nextCursor)
HistoryStore.loadMore()   → guard state==.loaded & nextCursor!=nil
  → client.history(cursor:nextCursor) → append items, update/clear nextCursor
  nextCursor==nil ⇒ state=.end ; error ⇒ .error(retryable)
401 anywhere ⇒ ResponseHandler fires onUnauthorized (existing sign-out seam)
```

`HistoryStore` state machine:
`idle → loading → loaded([Row], nextCursor?) → paging → loaded|end|error`
(empty page on first load with no items ⇒ `.empty`).

`ReflectionsStore`: holds `[Reflection]` (newest-first), `validate(body,mood)`
returning issue list mirroring BE (body 3..2000 trimmed, mood ≤24), `add()`
optimistic-or-refetch (KISS: POST then re-`reflections(id:)` to get canonical
order/id — avoids fabricating createdAt).

`ReadingDetailStore`: `load(id)` → `.loaded(Reading)` | `.notFound` (404) |
`.error`; `toggleVisibility()` → `setVisibility` → update local `isPublic`.

Endpoint construction: query for history via
`Endpoint(path: "readings", method: .GET)` with cursor/limit as query — confirm
`Endpoint`/`RequestBuilder` supports query; if not, append to path string
(`readings?cursor=...&limit=...`, URL-encode cursor).

## Related Code Files

Modify:
- `SeeTarotCore/Sources/SeeTarotCore/Models/Reflection.swift` (reconcile)
- `SeeTarotNetworking/Sources/SeeTarotNetworking/APIClientProtocol.swift` (+5 methods)
- `SeeTarotNetworking/Sources/SeeTarotNetworking/StubAPIClient.swift` (fixtures+hooks)

Create:
- `SeeTarotNetworking/Sources/SeeTarotNetworking/LiveAPIClient+History.swift`
- `SeeTarotFeatures/Sources/SeeTarotFeatures/History/HistoryStore.swift`
- `SeeTarotFeatures/Sources/SeeTarotFeatures/History/ReadingDetailStore.swift`
- `SeeTarotFeatures/Sources/SeeTarotFeatures/History/ReflectionsStore.swift`
- Tests: `SeeTarotNetworkingTests` (Live decode via MockURLProtocol; Stub),
  `SeeTarotFeaturesTests/HistoryStoresTests.swift`,
  `SeeTarotCoreTests` Reflection decode (contract shape) — add if Core has tests dir.

Delete: none.

## Implementation Steps

1. tarot-contract MCP `get_schema` for `ReflectionCreateResponse`,
   `ReadingVisibilityResponse`; paste shapes here. If they contradict story
   (e.g. visibility returns object not bool), STOP → escalate (stop condition).
2. Reconcile `Reflection.swift`; grep usages of `.readingId`/`.userId` on
   Reflection across repo; fix/remove. Confirm `Reading.reflections` still
   decodes (E02 fixtures/tests).
3. Add 5 methods to `APIClientProtocol`.
4. `LiveAPIClient+History.swift`: implement via `send`/`perform`; map
   `addReflection` response → created `id`; `setVisibility` → bool from
   `ReadingVisibilityResponse`; history cursor/limit query.
5. `StubAPIClient`: add `historyPages: [HistoryPage]` (or closure),
   `readingResult`, `visibilityResult`, `reflectionsResult`,
   `addReflectionResult` with deterministic defaults.
6. Implement 3 stores following `DailyReadingStore` `@MainActor @Observable`
   pattern; each <200 lines (split if needed).
7. Unit tests: pagination cursor-advance / null-stop / error; reflection
   validation boundaries (2/3/2000/2001 chars, mood 24/25, whitespace-only);
   visibility toggle; 404 not-found; Reflection decodes contract JSON;
   history Live decode via MockURLProtocol (200 + 401).
8. `swift test` per touched package; build.

## Todo List

- [ ] Fetch + record `ReflectionCreateResponse` / `ReadingVisibilityResponse`
- [ ] Reconcile `Reflection`; fix all usages; E02 decode still green
- [ ] Extend `APIClientProtocol` (+5)
- [ ] `LiveAPIClient+History.swift`
- [ ] Extend `StubAPIClient` fixtures + hooks
- [ ] `HistoryStore` / `ReadingDetailStore` / `ReflectionsStore`
- [ ] Unit tests green (pagination, validation, decode, 404/401)
- [ ] `swift test` + build clean

## Success Criteria

- `Reflection` decodes live `{id,body,mood?,createdAt}`; E02 reading decode
  unaffected. 5 methods exist on protocol, Live, Stub. Stores pass pagination
  (advance/null-stop/error), validation (boundary), 404, toggle unit tests.
  All touched packages `swift test` green; builds.

## Risk Assessment

| Risk | L×I | Mitigation |
|---|---|---|
| Fetched response shapes contradict story | M×H | Step 1 first; STOP→escalate per stop condition |
| Removing `readingId`/`userId` breaks E02 `Reading.reflections` decode | M×H | grep all usages; run E02 tests before/after; optionalize only if a fetched schema requires |
| `Endpoint` lacks query support | L×M | Build query into path string + URL-encode cursor (ISO8601 has `:`/`+`) |
| Store files exceed 200 lines | M×L | Split validation into `ReflectionValidation.swift` |

## Security Considerations

- All 5 endpoints `requiresAuth: true` except `GET /readings/{id}` (public 🌐)
  — still send bearer if present (owner gets `isOwner`/reflections context).
- 401 must flow through existing `onUnauthorized` sign-out seam — do not catch
  & swallow. No tokens/PII in logs.

## Next

Unblocks Phase 03 (UI consumes stores). Phase 02 runs independently in parallel.
