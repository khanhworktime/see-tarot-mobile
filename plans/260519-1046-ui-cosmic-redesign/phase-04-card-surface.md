# Phase 04 — Card Surface: Forced 95/155 + Name Label + back.png + 3D Flip + Glow

## Context Links
- `docs/product/ui-design-intake.md` §Hard Constraints, §Signature/Card reveal
- Seams: `CardEngine/FlipCardView.swift`, `RealCardSurface.swift`,
  `CardSurface.swift` (additive only — DO NOT reshape protocol)
- `Features/History/CardImage.swift` (consumes RealCardSurface)

## Overview
- Priority: P1
- Status: done
- Make the single shared flip card honor every card hard constraint: forced
  95/155, `bg #010726` fill, name label below, runtime-derived back.png, 3D
  Y-flip with half-flip silver glow burst, reduced-motion crossfade.
- **Completion evidence:** FlipCardView + RealCardSurface refactored to 95×155,
  name label below card, CardBackURL derivation (runtime /cards/back.png),
  artwork loaded via cache-first loader. 3D flip + glow on .threeDFlip. All
  9 CardBackURLTests pass.

## Key Insights
- `RealCardSurface.cardView` hardcodes `.frame(width:90,height:150)` → must be
  **95×155** (or aspect-locked, fill not letterbox). Back gets identical
  stretch.
- `FlipCardUIView`: back is brand indigo solid (`0.42,0.36,0.78`); must be
  `back.png`. `nameLabel` sits *inside* `frontView` overlapping artwork — but
  intake says name **below** the card (outside the artwork frame). Move the
  name OUT of `FlipCardUIView` into the SwiftUI `RealCardSurface` layout
  (label under the flip frame), so it's visible face-down too if desired and
  never overlaps art.
- `FlipCardUIView.image(for:)` returns `nil` (no loader). Real artwork load is
  needed: derive back URL = `URL` with same scheme+host as `imageUrl`, path
  `/cards/back.png`. Front = `imageUrl`. Use the existing artwork loader path
  used by `CardImage`/`PersistenceContainer.makeArtworkLoader()` — do NOT add
  new networking; reuse the cache-first loader. Pass loaded images in.
- `CardSurface` protocol: `cardView(imageURL:faceUp:position:)`. Reversed/name
  already carried by `RealCardSurface` init — keep. Back-URL derivation is
  internal; protocol unchanged (constraint: additive only).
- `FlipDecision` already gates `.threeDFlip` vs `.crossFade` vs `.none` by
  reduce-motion — reuse; add the glow burst only on `.threeDFlip` at half-flip.
- 95/155 stretch must apply to BOTH faces (`scaleToFill` + clip at 95×155).

## Requirements
Functional:
- Card frame forced to 95×155, `bg #010726` behind art, art fills (accept
  stretch, no letterbox), same stretch on back.png.
- Name label always rendered **below** the card; reversed → label shows
  reversed + artwork rotated 180°.
- Back image = runtime-derived `<scheme>://<host>/cards/back.png` from
  `ReadingCard.imageUrl`.
- 3D Y-flip back→face; silver (`accentBright`) glow burst at half-flip
  threshold; reduced-motion → crossfade (FlipDecision).
- Artwork loaded via existing cache-first loader (no new network).

Non-functional:
- Single shared `FlipCardView` (no duplicate flip impls).
- `CardImage.swift` still compiles (it calls `RealCardSurface`).
- Non-UIKit test target still compiles (degraded branch updated to 95×155).

## Architecture
Data flow: `RealCardSurface(name,reversed)` receives `imageURL` →
derives backURL (scheme+host of imageURL + `/cards/back.png`) → injects both
URLs + loader into `FlipCardView` → `FlipCardUIView` loads front/back images
via loader, draws at 95×155 scaleToFill, 180° transform if reversed →
`setFaceUp` runs FlipDecision style; on `.threeDFlip` overlays a CALayer glow
pulse peaking at half-flip → SwiftUI `RealCardSurface` stacks a `ScrimText`
name label beneath the 95×155 flip frame.

