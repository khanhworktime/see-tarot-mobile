---
name: project-ui-cosmic-redesign
description: SeeTarot iOS Cosmic Mysticism re-skin epic — scope, seams, hard constraints
metadata:
  type: project
---

UI redesign epic: presentation-only re-skin of all wired iOS surfaces to
"Cosmic Mysticism". Source of truth: `docs/product/ui-design-intake.md`
(accepted 2026-05-19, no open questions). Plan:
`plans/260519-1046-ui-cosmic-redesign/`.

**Why:** stakeholder-accepted brand change request; behavior/contract frozen.

**How to apply:** Re-skins here must NOT touch networking/auth/stores/nav
graph/API contract. Fixed seams: `DesignSystem/Tokens.swift` (keep
environment-injection, not singletons), `CardEngine/CardSurface.swift`
(additive only — never reshape the protocol), `CardEngine/FlipCardView.swift`
+ `RealCardSurface.swift`. Hard constraints: card forced 95/155 (accept
stretch), bg `#010726` screen+card, card name always below card, card back =
runtime-derived `<scheme>://<host>/cards/back.png` from `ReadingCard.imageUrl`,
per-card detail from in-payload `ReadingCard` only (NO per-card endpoint),
particles = SwiftUI TimelineView+Canvas (Metal toolchain ABSENT — never plan
Metal), fonts = bundled Cinzel+Lora ttf via SPM resources (not CDN), celtic
hidden in v1.
