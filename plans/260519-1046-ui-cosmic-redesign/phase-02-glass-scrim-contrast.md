# Phase 02 — Glass Surface + Scrim Contrast System

## Context Links
- `docs/product/ui-design-intake.md` §Surfaces, §Risks (low-contrast)
- `DesignSystem/Components.swift`

## Overview
- Priority: P1
- Status: done
- Build a reusable glassmorphic surface primitive whose text content always
  rests on an inner near-opaque scrim guaranteeing ≥4.5:1 contrast.
- **Completion evidence:** GlassSurface + ScrimText implemented, ContrastRatio
  util verifying ≥4.5:1 / ≥3:1 in tests (10/10 PASS), integrated across
  Phases 06/07/08 surfaces.

## Key Insights
- Intake mandates: text never sits directly on blur. Inner scrim = `bg` @
  ≥0.82 under all text; secondary ≥3:1. Verify in-context, both card states.
- Single primitive avoids per-screen contrast bugs (DRY) — every downstream
  phase composes this, not raw `.ultraThinMaterial`.
- `Components.swift` (41 lines) holds `PrimaryButton`/shared bits — extend, do
  not duplicate.
- Contrast must be a measurable acceptance check, not eyeballed: compute
  luminance ratio of `accentBright`/`accentDim` over the scrim composite.

## Requirements
Functional:
- `GlassSurface` view modifier/container: `.ultraThinMaterial` tinted toward
  `bgLayer1`, 1px `accent` hairline, soft outer glow.
- Inner scrim layer: `bg.opacity(≥0.82)` behind any text slot.
- Variants: `glassPanel` (content), `glassCard` (compact), both with scrim.
- Provide `ScrimText` helper so callers can't accidentally place text on bare
  blur.

Non-functional:
- Foreground `accentBright` on scrim ≥4.5:1; `accentDim` ≥3:1 — asserted by a
  unit test computing WCAG ratio from the composited RGB.
- Reused by Phases 06/07/08.

## Architecture
Data flow: caller wraps content in `GlassSurface { ... }` → renders z-stack:
outer glow → material → tint → hairline border → inner scrim
(`bg`@0.82+) → content. Text uses palette `accentBright/accentDim`.

Contrast computation: composite scrim over `bg` (opaque base #010726) →
effective bg RGB → WCAG contrast vs `accentBright`/`accentDim`. Encoded in a
test util `ContrastRatio.wcag(_:over:)`.

## Related Code Files
Modify:
- `DesignSystem/Sources/SeeTarotDesignSystem/Components.swift` (export glass
  helpers, or re-export)
Create:
- `DesignSystem/Sources/SeeTarotDesignSystem/GlassSurface.swift`
- `DesignSystem/Sources/SeeTarotDesignSystem/ContrastRatio.swift` (pure func,
  also used by Phase 09)
- `DesignSystem/Tests/SeeTarotDesignSystemTests/ContrastRatioTests.swift`

## Implementation Steps
1. Add `ContrastRatio.wcag(fg:bg:)` pure function (sRGB → relative luminance →
   ratio). Add `Color` → RGBA extraction helper (UIColor on iOS).
2. Implement `GlassSurface` container with the z-stack above; expose
   `glassPanel`/`glassCard` modifiers.
3. Add `ScrimText` (or `glassText` modifier) binding to palette tokens.
4. Unit test: assert `wcag(accentBright, over: scrimCompositeOverBg) ≥ 4.5`
   and `accentDim ≥ 3.0` for the chosen scrim α.
5. If a ratio fails, raise scrim α until it passes; record final α in the
   file header comment.
6. Build DesignSystem + run tests.

## Todo List
- [x] ContrastRatio pure func + Color RGBA extraction
- [x] GlassSurface (glow/material/tint/hairline/scrim) primitive
- [x] glassPanel / glassCard variants + ScrimText helper
- [x] Contrast unit test green (≥4.5 / ≥3.0)
- [x] Final scrim α documented
- [x] DesignSystem build + tests pass

## Success Criteria
- [x] `ContrastRatioTests` proves ≥4.5:1 primary / ≥3:1 secondary on scrim.
- [x] One reusable primitive; no downstream screen uses bare `.ultraThinMaterial`
  for text (enforced by review in Phases 06–08).

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Scrim α too low → fails contrast | M×H | Test-driven α; bump until passing |
| Material renders differently over particles vs gradient | M×M | Scrim is opaque-enough that backdrop is irrelevant for text; verify Phase 09 over live particles |
| Glow cost on scroll | L×M | Static shadow, no animation; cap blur radius |

## Security Considerations
None.

## Next Steps
Unblocks 06, 07, 08. `ContrastRatio` reused by Phase 09 audit.
