# Phase 04 — Persistence & Secure Storage

Context: `plan.md`, story `design.md` (Data Model), `docs/product/readings.md`.

## Overview

Priority: P1. Status: pending.
`SeeTarotPersistence`: Keychain token store (the `TokenStoring` impl),
SwiftData container (placeholder cache entity), artwork disk cache.

## Key Insights

- Networking's `TokenStoring` is satisfied here → keeps layering clean.
- Artwork is immutable, keyed by card id → simple content-addressed disk cache,
  no eviction logic in E01 (YAGNI; revisit E03).
- Reading/history models are NOT persisted in E01 (E02/E03) — only a minimal
  placeholder entity to prove the SwiftData container.

## Requirements

- `KeychainTokenStore: TokenStoring` — read/write/delete `see-tarot.session-token`,
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- `PersistenceContainer` — SwiftData `ModelContainer` with one placeholder
  `@Model CachedFlag` (proves container + migrations path).
- `ArtworkCache` — protocol + disk impl: `data(for cardId)`, `store(_:for:)`,
  files under Caches dir, `.completeUntilFirstUserAuthentication` file
  protection, async, thread-safe.

## Architecture

- `Persistence` depends on `Core` (+ Networking's `TokenStoring` protocol).
- No image decoding here (return `Data`); DesignSystem/Features render.
- Keychain wrapper isolated + unit-testable via a `KeychainAccessing` seam (use
  a fake in tests; real Keychain in an optional device/integration test).

## Related Code Files

Create:
- `.../SeeTarotPersistence/KeychainTokenStore.swift`
- `.../KeychainAccessing.swift` (seam + system impl)
- `.../PersistenceContainer.swift` (+ `CachedFlag` model)
- `.../ArtworkCache.swift` (protocol + `DiskArtworkCache`)
- `Tests/SeeTarotPersistenceTests/*`

## Implementation Steps

1. `KeychainAccessing` protocol + `SystemKeychain` (Security framework).
2. `KeychainTokenStore` conforming to Networking `TokenStoring`.
3. `PersistenceContainer` with SwiftData `ModelContainer` + placeholder model.
4. `DiskArtworkCache` (Caches dir, atomic writes, file protection, actor or
   serial queue for safety).
5. Tests: token store round-trip via fake keychain; container instantiation +
   placeholder insert/fetch; artwork cache store→read→miss.

## Todo List

- [ ] KeychainAccessing seam + system impl
- [ ] KeychainTokenStore (TokenStoring)
- [ ] SwiftData PersistenceContainer + placeholder model
- [ ] DiskArtworkCache with file protection
- [ ] Persistence unit tests green

## Success Criteria

`swift test` passes; token store satisfies Networking protocol; container
opens; artwork cache round-trips and reports misses.

## Risk Assessment

- SwiftData rough edges → keep schema to one trivial model in E01; real models
  deferred so a migration reset is harmless now.

## Security Considerations

- Token in Keychain only, device-only accessibility, never in SwiftData/logs.
- Artwork cache holds no PII (public card art).

## Next Steps

Phase 05 wires Keychain token store + APIClient into the auth flow.
