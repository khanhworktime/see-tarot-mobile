---
title: "SeeTarot iOS Cosmic Mysticism Re-skin"
description: "Presentation-only visual redesign of all wired iOS surfaces to the Cosmic Mysticism brand — no contract/state/nav-graph change."
status: implemented
priority: P2
effort: 38h
branch: main
tags: [ios, swiftui, ui, design-system, re-skin]
created: 2026-05-19
completed: 2026-05-19
---

# SeeTarot iOS Cosmic Mysticism Re-skin

Presentation-only re-skin per `docs/product/ui-design-intake.md`. Implement
exactly the accepted intake — do NOT redesign. No change to networking, auth,
stores, navigation graph, or API contract. Render per-card detail from the
in-payload `ReadingCard`; no per-card endpoint.

## Source of Truth

- `docs/product/ui-design-intake.md` (accepted 2026-05-19, no open questions)

## Implementation Status

Phases 01–08 implemented & code-reviewed. Phase 09 verification gates completed.
Post-review blockers fixed & re-verified: H1 (CardImageLoader wired to ReadingView),
M1 (reversed artwork now rotated via FlipCardView.Coordinator), M5 (InterpretationBlocks
slug de-duplicated + 4 tests added). SpreadRitualView split 545→398 LOC to satisfy
SwiftLint 400 hard limit. Build: xcodebuild clean PASS, 0 errors, 3 known warnings
(pre-existing, non-blocking). Tests: 177/177 PASS repo-wide (~177 incl. DesignSystem
10 ContrastRatio tests, CardEngine 49, Features 56+5 skipped).

**Known Residuals (accepted):** 3 compiler warnings (FlipCardView.swift non-Sendable
closures @MainActor-confined, AmbientBackgroundView.swift onChange deprecation iOS17).
**Deferred v1:** H2 (mid-session Low Power Mode reactivity), M3/M4 (no-host URL guard,
cache-key scheme/port aliasing — low risk dev/staging only).

## Phases

| # | Phase | Status | Effort | Blocked by |
|---|-------|--------|--------|------------|
| 01 | [Design tokens + bundled fonts + color foundation](phase-01-tokens-fonts-color.md) | done | 5h | — |
| 02 | [Glass surface + scrim contrast system](phase-02-glass-scrim-contrast.md) | done | 4h | 01 |
| 03 | [Reactive particle background + reduced-motion fallback](phase-03-particle-background.md) | done | 5h | 01 |
| 04 | [Card surface: forced 95/155 + name label + back.png + 3D flip + glow](phase-04-card-surface.md) | done | 5h | 01 |
| 05 | [Spread ritual: shuffle / fan / hold-to-focus / staggered deal](phase-05-spread-ritual.md) | done | 5h | 04 |
| 06 | [Oracle SSE block magic-reveal + card detail sheet](phase-06-oracle-reveal-detail.md) | done | 5h | 02, 04 |
| 07 | [Immersive nav hub + 4-tab bottom bar + Today/Daily anchor](phase-07-nav-hub-bottom-bar.md) | done | 4h | 02, 03 |
| 08 | [Remaining surfaces re-skin (Auth/Onboarding/Profile/History/Reflections/errors/offline/empty)](phase-08-remaining-surfaces.md) | done | 3h | 02 |
| 09 | [Verification: contrast / reduced-motion / Dynamic Type / perf / build+tests](phase-09-verification.md) | done | 2h | 03,05,06,07,08 |

## Dependency Graph

```
01 ──┬─> 02 ──┬─> 06 ──┐
     │        ├─> 07 ──┤
     ├─> 03 ──┘        ├─> 09
     └─> 04 ──> 05 ────┘
              └─> 06
        02 ──> 08 ──────┘
```

01 is the unblocker for everything. 02/03/04 parallelizable after 01.
05 needs 04. 06 needs 02+04. 07 needs 02+03. 08 needs 02. 09 gates ship.

## File Ownership (no two phases edit the same file)

- **01**: `DesignSystem/Tokens.swift`, `DesignSystem/Package.swift`,
  `DesignSystem/Resources/Fonts/*`, `ios/SeeTarot/Info.plist`
- **02**: `DesignSystem/Components.swift`, new `DesignSystem/GlassSurface.swift`
- **03**: `CardEngine/AmbientBackgroundView.swift`, new
  `CardEngine/ParticleField.swift`
- **04**: `CardEngine/FlipCardView.swift`, `CardEngine/RealCardSurface.swift`,
  `CardEngine/CardSurface.swift` (additive only — no protocol reshape)
- **05**: new `CardEngine/SpreadRitualView.swift`,
  `Features/Reading/ReadingView.swift` (ritual host wiring)
- **06**: `Features/Reading/ReadingView.swift` (block render — sequenced after
  05's wiring), new `Features/Reading/InterpretationBlocks.swift`, new
  `Features/Reading/CardDetailSheet.swift`
- **07**: `Features/App/RootView.swift`, `Features/App/HomeView.swift`, new
  `Features/App/MainTabView.swift`
- **08**: `Features/Auth/*`, `Features/Profile/*`,
  `Features/History/*` (except CardImage which 04 stabilizes),
  `Features/Reading/QuotaChip.swift`, `DailySection.swift`,
  `OracleFormView.swift`
- **09**: no production edits — audit + test only

Note: ReadingView.swift is touched by 05 then 06 sequentially (06 blocked by
05's wiring landing) — never in parallel.

## Key Constraints (carried into every phase)

- bg `#010726` for screen AND card; force 95/155 aspect (accept stretch).
- Card back = `/cards/back.png` derived at runtime from `ReadingCard.imageUrl`
  scheme+host.
- Card name always rendered below card; reversed → label + 180° artwork.
- Glass text sits on inner opaque scrim (`bg` @ ≥0.82) → ≥4.5:1 contrast.
- Particles = SwiftUI TimelineView+Canvas (NO Metal). Static-gradient fallback
  for reduced-motion / low-power. ≥60fps iPhone-12 class.
- Fonts = bundled Cinzel + Lora `.ttf`, scaled via UIFontMetrics. NOT CDN.
- Keep token environment-injection pattern (no singletons).
- Celtic stays hidden v1 (ship 1-card & 3-card only).
