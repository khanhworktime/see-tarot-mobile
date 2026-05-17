# Phase 02 — Card Flip Animation

Context: `plan.md`, decision 0004 (Core Animation, NOT Metal),
`SeeTarotCardEngine/CardSurface.swift` (E01 seam).

## Overview

Priority: P0. Status: pending.
Real `CardSurface` implementation: a 3D card flip (face-down → face-up) via
UIKit/Core Animation bridged into SwiftUI with `UIViewRepresentable`. Replaces
`PlaceholderCardSurface`. 60fps target.

## Requirements

- `FlipCardView: UIViewRepresentable` wrapping a UIKit card view that performs
  a `CATransform3D` Y-axis flip with perspective on `faceUp` change.
- Card front: artwork (AsyncImage-style; nil ⇒ DesignSystem placeholder),
  name, reversed indicator. Back: brand motif (DesignSystem accent).
- `RealCardSurface: CardSurface` returning `FlipCardView`.
- Reduced-motion: honor `UIAccessibility.isReduceMotionEnabled` → cross-fade
  instead of 3D flip.
- Deterministic flip duration from `DesignTokens.motion`.

## Related Code Files

Create (SeeTarotCardEngine/):
- `FlipCardView.swift` (UIViewRepresentable + UIKit card layer)
- `RealCardSurface.swift`
Modify:
- `CardSurface.swift` (keep protocol; mark placeholder preview-only)
Tests:
- `SeeTarotCardEngineTests/CardSurfaceTests.swift` (instantiation, reduced
  motion branch selection — logic-level, not pixel)

## Implementation Steps

1. UIKit `FlipCardUIView`: two faces, `flip(toFaceUp:animated:)` using
   `CATransform3D` (m34 perspective) + `CATransaction` timing.
2. `FlipCardView` UIViewRepresentable bridging `faceUp`/`imageURL`/`reversed`.
3. `RealCardSurface` conforming to seam.
4. Reduced-motion fallback (cross-fade).
5. Tests: surface returns a view; reduced-motion flag chooses fallback path
   (extract decision into a testable pure function).

## Todo List

- [ ] FlipCardUIView (Core Animation 3D flip)
- [ ] FlipCardView UIViewRepresentable
- [ ] RealCardSurface conforms to CardSurface
- [ ] Reduced-motion cross-fade fallback
- [ ] Tests green; iOS build SUCCEEDED; visual check on sim (manual note)

## Success Criteria

Flip renders smoothly (60fps target, manual sim observation noted in Phase 04);
reduced-motion path verified by unit logic; build green. iOS-only API guarded
for host `swift test`.

## Risk / Security

- Core Animation is iOS-only → `#if canImport(UIKit)`; host tests cover pure
  decision logic only. No Metal (decision 0004). No data/secrets.

## Next

Phase 03 wires stores + cards into screens.
