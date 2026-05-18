---
title: E03 History + Reflections + Offline Artwork
status: done
lane: normal
created: 2026-05-18
story: docs/stories/epics/E03-history-reflections-offline.md
blockedBy: []
blocks: []
---

# E03 History + Reflections + Offline Artwork — Implementation Plan

Authenticated reading history (cursor-paginated, newest-first), reading detail
with reflections journal (append-only) + visibility toggle, and offline card
artwork from a bounded on-device cache. Builds on E01 networking/persistence
seams + E02 reading-render components (both `implemented`).

## Authoritative Context

- Story (authoritative): `docs/stories/epics/E03-history-reflections-offline.md`
- Contract: live tarot-contract MCP (2026-05-18) — see story §Authoritative Contract
- Decisions: `0004` (SwiftUI + `@Observable` MVVM, iOS17, Core Animation),
  `0005` (BE-contract-reconciliation), `0006` (bearer-only cookie-free client)
- Memory: BE migrating Fastify→NestJS — tarot-contract MCP is authoritative

## Constraints

- iOS 17+. SwiftUI + `@Observable` `@MainActor` stores. Files <200 lines;
  `.swift` PascalCase. No secrets. DRY/KISS/YAGNI — reuse seams, do not recreate.
- Append-only reflections (no edit/delete). Newest-first ordering everywhere.
- Client validation mirrors BE before request (body 3–2000, mood ≤24).
- Out of scope: E04 personalization, E05 monetization, E06 Android.

## Phases

| # | Phase | Status | Output |
|---|-------|--------|--------|
| 01 | [Contract reconcile + API surface + stores](phase-01-contract-api-stores.md) | done | Reflection model reconciled; 5 API methods (Live+Stub); History/Detail/Reflections stores + tests |
| 02 | [Offline artwork cache eviction + image loader](phase-02-artwork-cache-loader.md) | done | Bounded eviction on `DiskArtworkCache`; async card-image loader (network→store→cache-first) + tests |
| 03 | [History/Detail/Reflections UI + Home entry](phase-03-history-detail-ui.md) | done | HistoryListView, ReadingDetailView (reuse E02), ReflectionsSection, AddReflectionView, visibility toggle, Home→History entry |
| 04 | [Verification & harness update](phase-04-verification-harness.md) | done | full swift test, lint, sim E2E vs live BE :3001, TEST_MATRIX/story/plan status, verification report |

## Dependencies

Linear 01→02→03→04. Phase 02 (persistence package, owns
`SeeTarotPersistence/*`) is **independent of Phase 01** (Core + Networking +
Features) — parallelizable if two agents. Phase 03 consumes both 01 (stores)
and 02 (image loader). Phase 04 depends on all.

File ownership (no overlap across parallel work):
- P01: `SeeTarotCore/Models/Reflection.swift`, `SeeTarotNetworking/*`,
  `SeeTarotFeatures/Sources/.../History/*` (stores only)
- P02: `SeeTarotPersistence/Sources/*`
- P03: `SeeTarotFeatures/Sources/.../History/*` (views), `App/HomeView.swift`
- P04: test files + `docs/*` only (reads impl, never edits)

## Success Criteria

- History: open → `GET /readings` page 1; infinite scroll appends via
  `nextCursor`; `null` stops; empty state; 401→sign-out seam; newest-first row
  (kind/spread/preview/relative date).
- Detail: tap row → `GET /readings/{id}`; render interpretation + card(s)
  (reuse E02 `RealCardSurface`/render); 404→friendly not-found.
- Reflections: list newest-first; add form client-mirrors BE (3–2000, mood≤24);
  `POST .../reflect` → refetch/append; 400 `issues[]` surfaced; append-only.
- Visibility: owner toggles `isPublic` via `PATCH /readings/{id}`; reflects
  server state; 404/400 handled.
- Offline: warm-cached card renders with airplane mode on; cache bounded.
- Unit tests (stores + pagination + validation + cache eviction + Reflection
  decode) green; app builds; sim E2E vs live BE :3001.
- `docs/TEST_MATRIX.md` E03 row → evidence; story Status updated.

## Stop Conditions (harness)

Pause and escalate if: live contract for `ReflectionCreateResponse` /
`ReadingVisibilityResponse` (fetched in P01) contradicts story assumptions;
reconciling `Reflection` would break E02 `Reading.reflections` decode in a way
not coverable by optionalizing; client validation would be weakened to pass;
architecture (Approach A / decision 0004) would change; cache eviction needs a
DB/index (must stay file-mtime simple — YAGNI).

## Unresolved Questions

- `ReflectionCreateResponse` and `ReadingVisibilityResponse` exact shapes not
  yet fetched — **Phase 01 first step** fetches via tarot-contract MCP
  `get_schema` before any coding.
- Card image URL host/auth for offline loader: `ReadingCard.imageUrl` is
  optional and may be absent in live data — loader must no-op gracefully when
  nil (placeholder via existing `RealCardSurface`). Confirm during P02/P04.
- Live BE at `localhost:3001` reachability + test creds for sim E2E (same
  blocker class as E01/E02 smoke); unit/stub proof covers logic meanwhile.
- Whether reconciled `Reflection` shape warrants a decision note amending
  `0005` — P01 decides based on fetched schemas.
