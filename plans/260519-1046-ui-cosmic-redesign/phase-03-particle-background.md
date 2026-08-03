# Phase 03 — Reactive Particle Background + Reduced-Motion Fallback

## Context Links
- `docs/product/ui-design-intake.md` §Background, §Risks (perf/battery)
- Seam: `CardEngine/AmbientBackgroundView.swift` (API must stay stable —
  consumed by `RootView`)

## Overview
- Priority: P1
- Status: done
- Replace the gradient ambient bg with a CPU particle starfield (TimelineView
  + Canvas), touch-reactive + slow drift, with a static-gradient fallback for
  reduced-motion / low-power. NO Metal.
- **Completion evidence:** ParticleField + AmbientBackgroundView implemented
  with TimelineView+Canvas, reduced-motion gate, low-power fallback. Particle
  count capped 150, zero per-frame allocations. 60fps cap enforced.

## Key Insights
- `AmbientBackgroundView` is already the single bg seam used by `RootView`
  `.background(AmbientBackgroundView())`. Keep `public init()` + view name
  stable so RootView needs no change here (RootView edits are owned by 07).
- Metal toolchain absent (intake S1776) → `TimelineView(.animation)` +
  `Canvas` only.
- Perf budget: ≥60fps iPhone-12 class → cap particle count (~120–180),
  precompute particle structs, integrate in the timeline tick, no per-frame
  allocations, pause when off-screen (`.onDisappear`/scenePhase).
- Reduced-motion (`@Environment(\.accessibilityReduceMotion)`) AND
  `ProcessInfo.isLowPowerModeEnabled` → static gradient (reuse current
  gradient look retinted to new palette). No layout shift on switch.
- Touch-reactive: a drag/press location nudges nearby particles
  (radial impulse), decays back to drift.

## Requirements
Functional:
- `AmbientBackgroundView` renders particle field over `bg #010726`.
- Slow global drift; touch/press creates local convergence/repel impulse.
- Reduced-motion OR low-power → static gradient (palette-tinted), no Canvas
  ticking.
- Off-screen → pause ticking.

Non-functional:
- ≥60fps on iPhone-12 class (Phase 09 measures).
- Particle count capped; no allocation in draw closure.
- Same public API (`AmbientBackgroundView()` ).

## Architecture
Data flow: `TimelineView(.animation)` tick → `ParticleSystem.advance(dt,
impulse)` mutates a fixed `[Particle]` buffer → `Canvas` draws circles with
`starlight` α by depth. Touch via `DragGesture(minimumDistance:0)` → sets
`impulse` point consumed next tick. Gate: if reduceMotion||lowPower → render
`StaticGradientBackground` instead (no TimelineView mounted).

## Related Code Files
Modify:
- `CardEngine/Sources/SeeTarotCardEngine/AmbientBackgroundView.swift`
Create:
- `CardEngine/Sources/SeeTarotCardEngine/ParticleField.swift`
  (`ParticleSystem` value type + `Particle` + `StaticGradientBackground`)
- `CardEngine/Tests/SeeTarotCardEngineTests/ParticleSystemTests.swift`
  (pure simulation: advance is deterministic, count capped, impulse decays)

## Implementation Steps
1. Define `Particle` (pos, vel, radius, depth/α) and `ParticleSystem` with
   `advance(dt:bounds:impulse:)` — pure, testable, no SwiftUI.
2. Implement `StaticGradientBackground` (retint current LinearGradient to new
   palette: `bg`, `bgLayer1`, `accent` low α).
3. Rewrite `AmbientBackgroundView`: gate on
   `accessibilityReduceMotion || ProcessInfo.lowPowerMode`; else
   `TimelineView(.animation) { Canvas { ... } }` with `DragGesture` impulse +
   scenePhase/onDisappear pause.
4. Cap count constant; tune for perf; ensure no allocs in `Canvas` closure.
5. Unit test the simulation (determinism, cap, impulse decay).
6. Build CardEngine + tests.

## Todo List
- [x] Particle + ParticleSystem pure value types
- [x] StaticGradientBackground (palette-tinted)
- [x] AmbientBackgroundView gate + Canvas/TimelineView path
- [x] Touch impulse + off-screen/low-power pause
- [x] Particle count cap + zero-alloc draw closure
- [x] Simulation unit tests green
- [x] CardEngine build + tests pass

## Success Criteria
- Particles drift + react to touch; reduced-motion/low-power shows static
  gradient with identical layout (no shift).
- API unchanged; RootView still compiles untouched.
- Phase 09 confirms ≥60fps + off-screen pause.

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Canvas CPU cost drops below 60fps | M×H | Cap count, no allocs, pause off-screen, profile in 09 |
| Battery drain | M×M | Low-power static fallback; pause when bg not visible |
| Reduced-motion path jank/shift | L×M | Mount static branch without TimelineView; same frame rect |
| API drift breaks RootView | L×H | Keep `AmbientBackgroundView()` signature exactly |

## Security Considerations
None.

## Next Steps
Unblocks 07 (nav hub composes bg). Perf validated in 09.