Back-URL derivation: `URLComponents(url:)` keep scheme+host(+port), set
`path="/cards/back.png"`, drop query. If imageUrl nil → no back fetch, show
`bg` fill placeholder (never crash, parity with current CardImage fallback).

## Related Code Files
Modify:
- `CardEngine/Sources/SeeTarotCardEngine/FlipCardView.swift` (95×155, back.png,
  real image load, glow burst, remove in-art label)
- `CardEngine/Sources/SeeTarotCardEngine/RealCardSurface.swift` (95×155 frame,
  name label below, pass backURL+loader)
- `CardEngine/Sources/SeeTarotCardEngine/CardSurface.swift` (additive doc only
  if needed — no protocol reshape)
Create:
- `CardEngine/Sources/SeeTarotCardEngine/CardBackURL.swift` (pure derivation
  helper)
- `CardEngine/Tests/SeeTarotCardEngineTests/CardBackURLTests.swift`
Read for context (no edit):
- `Features/History/CardImage.swift`, `SeeTarotPersistence` artwork loader API

## Implementation Steps
1. Add `CardBackURL.derive(from:URL?) -> URL?` pure helper + tests
   (scheme+host+port preserved, path replaced, nil-safe).
2. Update `RealCardSurface`: frame 95×155; `VStack { flipFrame; name label }`
   using design tokens; pass derived back URL + artwork loader into
   `FlipCardView`; update the non-UIKit degraded branch to 95×155.
3. Update `FlipCardView`/`FlipCardUIView`: accept back URL + loader; remove
   in-art `nameLabel`; both faces `contentMode = .scaleToFill`, clip 95×155;
   reversed → 180° on front art only.
4. Implement real image load using the injected cache-first loader (front +
   back); no direct URLSession.
5. Add half-flip silver glow: a temporary glow layer animated to peak opacity
   at flip midpoint on `.threeDFlip`; skipped on `.crossFade`/`.none`.
6. Verify `CardImage.swift` + ReadingView still compile (callers unchanged).
7. Build CardEngine + Features + tests.

## Todo List
- [x] CardBackURL.derive + tests (scheme/host/port/nil)
- [x] RealCardSurface 95×155 + name label below + loader/backURL wiring
- [x] FlipCardView back.png, scaleToFill both faces, reversed 180°
- [x] Real artwork load via existing cache-first loader (no new net)
- [x] Half-flip silver glow burst (threeDFlip only)
- [x] Reduced-motion crossfade preserved (FlipDecision)
- [x] CardImage/ReadingView still compile; CardEngine+Features build+tests

## Success Criteria
- [x] Card is exactly 95×155, `#010726` fill, art stretched not letterboxed.
- [x] Name always below; reversed shows reversed label + 180° art (post-review fix M1).
- [x] Back = runtime-derived host `/cards/back.png`.
- [x] Flip = 3D + half-flip glow; reduced-motion = crossfade, no layout shift.
- [x] No new network calls (loader reuse only).

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Reshaping CardSurface protocol (forbidden) | M×H | Additive only; carry backURL/loader via RealCardSurface init, not protocol |
| imageUrl nil → no back/front | M×M | bg-fill placeholder, never crash (parity w/ current fallback) |
| Loader API mismatch for back.png (cardId-keyed) | M×M | Key back by synthetic id (e.g. "_back@host") or URL-only load path; confirm loader signature before coding |
| Stretch looks bad | L×L | Stakeholder-accepted; identical on back for consistency |
| In-art→below label move regresses a11y label | L×M | Keep accessibilityLabel on flip frame; add label text below |

## Security Considerations
Back URL derived only from same scheme+host as trusted `imageUrl` — no
arbitrary host. No new endpoints.

## Next Steps
Unblocks 05 (ritual hosts these cards) and 06 (detail sheet + reveal row).
RESOLVED: back.png loads via `CardImageLoader` with synthetic key
`_back@<host>` (cache-first, host derived from `ReadingCard.imageUrl`); no
protocol/seam change. Loader signature concern closed.
