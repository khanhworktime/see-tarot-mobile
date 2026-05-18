# Verification Report — E03 History + Reflections + Offline Artwork

Date: 2026-05-18
Plan: `plans/260518-1229-e03-history-reflections-offline/`
Lane: normal (strong validation)

## Result

E03 **implemented**. Unit/integration green across 6 packages, lint clean, iOS
build + sim run clean, and a live BE smoke proves the real contract end-to-end
(history → reading → reflection echo → visibility round-trip). Sim E2E confirms
the UI against the running backend. Contract drift surfaced via the
tarot-contract MCP was reconciled (not worked around). No faked green.

## Evidence

### Tests (host `swift test`, all packages)

| Package | Tests | Result |
| --- | --- | --- |
| SeeTarotCore | 17 | pass (+3 ReflectionDecodeTests) |
| SeeTarotNetworking | 16 | pass (+6 HistoryEndpointsTests) |
| SeeTarotPersistence | 10 | pass (+6 ArtworkCacheLoaderTests) |
| SeeTarotDesignSystem | 4 | pass |
| SeeTarotCardEngine | 7 | pass |
| SeeTarotFeatures | 33 | 30 pass, 3 live skip (no env) |
| **Total** | **87** | live env: 87 pass; no env: 84 pass + 3 skip; 0 fail |

E03-specific: history pagination (advance / null-stop / empty / error),
reflection validation boundaries (2/3/2000/2001, ws-only, mood 24/25),
visibility toggle, 404 not-found, `Reflection` decodes contract shape +
`Reading` still decodes with lean reflections, Live history/reflect/visibility
decode + query construction via MockURLProtocol, cache LRU-by-mtime eviction
(just-written survives), loader cache-hit-no-network / nil-url / offline
fallback / fetch-store-then-offline, cache survives relaunch.

### Live BE smoke (`LiveHistorySmokeTests`, `SEE_TAROT_BASE_URL=:3001`)

PASSED (0.178s): sign-in → `GET /readings` page → `GET /readings/{id}` →
`POST /readings/{id}/reflect` (random marker) → marker echoes back in
`GET /readings/{id}/reflections` → `PATCH /readings/{id}` visibility flip +
restore. Asserts concrete data — cannot pass without hitting the endpoints.

### Build & Lint

- `xcodebuild`/`build_run_sim` iOS Debug → **SUCCEEDED** (clean).
- SwiftLint **0 errors / 0 warnings** (fixed `body_` identifier + large_tuple).

### Sim E2E (XcodeBuildMCP + ios-simulator MCP, live BE :3001)

Home shows new **"Reading history"** entry → `HistoryListView` renders the live
cursor-paginated list newest-first (Nine of Wands, oracle, King of
Pentacles…) → tap row → `ReadingDetailView` renders live `GET /readings/{id}`
(card via `CardImage`, full interpretation, owner `VisibilityToggle`
Private/Make-public, `ReflectionsSection` "No reflections yet", validated
`AddReflectionView` with Save disabled until valid).

## Acceptance Criteria

| Criterion | Status |
| --- | --- |
| History cursor pagination, empty, error, newest-first | met (unit + sim live list) |
| Reading detail + 404 not-found | met (unit + sim live render) |
| Reflections list + add (BE-mirrored validation, append-only) | met (unit + live smoke echo) |
| Visibility toggle owner-only | met (unit + live smoke flip + sim toggle UI) |
| Offline artwork bounded cache | met (Phase 02 unit: eviction + offline serve) |
| Client validation mirrors BE | met (unit boundaries + sim disabled Save) |
| Tests + build + lint green | met |

## Not Attempted / Deferred (documented, not faked)

1. **Sim airplane-mode offline-artwork check** — live readings return
   `imageUrl=nil`, so detail uses the `RealCardSurface` placeholder; there is
   no warm artwork to evict/serve offline in-sim. Offline cache + eviction is
   unit-proven (`ArtworkCacheLoaderTests`: fetch→store→offline-serve, LRU
   eviction). Real-art E2E folds in when BE returns card image URLs.
2. **Sim reflection text-entry** — simulator TextEditor focus via automation
   is unreliable (same limitation noted in E02). The add path is proven by the
   live smoke (real POST + echo) + unit tests, not faked in the screenshot.
3. **Real-device run** — out of scope per user (simulator flow until asked).

## Contract Reconciliation

`Reflection` Core model had required `readingId`+`userId`; live contract
(tarot-contract MCP) is `{id, body, mood?, createdAt}`. Reconciled by removing
the extra fields; `Reading.reflections` decode unaffected (regression test
added). Does not amend decision 0005 (reflections remain BE-centric; only the
wire shape is leaner). `ReflectionCreateResponse {id}` /
`ReadingVisibilityResponse {id,isPublic}` fetched and matched plan assumptions
(no escalation).

## Unresolved Questions

- BE returns `imageUrl=nil` for current readings — confirm whether card art
  URLs are planned (affects offline-artwork real E2E) post NestJS migration.
- Live BE creds remain env-only and shared (admin) — fine for smoke; a
  dedicated test account would isolate reflection/visibility side-effects.
