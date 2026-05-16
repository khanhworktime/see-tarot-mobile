# Product Overview — See Tarot Mobile

Spec intake 2026-05-16; reconciled to real BE contract 2026-05-17 (decision
0005). Living contract — update on change.

## What

Native mobile apps for the live See Tarot brand. Web: `seetarot.com`,
`app.seetarot.com`. Backend: `api.seetarot.com` (Fastify + Better Auth +
Drizzle/Postgres; BE temporary, may change). Mobile reuses existing BE artwork,
auth, readings, profile, reflections.

## Who

Existing and new See Tarot users. iOS phase 1; Android later.

## Core Value

1. Card spreads ("trải bài") with high-quality native animation.
2. Personalized personal-story readings (BE-centric; AI personalization module
   is future BE work).

## Surfaces

- iOS — Swift, SwiftUI + UIKit/Metal. Phase 1 focus.
- Android — Kotlin, later, mirrors iOS contract.
- Repo split: `ios/`, `android/`. Root keeps harness.

## Capabilities (v1 Core)

| Capability | Notes |
| --- | --- |
| Auth | Better Auth Bearer. Email/password + Google (gated on `/auth-providers`). No Sign in with Apple. See `api-conventions.md`. |
| Onboarding | `onboardedAt==null` → onboarding → `POST /profile/onboard`. |
| Daily | 1-card daily energy (`kind=daily`, forced `general`). |
| Oracle | 1-card & 3-card, user picks topic + question. See `readings.md`. |
| AI reading | Existing tested BE module via SSE (`/readings/generate`) + sync daily. |
| History | Cursor pagination; offline replay of cached readings. |
| Reflections | Server-side journal on a reading (append-only). |
| Personalization | BE-centric: profile + reflections. See `personalization.md`. |
| Quota/tier | Rendered from `GET /quota`; free launch (everyone `plus`). |
| Monetization | Deferred — `billing.md`. No StoreKit in v1. |
| Offline | Cached artwork + past readings. New draw + SSE need network. |

## Non-Goals (v1)

- Android implementation.
- Full parity with `app.seetarot.com`.
- Sign in with Apple; StoreKit/paid tiers; dedicated AI personalization module.
- Web/Ko-fi billing inside the app.

## BE Status

Contract now concrete from `see-tarot-be/docs/api-reference-mobile-swift.md`
(BE temporary, future guide expected). No new BE work required for v1; open
items are BE config/verification only (see `api-conventions.md` open questions).
