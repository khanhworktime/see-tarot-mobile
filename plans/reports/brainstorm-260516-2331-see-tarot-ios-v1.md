# Brainstorm — See Tarot iOS v1

Date: 2026-05-16
Status: Approved (Approach A)

> **Update 2026-05-17:** BE contract supplied
> (`see-tarot-be/docs/api-reference-mobile-swift.md`). Several assumptions
> below were reconciled — see `docs/decisions/0005-be-contract-reconciliation.md`
> and updated `docs/product/*`. Net changes: auth = Better Auth Bearer
> (email/pw + Google, **no Sign in with Apple**); personalization = **BE-centric**
> (no device-only privacy rule); monetization = **free launch, StoreKit
> deferred**; reading = SSE + sync daily; v1 spreads confirmed (daily 1-card,
> oracle 1 & 3-card). Approach A architecture unchanged.

## Problem Statement

See Tarot is a live brand (web `seetarot.com`, app `app.seetarot.com`, BE
`api.seetarot.com`). Goal: native mobile apps (Swift iOS, Kotlin Android) — no
Flutter (animation quality reasons). Priority = best app quality, not coding
speed. App focuses on card spreads ("trải bài") + personalized personal-story.
BE already has card master-data + a tested AI reading module, but NO per-user
personalization module yet. This phase focuses fully on iOS; repo split into
`ios/` and `android/` subfolders.

## Harness Intake

- Input type: New spec.
- Lane: HIGH-RISK. Risk flags: Auth, External systems (StoreKit/Apple),
  Public API contract, Cross-platform, Multi-domain, Weak proof (no contract
  yet). Hard gates: Auth, External provider behavior.

## Scope Decomposition (3 sub-projects)

1. iOS app v1 — focus now.
2. BE personalization module — dependency, separate repo (user splits later).
3. Android app — later, mirrors iOS contract.

Personalization is hybrid and CANNOT be fully completed in iOS alone; iOS v1
designs `PersonalizationProvider` behind an interface and ships with existing
reading.

## Locked Decisions (from user)

| Topic | Decision |
| --- | --- |
| API contract | BE repo not yet available (in a monorepo, user splits later). Design against `APIClientProtocol` + contract doc; stub until real BE. |
| Personalization | Hybrid: BE stores profile/history + server-side personalized prompt; iOS keeps sensitive context on-device (encrypted), sends ephemeral derived context only. |
| iOS UI stack | SwiftUI-first + UIKit/Core Animation for cards + Metal for ambient background only. |
| Auth | Shared BE accounts (token/JWT) + mandatory Sign in with Apple, linked to BE account. |
| v1 scope | Core: auth, 1–3 spreads, AI reading, history, basic personalization. |
| Offline | Cache artwork long-term + view past readings offline; new draw + AI need network. |
| Monetization | StoreKit 2 subscription, BE verifies entitlement (App Store Server Notifications v2). |
| Design language | Native iOS feel (HIG) + brand accents. |

## Approaches Evaluated

- A. SwiftUI + MVVM + SPM modular + Core Animation/Metal — CHOSEN. Native,
  minimal deps (KISS/YAGNI), maintainable, on-trend. Risk: complex card
  animation needs Core Animation skill.
- B. SwiftUI + TCA modular — max testability, steep learning curve + heavy
  dependency, over-needs for consumer tarot app unless team knows TCA.
- C. UIKit + VIPER/Clean — rejected, verbose, over-engineered.

## Chosen Architecture (A)

- SwiftUI + `@Observable` (iOS 17+), thin MVVM.
- Local Swift Packages: `Core`, `Networking` (APIClient protocol, async/await,
  Codable), `Persistence` (SwiftData + Keychain, FileProtection), `DesignSystem`,
  `CardEngine` (Core Animation; Metal for ambient bg), `Features/*` (Auth,
  Spread, Reading, History, Personalization, Paywall).
- Artwork: dedicated immutable disk cache keyed by card id.
- Sensitive personalization context: encrypted on-device, never sent raw; only
  ephemeral derived context per reading.
- Repo: root keeps harness; `ios/` Xcode workspace + SPM; `android/` placeholder.

## Risks

1. Blind API contract — Networking is assumption until BE repo. Mitigation:
   protocol + stub + contract doc, flagged TBD.
2. Missing 3 BE endpoints (Apple link, personalization, StoreKit entitlement)
   block part of v1. Mitigation: BE Dependency Contract handed to BE team early.
3. App Store digital-goods policy — must use IAP, not web billing in-app.
   StoreKit 2 chosen → compliant.
4. Animation scope creep — Metal limited to background; cards Core Animation.

## Success Metrics

iOS v1 runs end-to-end with stub + existing real reading; 60fps on draw/flip;
cold start < 2s; offline replay works; StoreKit sandbox purchase/restore OK;
Sign in with Apple passes App Store review.

## Harness Artifacts Generated

- `docs/product/overview.md`, `api-conventions.md`, `personalization.md`,
  `billing.md`
- `docs/stories/spec-intake-see-tarot.md`
- `docs/stories/epics/E01-ios-foundation/` (overview/design/execplan/validation)
- `docs/stories/backlog.md` updated
- `docs/decisions/0004-native-ios-app-architecture.md`
- `docs/TEST_MATRIX.md` rows added
- `docs/HARNESS_BACKLOG.md` item (cross-repo BE dependency contract gap)

## Open Questions

- Exact endpoint list / auth flow / response envelope of `api.seetarot.com`
  (resolved when BE repo provided).
- Which 1–3 spreads ship in v1 (need product confirmation).
- Subscription tiers/prices and existing web entitlement model.
- Does BE already issue refresh tokens, or only short-lived JWT?

## Next Step

Proceed to `/ck:plan` to produce phased implementation plan for iOS v1
(Approach A), referencing `docs/stories/epics/E01-ios-foundation/`.
