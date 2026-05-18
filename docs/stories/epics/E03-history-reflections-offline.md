# US-E03 History + Reflections + Offline Artwork

## Status

implemented (2026-05-18) — live BE smoke PASSES (history → reading →
reflection echo → visibility round-trip); sim E2E confirms Home→History→Detail
against the running backend. See
`plans/reports/verification-260518-1229-e03-history-reflections-offline.md`.

## Lane

normal (strong validation)

Intake: Public contract (consume-only), New UI surface, Weak proof (new),
contract-reconciliation (Reflection model drift). No hard gate (auth done E01;
no data migration; iOS-only; BE consume-only).

## Product Contract

An authenticated user can browse their **reading history** (cursor-paginated,
newest first), open any past reading to see its full interpretation + card(s),
write **reflections** (journal entries, append-only) on a reading and read
prior ones, and toggle a reading's public visibility. Previously-viewed card
**artwork renders offline** from an on-device cache. Out of scope: AI
personalization (E04), monetization/paywall (E05), Android (E06).

## Relevant Product Docs

- `docs/product/readings.md` (history/reflections behavior, locked v1)
- `docs/product/api-conventions.md` (cursor pagination, error envelopes)
- `docs/product/personalization.md` (reflections are BE-centric per 0005)

## Authoritative Contract (tarot-contract MCP, 2026-05-18)

- `GET /readings?cursor=<ISO8601>&limit=1..50` (default 20) 🔒 →
  `HistoryResponse { items: HistoryRow[], nextCursor: string|null }`.
  `HistoryRow { id, kind(daily|oracle), spread(single|three|celtic),
  intent?, question?, preview, createdAt }`. Cursor = ISO8601 of last
  rendered row; `nextCursor==null` ⇒ end.
- `GET /readings/{id}` 🌐 (public) → full `Reading`.
- `PATCH /readings/{id}` 🔒 `{ isPublic: boolean }` owner-only →
  `ReadingVisibilityResponse`. 400/401/404.
- `POST /readings/{id}/reflect` 🔒 `{ body: 3..2000, mood?: <=24 }` →
  `ReflectionCreateResponse` (created id). 400(issues)/401/404.
- `GET /readings/{id}/reflections` 🔒 →
  `ReflectionsListResponse { items: Reflection[] }`;
  `Reflection { id, body, mood?, createdAt }`.

### Contract drift to reconcile

Core `Reflection` currently has required `readingId` + `userId`; the live
contract `Reflection` is `{ id, body, mood?, createdAt }` only. Decoding the
reflections list would fail. E03 must reconcile Core to the contract (BE
migrating to NestJS — MCP is authoritative). Note in a decision if it changes
0005 assumptions.

## Acceptance Criteria

- History: open History → `GET /readings` first page; infinite scroll appends
  using `nextCursor`; `nextCursor==null` stops; empty state when no rows;
  401 → sign-out (existing seam). Newest-first; row shows kind/spread/preview/
  relative date.
- Detail: tap row → `GET /readings/{id}`; render interpretation + card(s)
  (reuse E02 reading view); 404 → friendly not-found.
- Reflections: detail shows reflections (`GET .../reflections`, newest-first)
  + add form (client mirror: body 3–2000, mood ≤24 optional); `POST .../reflect`
  → optimistic/refetch append; 400 issues surfaced; append-only (no edit/delete).
- Visibility: owner can toggle `isPublic` (`PATCH /readings/{id}`); reflects
  server state; 404/400 handled.
- Offline artwork: card images served from `ArtworkCache`; a previously-viewed
  card renders with no network; cache bounded (simple size cap — revisit note
  from E01 closed).
- Client validation mirrors BE before request. Unit tests (stores + pagination
  + validation + cache) green; app builds; simulator E2E vs live BE.

## Design Notes

- API surface: extend `APIClientProtocol` —
  `history(cursor:limit:) -> HistoryPage`, `reading(id:) -> Reading`,
  `setVisibility(id:isPublic:) -> Bool`,
  `addReflection(id:body:mood:) -> String`,
  `reflections(id:) -> [Reflection]`. Reuse generic `send` where trivial.
- Domain: `HistoryStore` (`@Observable`, cursor state machine
  idle→loading→loaded→paging→end|error), `ReadingDetailStore`,
  `ReflectionsStore` (list + create + validation).
- UI: `HistoryListView` (List + onAppear paging), `ReadingDetailView`
  (reuse E02 card/interpretation rendering), `ReflectionsSection` +
  `AddReflectionView`, visibility toggle in detail. Entry point: Home → History.
- Offline: async card image loader backed by `DiskArtworkCache`
  (network → store → cache-first next time); add bounded eviction (LRU by
  mtime or size cap).
- Reconcile Core `Reflection` to contract shape.
- Stub `StubAPIClient` extended with deterministic history/reflection fixtures
  for unit + offline-UI tests.

## Validation

| Layer | Expected proof |
| --- | --- |
| Unit | HistoryStore pagination (cursor advance / null-stop / error); reflection validation (3–2000, mood≤24); visibility toggle; cache hit/miss + eviction; Reflection decodes contract shape |
| Integration | mock URLProtocol: /readings paging 200, /readings/{id} 200/404, reflect 200/400-issues, reflections 200; ArtworkCache disk round-trip |
| E2E | Sim vs live BE: history loads + scrolls, open reading, add+see reflection, toggle visibility, offline artwork renders (airplane after warm cache) |
| Platform | iOS17 build; smooth scroll; cache survives relaunch |
| Release | full suite + lint before merge |

## Harness Delta

Story sliced from the unsliced E03 row (`TEST_MATRIX`). Surfaces a real
contract drift (Reflection shape) found via tarot-contract MCP — the
cross-repo BE dependency the HARNESS_BACKLOG flagged; MCP now the authoritative
source while BE migrates Fastify→NestJS. Depends on E01 networking/persistence
seams + E02 reading-render components (both `implemented`).

## Evidence

Verified 2026-05-18 —
`plans/reports/verification-260518-1229-e03-history-reflections-offline.md`.
87 tests across 6 packages (live env: 87 pass; no env: 84 pass + 3 live skip),
0 fail; SwiftLint 0 errors/0 warnings; iOS build + sim run clean. Live BE
smoke `LiveHistorySmokeTests` PASSED: real history page → `GET /readings/{id}`
→ `POST /readings/{id}/reflect` echoed back in `GET .../reflections` →
`PATCH /readings/{id}` visibility flip + restore. Sim E2E (live BE): Home →
"Reading history" → live paginated list (newest-first) → detail (card +
interpretation + owner visibility toggle + reflections section + validated add
form). Contract drift reconciled (`Reflection` → `{id,body,mood?,createdAt}`).
Note: live readings return `imageUrl=nil` → `RealCardSurface` placeholder;
offline-artwork cache/eviction is unit-proven (Phase 02) — no warm art to
airplane-test in sim (honest: not faked). Commits 9e760ab (P01), fe09a90
(P02), 34d2b8f (P03), + P04.
