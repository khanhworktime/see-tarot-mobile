# Phase 02 — Offline Artwork Cache Eviction + Image Loader

## Context Links

- Story: `docs/stories/epics/E03-history-reflections-offline.md` (Offline AC)
- Plan: `plan.md`
- Seam: `ios/Packages/SeeTarotPersistence/Sources/SeeTarotPersistence/ArtworkCache.swift`
  (protocol `ArtworkCache` + actor `DiskArtworkCache`, NO eviction yet)
- Persistence container: `SeeTarotPersistence/.../PersistenceContainer.swift`
- Consumer (E02 card render): `SeeTarotFeatures/.../Reading/ReadingView.swift`
  uses `RealCardSurface(...).cardView(imageURL:faceUp:position:)`

## Overview

- **Priority:** P1 (independent of P01; blocks P03 image rendering)
- **Status:** planned
- Add bounded eviction to `DiskArtworkCache` and an async card-image loader
  (cache-first → network → store) so a previously-viewed card renders offline.

## Key Insights

- `DiskArtworkCache` is content-addressed by `cardId`, file-protected,
  atomic writes. Comment explicitly says "No eviction in E01 … revisit E03".
- Story says **simple size cap (or LRU by mtime)** — KISS/YAGNI: no DB, no
  index. Use file mtime + total dir size; evict oldest until under cap.
- `ReadingCard.imageUrl` is `String?` and may be nil in live data — loader
  MUST no-op gracefully (return nil → existing `RealCardSurface` placeholder).
- Loader is keyed by `cardId` (cache key) but fetches from `imageUrl`. Cache
  hit must NOT require network or even a URL.

## Requirements

Functional:
1. `DiskArtworkCache` bounded eviction: configurable `maxBytes` (default e.g.
   64 MB). After `store`, if total dir size > cap, delete files by oldest mtime
   until ≤ cap (never delete the just-written file).
2. `store` bumps mtime (touch) so re-viewed cards are "recent" (LRU-by-mtime).
   `data(for:)` SHOULD touch mtime on hit (read = recency) — keep cheap.
3. Async card-image loader (new type, e.g. `CardImageLoader`):
   `func image(cardId:String, url:URL?) async -> Data?`
   - cache hit → return cached (no network)
   - miss + url==nil → return nil
   - miss + url → fetch (URLSession, bearer NOT required for static art;
     use a plain ephemeral session) → on success store + return → on failure
     return cached-if-any else nil (offline-tolerant)
4. Expose via `PersistenceContainer` (or composition) so Features can inject it.

Non-functional: actor-isolated, `Sendable`; files <200 lines; no secrets; cap
configurable for tests (tiny cap).

## Architecture

```
CardImageLoader.image(cardId, url)
  ├─ cache.data(cardId)         → hit  ⇒ return (offline-safe)
  ├─ url == nil                 → return nil (placeholder upstream)
  └─ URLSession.data(url)
        ├─ ok   ⇒ cache.store(data, cardId) ⇒ return data
        └─ fail ⇒ cache.data(cardId) ?? nil   (airplane mode → nil → placeholder)

DiskArtworkCache.store(data,id):
  write atomic → setProtection → enforceCap():
    list dir (url, size, mtime) → total>maxBytes ?
      sort mtime asc → delete oldest (skip just-written) until ≤ maxBytes
```

Eviction is invoked synchronously inside the `store` actor call (serialized,
no races). Reads are cheap; mtime touch on read is best-effort
(`try? fm.setAttributes(.modificationDate)`).

## Related Code Files

Modify:
- `SeeTarotPersistence/Sources/SeeTarotPersistence/ArtworkCache.swift`
  (add `maxBytes` init param + `enforceCap()` + mtime touch) — keep <200 lines;
  if tight, split eviction into `ArtworkCacheEviction.swift`.
- `SeeTarotPersistence/.../PersistenceContainer.swift` (expose loader/cache)

Create:
- `SeeTarotPersistence/Sources/SeeTarotPersistence/CardImageLoader.swift`
- Tests: `SeeTarotPersistenceTests` — eviction (cap enforced, oldest first,
  just-written survives), loader (hit no-network, miss+nil, miss+url store,
  offline fallback to cache, offline+no-cache → nil), disk round-trip +
  survives "relaunch" (new instance, same dir).

Delete: none.

## Implementation Steps

1. Add `maxBytes` param to `DiskArtworkCache.init` (default 64 MB).
2. Implement `enforceCap()`: enumerate dir with `resourceValues`
   (`.fileSizeKey`, `.contentModificationDateKey`); sum; if over, sort by
   mtime asc, delete until ≤ cap, never the just-stored file.
3. Touch mtime on `store` (atomic write already sets it) and best-effort on
   `data(for:)` hit.
4. `CardImageLoader` actor/struct wrapping an injected `ArtworkCache` +
   `URLSession` (ephemeral, no cookies — consistent w/ 0006, though art is
   public). Implement the flow above.
5. Wire into `PersistenceContainer` for Features injection.
6. Tests with tiny `maxBytes` (e.g. 300 bytes) + temp dir; URLProtocol mock
   for loader network path; assert no-network on cache hit (fail session).
7. `swift test` SeeTarotPersistence; build.

## Todo List

- [ ] `maxBytes` param + default
- [ ] `enforceCap()` LRU-by-mtime, skip just-written
- [ ] mtime touch on store + read
- [ ] `CardImageLoader` (cache-first, offline-tolerant, nil-url safe)
- [ ] Expose via `PersistenceContainer`
- [ ] Tests: eviction + loader + round-trip + relaunch survive
- [ ] `swift test` + build clean

## Success Criteria

- Cache never exceeds `maxBytes` after stores; oldest evicted first;
  just-written file always survives. Loader returns cached bytes with the
  network session guaranteed-to-fail (proves offline). nil url → nil (no
  crash). Cache survives a fresh `DiskArtworkCache` over same dir.
  `SeeTarotPersistence` `swift test` green.

## Risk Assessment

| Risk | L×I | Mitigation |
|---|---|---|
| Eviction races under concurrent stores | L×M | actor serializes; eviction inside `store` call |
| mtime unreliable on some FS | L×M | atomic write sets mtime; read-touch best-effort only, cap still bounds size |
| Loader couples to bearer/session wrongly | L×M | art is public; use plain ephemeral session, no token |
| `imageUrl` nil in live data → blank cards | M×M | loader returns nil → existing `RealCardSurface` placeholder; covered by test + P04 E2E |
| `ArtworkCache.swift` >200 lines | M×L | split `ArtworkCacheEviction.swift` |

## Security Considerations

- Keep `FileProtectionType.completeUntilFirstUserAuthentication` on stored
  files (existing). Artwork is non-sensitive but card-set could be inferred —
  retain protection. No tokens sent for static art. Sanitize `cardId` path
  (existing `/`→`_`) preserved through touch/evict.

## Next

Unblocks Phase 03 card rendering offline. Independent of Phase 01 — may run in
parallel (distinct package + file ownership).
