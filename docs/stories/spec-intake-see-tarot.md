# Spec Intake — See Tarot Mobile

Date: 2026-05-16

## Source

- User prompt: brainstorm session 2026-05-16 (see
  `plans/reports/brainstorm-260516-2331-see-tarot-ios-v1.md`).
- External reference: live brand `seetarot.com`, `app.seetarot.com`,
  `api.seetarot.com`.

## Project Summary

Native iOS (Swift) + later Android (Kotlin) apps for live See Tarot brand.
Focus: card spreads + personalized personal-story. Reuses existing BE artwork +
AI reading. Best quality over speed. iOS first.

## Candidate Product Docs

| File | Purpose | Source sections |
| --- | --- | --- |
| `docs/product/overview.md` | Product scope, surfaces, v1 capabilities | full prompt |
| `docs/product/api-conventions.md` | Mobile↔BE contract (TBD until BE repo) | BE refs |
| `docs/product/personalization.md` | Hybrid personalization model + privacy rule | personalization ask |
| `docs/product/billing.md` | StoreKit 2 subscription + entitlement | monetization ask |

## Candidate Epics

| Epic | Description | Status |
| --- | --- | --- |
| E01 | iOS foundation: modular SPM skeleton, networking protocol/stub, auth + Sign in with Apple, design system | sliced (high-risk) |
| E02 | Card spread + AI reading flow + animation | unsliced |
| E03 | History + offline cache | unsliced |
| E04 | Personalization (iOS interface; full needs BE module) | unsliced |
| E05 | Subscription (StoreKit 2 + BE entitlement) | unsliced |
| E06 | Android app (mirrors iOS contract) | unsliced |

## Architecture Questions

- Runtime stack: Swift, SwiftUI + UIKit/Core Animation, Metal (ambient bg).
- Product surfaces: iOS (now), Android (later).
- Storage: SwiftData + Keychain + dedicated artwork disk cache.
- External providers: api.seetarot.com, Sign in with Apple, StoreKit 2.
- Deployment target: App Store; iOS 17+.
- Security model: shared BE account + Apple identity; on-device encryption of
  sensitive context; raw sensitive text never leaves device.

## Validation Shape

| Layer | Expected proof |
| --- | --- |
| Unit | domain (spreads, entitlement gating, derived-context), view models |
| Integration | APIClient against stub + (later) real BE; StoreKit sandbox |
| E2E | sign-in → draw → reading → history offline replay |
| Platform | App Store review (Sign in with Apple, IAP), 60fps, cold start <2s |
| Release | full suite + perf smoke before submit |

## Reconciliation (2026-05-17)

BE contract supplied (`see-tarot-be/docs/api-reference-mobile-swift.md`).
Resolved via decision 0005: auth = Better Auth Bearer (email/pw + Google, no
SiwA); personalization = BE-centric; monetization = free launch, deferred; v1
spreads confirmed (daily 1-card, oracle 1 & 3-card). See updated product docs.

## Open Decisions

- BE config items only: `set-auth-token` delivery, Google native redirect URI,
  `Infinity` wire format (verify against live BE).
- Subscription tiers/prices — separate monetization brainstorm (deferred).

## First Story Candidates

- E01 iOS foundation (this intake — high-risk story packet created).

## Harness Delta

- Product docs created. Decision 0004 recorded. E01 high-risk story folder
  created. TEST_MATRIX rows added. HARNESS_BACKLOG item added (cross-repo BE
  dependency contract has no harness home).
