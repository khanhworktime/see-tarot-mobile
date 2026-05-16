# 0005 BE Contract Reconciliation (Real api.seetarot.com)

Date: 2026-05-17

## Status

Accepted (supersedes auth/billing/personalization assumptions in 0004)

## Context

0004 + first product docs were written before the BE contract was available
and made assumptions (custom JWT, mandatory Sign in with Apple, StoreKit 2,
strict on-device-only sensitive text). User supplied the real derived contract:
`see-tarot-be/docs/api-reference-mobile-swift.md`. BE = Fastify + Better Auth
(Bearer) + Drizzle/Postgres. Several assumptions conflicted with reality.

## Decision

Reconcile to the real contract:

1. **Auth**: Better Auth Bearer tokens. v1 = email/password + Google (gated on
   `GET /auth-providers`). Sign in with Apple DROPPED for v1 (no BE endpoint;
   not required by App Store while email/password exists). Token from
   `set-auth-token` header → Keychain; `Authorization: Bearer`; 401 → sign-out.
2. **Personalization**: BE-centric. Profile (`birthDate`, `timezone`,
   `preferredIntent`, `onboardedAt`) and reflections are already server-side.
   On-device is cache only. The "raw sensitive text never leaves device" hard
   rule is REMOVED. Dedicated AI personalization module remains future BE work.
3. **Monetization**: v1 free launch (every authed user effectively `plus`).
   Render quota from `GET /quota`. Ko-fi is server-side only. StoreKit 2
   decision DEFERRED to a later monetization brainstorm.
4. **Onboarding**: real gate — `onboardedAt == null` → onboarding →
   `POST /profile/onboard`.
5. **Reading generation**: SSE stream over `POST /readings/generate`; daily via
   synchronous `POST /readings/daily` (+ `GET /readings/daily-today`).

0004 Approach A (SwiftUI + @Observable MVVM + SPM modular + Core
Animation/Metal) stands unchanged.

## Alternatives Considered

1. Keep mandatory Sign in with Apple → blocked, needs new BE work, not required.
2. Lock StoreKit 2 now → blocked, conflicts with existing Ko-fi/free launch.
3. Strict on-device-only journal → contradicts existing server-side reflections.

## Consequences

Positive:

- v1 unblocked: builds entirely on existing BE endpoints, no new BE work.
- Networking no longer an assumption; contract is concrete.

Tradeoffs:

- No Sign in with Apple in v1 (revisit if Google becomes sole social login).
- Personalization privacy posture is server-side trust, not device-only.
- Monetization undecided (separate brainstorm needed before any paid tier).

## Follow-Up (BE answered 2026-05-17)

- `set-auth-token`: header (Better Auth `bearer()` expected) — verify on live
  build during auth phase. Resolved-pending-verify.
- `oracleRemaining`: `null` on wire when unlimited — RESOLVED. FE: null ⇒
  unlimited.
- Google: FE design assumption = **native idToken flow**; final flow is a BE
  decision in the auth phase (BE has no native config yet). Email/password
  ships regardless; Google sign-in gated on this BE task.
- Schedule monetization brainstorm before introducing paid tier.
