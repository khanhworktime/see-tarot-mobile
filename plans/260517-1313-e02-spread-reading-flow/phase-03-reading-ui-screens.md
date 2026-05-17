# Phase 03 — Reading UI Screens

Context: `plan.md`, phases 01–02, `docs/product/readings.md`, DesignSystem.

## Overview

Priority: P0. Status: pending.
SwiftUI screens wiring stores + flip cards: daily section in Home, Oracle form,
Reading view (reveal + streaming), quota chip. DesignSystem tokens throughout.

## Requirements

- `HomeView` (replace E01 placeholder): authenticated landing — daily card
  section (driven by `DailyReadingStore`), entry to Oracle, `QuotaChip`,
  sign-out. States: loading / card+interpretation / blocked(already drawn) /
  retry(502).
- `OracleFormView`: topic picker (7 intents, iOS copy from a local
  `IntentCopy` map), question `TextEditor` (10–500 counter; `yesNo` requires
  question), spread choice (single/three; celtic hidden), submit (disabled
  until client-valid).
- `ReadingView`: consumes `OracleReadingStore` — `RealCardSurface` flip
  reveals per `card` event, interpretation text streams in (`delta`),
  finalize on `done`; error → retry; `.onDisappear` → `store.stop()`.
- `QuotaChip`: from `Quota` — show daily remaining; oracle count only if
  finite (nil ⇒ "Unlimited", no number).
- `IntentCopy.swift`: label + when-to-offer per `ReadingInput.Intent`.
- Wire `RootView.authenticated` → `HomeView`; navigation to Oracle/Reading.

## Related Code Files

Create (SeeTarotFeatures/Reading/):
- `IntentCopy.swift`, `QuotaChip.swift`, `OracleFormView.swift`,
  `ReadingView.swift`, `DailySection.swift`
Modify:
- `App/HomeView.swift` (real content), `App/RootView.swift` (nav)
Tests:
- `SeeTarotFeaturesTests/IntentCopyTests.swift` (all 7 mapped),
  `QuotaChipModelTests.swift` (null⇒unlimited display string)

## Implementation Steps

1. `IntentCopy` map (all 7 intents) + test.
2. `QuotaChip` + display-model test (finite vs unlimited).
3. `OracleFormView` (validation-driven submit).
4. `ReadingView` (reveal + streaming + cancel on disappear).
5. `DailySection` + `HomeView` real content.
6. `RootView` navigation; keep ambient bg.

## Todo List

- [ ] IntentCopy (7) + test
- [ ] QuotaChip + model test
- [ ] OracleFormView (client validation)
- [ ] ReadingView (reveal/stream/cancel)
- [ ] HomeView daily section + nav
- [ ] `swift test` green; iOS build + sim run; screenshot in Phase 04

## Success Criteria

Authenticated app shows Home w/ daily + quota; oracle form validates; reading
view reveals cards then streams text (stub-driven on sim if no BE); tests
green; build SUCCEEDED.

## Risk / Security

- iOS-only view modifiers guarded for host tests. No secrets. Cancel-on-
  disappear must abort SSE (verify in Phase 04).

## Next

Phase 04 verifies + updates harness.
