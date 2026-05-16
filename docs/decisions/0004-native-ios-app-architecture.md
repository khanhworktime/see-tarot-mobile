# 0004 Native iOS App Architecture (SwiftUI + MVVM + SPM Modular)

Date: 2026-05-16

## Status

Accepted

## Context

See Tarot needs native mobile apps. Flutter rejected (animation quality).
Priority: best app quality, not speed. iOS first. App is animation-heavy
(card spreads), needs shared BE auth, hybrid personalization, StoreKit 2
subscription. BE repo not yet available (monorepo, split later).

## Decision

Approach A: SwiftUI-first + `@Observable` thin MVVM, modularized via local
Swift Packages (`Core`, `Networking`, `Persistence`, `DesignSystem`,
`CardEngine`, `Features/*`). Card animation via Core Animation/UIKit bridged
into SwiftUI; Metal limited to ambient background. All BE access behind
`APIClientProtocol` (stub until real BE). SwiftData + Keychain persistence.
Native iOS feel + brand accents. Repo split `ios/` + `android/`.

## Alternatives Considered

1. B — SwiftUI + TCA: max testability but heavy dependency + steep curve,
   over-needs for this app unless team already fluent in TCA.
2. C — UIKit + VIPER/Clean: verbose, against trend, over-engineered.

## Consequences

Positive:

- Minimal dependencies (KISS/YAGNI), maintainable, on-trend.
- Protocol-based networking unblocks dev before BE repo exists.
- Modular SPM enables parallel feature work + reuse for Android contract.

Tradeoffs:

- Complex card animation needs strong Core Animation skill (no framework
  shortcut).
- SwiftData relatively new; accept minor rough edges vs adding GRDB.
- Networking remains assumption until BE repo confirms contract.

## Follow-Up

- Hand BE Dependency Contract (`api-conventions.md`) to BE team early.
- Confirm v1 spread set and subscription tiers with product.
- Revisit if BE contract diverges significantly from assumptions.
