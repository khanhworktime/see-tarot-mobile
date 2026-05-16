# Phase 06 — DesignSystem & CardEngine Seams

Context: `plan.md`, decision 0004, `docs/product/overview.md` (native + brand).

## Overview

Priority: P1. Status: pending.
`SeeTarotDesignSystem` tokens + primitives; `SeeTarotCardEngine` animation seam
with a Metal ambient-background spike. No real card animation (E02).

## Key Insights

- Design language = native iOS (HIG) + brand accent (decision 0004). Tokens
  now, full motion later.
- CardEngine boundary: SwiftUI hosts a `UIViewRepresentable` seam; Metal is
  scoped to ambient background only — the spike proves 60fps, not the card UX.
- Keep seams minimal (YAGNI): real flip/spread animation is E02.

## Requirements

- `DesignSystem`: color tokens (semantic: background, surface, accent, text),
  typography scale, spacing scale, motion constants; light/dark; brand accent
  asset. Reusable `PrimaryButton`, `TextFieldStyle`, `LoadingView` used to
  restyle Phase 05 screens.
- `CardEngine`: `AmbientBackgroundView` (`UIViewRepresentable` wrapping a
  `MTKView`) rendering a cheap shader (gradient/particles), plus a
  `CardSurface` protocol/placeholder seam for E02.
- A measurable 60fps check for the ambient view (instrumented or manual note).

## Architecture

- `CardEngine` depends on `DesignSystem` (palette feeds shader uniforms).
- Metal: one `.metal` shader, minimal pipeline; gracefully no-op on simulator
  if needed (fallback SwiftUI gradient) so CI/sim build is stable.
- Tokens are values (no singletons) injected via SwiftUI environment.

## Related Code Files

Create:
- `.../SeeTarotDesignSystem/Tokens/Colors.swift`, `Typography.swift`,
  `Spacing.swift`, `Motion.swift`
- `.../Components/PrimaryButton.swift`, `LoadingView.swift`, `Styles.swift`
- `.../Resources/` brand accent color asset
- `.../SeeTarotCardEngine/AmbientBackgroundView.swift`
- `.../SeeTarotCardEngine/Shaders/ambient.metal`
- `.../SeeTarotCardEngine/CardSurface.swift` (seam protocol + stub)
- Update Phase 05 views to consume DesignSystem
- `Tests/SeeTarotDesignSystemTests/*` (token sanity), CardEngine smoke

## Implementation Steps

1. Define token files + environment injection.
2. Build shared components; restyle SignIn/SignUp/Home with tokens.
3. `AmbientBackgroundView` MTKView + minimal shader + SwiftUI fallback.
4. `CardSurface` seam protocol (no impl) documented for E02.
5. Measure ambient fps on device/sim; record note.
6. Token sanity tests; CardEngine view instantiation smoke.

## Todo List

- [ ] Token files + environment injection
- [ ] Shared components; Phase 05 screens restyled
- [ ] AmbientBackgroundView (Metal) + SwiftUI fallback
- [ ] CardSurface seam protocol (E02 contract)
- [ ] 60fps ambient check recorded
- [ ] DesignSystem/CardEngine tests green

## Success Criteria

App uses tokens (no hardcoded colors in Features); ambient background renders
≥60fps (or documented sim fallback); CardEngine builds; tests pass.

## Risk Assessment

- Metal on simulator instability → SwiftUI gradient fallback keeps build/tests
  green; real Metal validated on device.
- Scope creep into real card animation → explicitly deferred to E02 (seam only).

## Security Considerations

- None (presentation only, no data).

## Next Steps

Phase 07 verifies the whole skeleton and updates harness evidence.
