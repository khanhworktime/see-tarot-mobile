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

accepted — interim convention in use: the `tarot-contract` MCP (live BE
OpenAPI) is the authoritative consume-only source while BE migrates
Fastify→NestJS; divergences recorded as decision records.

### Cross-repo dependency status (snapshot 2026-05-18)

| # | Ask | Status |
|---|-----|--------|
| 1 | Card artwork URLs | RESOLVED (BE live) — `imageUrl` now populated, **but `.svg`**; iOS cannot decode SVG at runtime → new client item below |
| 2 | Apple sign-in (App Store 4.8) | RESOLVED — `/auth-providers` `apple:true` live |
| 3 | Error envelope post-NestJS | INTENTIONAL drift — `{message}` (Better Auth) vs `{error,message?,issues?}` (app). Client must handle BOTH (follow-up when wiring social sign-in) |
| 4 | AI personalization | RESOLVED — BE folds profile + 3 reflections into prompt server-side; no client work |
| 5 | Google native sign-in | RESOLVED — `/auth/sign-in/social` `idToken` flow live; success = 200 + `set-auth-token` + user |
| 6 | Monetization | REVERSED — Ko-fi dropped → StoreKit 2 IAP; see decision 0007; implementation deferred |
| 7 | Test account | OPEN — shared `admin` used for smoke; dedicated non-admin + seed/reset still wanted |

New open BE dependency (from #6): published IAP product IDs + entitlement /
ASSN v2 → `/quota` propagation contract (decision 0007).

## Missing Harness Capability

### Title

iOS runtime SVG artwork rendering

### Discovered While

E03 phase 04 verification + the 2026-05-18 BE dependency reconciliation. BE now
serves card artwork as `image/svg+xml` (e.g.
`.../cards/nine-of-wands.svg`, ~440 KB, Illustrator-generated).

### Current Pain

`CardImage` decodes via `UIImage(data:)` / `NSImage(data:)`, which do NOT
render raster SVG from network bytes (SwiftUI `Image` only handles SVG as a
build-time bundled vector asset). So `imageUrl` is now live but cards still
fall back to the `RealCardSurface` placeholder — E03 offline-artwork cannot be
truly proven (cache logic is unit-proven; real render is blocked). Honest gap,
not faked.

### Suggested Improvement

Decide an SVG strategy and add a phase: (a) pure-Swift SVG rasterizer SPM dep
(e.g. SwiftDraw) → `UIImage`, cache the rasterized bytes; (b) ask BE to also
serve PNG/PDF (content-negotiation or `?format=`); or (c) PDF variant
(native). Then wire into `CardImage`/`CardImageLoader` and re-run the E03
offline-artwork E2E (airplane mode).

### Risk

normal

### Status

proposed — awaiting strategy decision (a/b/c)

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

