# Phase 05 — Spread Ritual: Shuffle / Fan / Hold-to-Focus / Staggered Deal

## Context Links
- `docs/product/ui-design-intake.md` §Signature/Spread ritual
- `Features/Reading/ReadingView.swift` (ritual host)
- Phase 04 card surface (dependency)

## Overview
- Priority: P2
- Status: done
- Add the ceremonial deck ritual (shuffle → fan → hold-to-focus → release →
  deal + staggered flip) in front of the existing Oracle flow. Presentation
  only — store/state machine untouched.
- **Completion evidence:** SpreadRitualView + RitualCardState + RitualTimeline
  implemented, reduced-motion path (skip hold, crossfade), 30-50ms stagger.
  ReadingView wired to mount ritual during composing/revealing. Built as
  separate components to satisfy SwiftLint 400-line limit (545→398 LOC).

## Key Insights
- `ReadingView` drives off `store.state` (`.composing/.revealing/.done/...`).
  The ritual is a **pre-roll visual** layered before the cards row; it must
  NOT alter `OracleReadingStore` or the submit/stop lifecycle. `store.submit`
  is called in `.task`; ritual visuals run alongside the
  composing/revealing states, gating only WHEN faces flip up.
- Ritual phases: shuffle (riffle/scatter, particle-reactive) → fan (arc out)
  → hold-to-focus (press&hold deck, particles converge while held — the "deep
  breath") → release → deal + sequential flip (3-card: left→right, 30–50ms
  stagger).
- Reduced-motion: SKIP hold beat entirely → go straight to deal (intake
  resolved decision 3). Also collapse shuffle/fan to minimal/crossfade.
- 1-card and 3-card only; build the timeline so a celtic (10) layout is a
  data-driven slot array, but celtic stays hidden (no entry).
- Particle convergence couples to Phase 03 — expose an impulse/hook so
  hold-to-focus can pull particles inward; keep coupling optional (ritual
  still works if bg is static fallback).
- File ownership: ritual = new `SpreadRitualView.swift`; ReadingView edited
  here ONLY for host wiring (mount ritual, feed cards, signal "faces ready").
  Phase 06 edits ReadingView's interpretation render AFTER this lands.

## Requirements
Functional:
- Ordered timeline: shuffle → fan → hold-to-focus → release → deal+flip.
- Hold gesture: press&hold deck; particles converge while held; release
  triggers deal; sequential flip with 30–50ms stagger (3-card L→R).
- Reduced-motion: no hold beat; minimal shuffle/fan; straight to dealt+
  revealed (crossfade via FlipDecision).
- Slot layout data-driven by card count (1 / 3; celtic-ready, hidden).
- Interruptible; never blocks input; no layout shift; cancels cleanly on
  dismiss (ReadingView `.onDisappear` still calls `store.stop()`).

Non-functional:
- Zero change to `OracleReadingStore`/state machine/networking.
- Uses Phase-04 `RealCardSurface`/`FlipCardView` for the actual cards.

## Architecture
Data flow: ReadingView mounts `SpreadRitualView(cards:reduceMotion:)` while
`store.state ∈ {composing,revealing}`. Ritual internal phase enum advances on
its own animation clock; `hold` gesture publishes a converge impulse to the
ambient particle field (optional environment hook). On release → deal
positions cards into spread slots → triggers per-card `faceUp` with stagger
→ hands off to the steady cards row (Phase 06 detail/tap lives there).
Reduced-motion path: phase enum jumps shuffle→dealt.

## Related Code Files
Create:
- `CardEngine/Sources/SeeTarotCardEngine/SpreadRitualView.swift`
- `CardEngine/Sources/SeeTarotCardEngine/SpreadLayout.swift` (slot frames by
  count — pure, testable)
- `CardEngine/Tests/SeeTarotCardEngineTests/SpreadLayoutTests.swift`
Modify:
- `Features/Reading/ReadingView.swift` (host the ritual; replace the plain
  `cards(_:)` HStack mounting with ritual during composing/revealing) — wiring
  only; interpretation text render untouched here (Phase 06 owns that next)

## Implementation Steps
1. `SpreadLayout.slots(count:in:)` pure → CGRect/offsets for 1,3 (+celtic map
   defined but unused). Tests for 1 and 3.
2. `SpreadRitualView`: phase state machine (shuffle/fan/hold/deal/done),
   animation timings from design tokens; renders deck then dealt cards via
   Phase-04 `RealCardSurface`.
3. Hold-to-focus `LongPressGesture`/`DragGesture` while pressed → emit
   converge impulse (env hook to ambient particles; degrade gracefully).
4. Reduced-motion gate (`@Environment(\.accessibilityReduceMotion)`): skip
   hold, collapse shuffle/fan, straight to dealt + crossfade reveal.
5. Stagger reveal 30–50ms L→R for 3-card.
6. Wire into `ReadingView`: mount ritual for composing/revealing; ensure
   `store.submit`/`stop` lifecycle and dismiss-cancel unchanged.
7. Build CardEngine + Features + tests.

## Todo List
- [x] SpreadLayout slots 1/3 (+celtic map) + tests
- [x] SpreadRitualView phase machine (shuffle/fan/hold/deal)
- [x] Hold-to-focus gesture + particle converge hook
- [x] Reduced-motion: skip hold, collapse, crossfade reveal
- [x] 30–50ms staggered L→R flip (3-card)
- [x] ReadingView host wiring; store lifecycle untouched
- [x] Interruptible, no layout shift, dismiss cancels
- [x] CardEngine+Features build + tests pass

## Success Criteria
- [x] Full ritual plays on Oracle reading; reduced-motion skips hold and is
  shift-free.
- [x] `OracleReadingStore` & networking byte-identical (diff shows only view
  wiring).
- [x] 1-card & 3-card layouts correct; celtic absent.

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Ritual desyncs from SSE card arrival | M×H | Ritual is visual pre-roll; flip-up gated by store cards present, not vice-versa |
| ReadingView edit collides w/ Phase 06 | M×M | 06 blocked-by 05; sequential same-file edits, never parallel |
| Hold gesture blocks scroll/input | L×M | Gesture scoped to deck; interruptible; no modal block |
| Particle coupling brittle if bg static | L×L | Optional env hook; ritual works without it |

## Security Considerations
None.

## Next Steps
Unblocks 06 (interpretation + detail compose onto the dealt cards row).
