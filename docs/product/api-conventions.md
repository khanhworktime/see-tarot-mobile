# API Conventions — Mobile ↔ api.seetarot.com

Status: CONFIRMED from BE-derived contract. Source of truth:
`see-tarot-be/docs/api-reference-mobile-swift.md` (BE = Fastify + Better Auth +
Drizzle/Postgres). BE marked temporary — re-verify when BE updates / repo split.

## Base URL

Per-build config (Info.plist `API_BASE_URL`), never hardcode. Prod e.g.
`https://api.seetarot.com`, local `http://localhost:3001`.

## Transport

- async/await + `Codable`. Single `JSONDecoder` default key strategy — API is
  already camelCase, do NOT use `.convertFromSnakeCase`.
- All BE access behind `APIClientProtocol` (Networking package). Stub still used
  for unit tests; real impl now concrete (no longer assumption).
- Rate limit: 120 req/min/IP global, 60 for `/auth/*`. Handle `429` w/ backoff.
- Error envelope: non-2xx JSON `{ error, message?, issues? }` (`issues` = Zod
  array on 400).

## Auth (Better Auth, Bearer)

- v1: email/password (always on) + Google (only if `GET /auth-providers` →
  `{google:true}`). No Sign in with Apple (decision 0005).
- Token in `set-auth-token` response header on sign-in/up → Keychain.
  Confirmed as Better Auth `bearer()` plugin expected behavior (src/auth.ts);
  still log full response headers on first `POST /auth/sign-in/email` to verify
  on the real 1.6.3 build.
- Every authed request: `Authorization: Bearer <token>`.
- Session 30d, auto-refresh server-side. `401` → drop token → sign-in.
- Google (design assumption): **native idToken flow** — app gets Google
  idToken via Google SDK, posts to BE; avoids custom-scheme redirect URI. BE
  currently has only web redirect + `trustedOrigins=WEB_ORIGIN`, no native
  config. Final flow is a BE decision made during the auth phase; if BE keeps
  web-redirect instead, BE must add custom scheme/universal link to Google
  Cloud Console + `trustedOrigins`.
- `GET /auth/get-session` user has: `tier`, `subscriptionStatus`,
  `subscriptionRenewsAt`, `kofiEmail`, `birthDate`, `timezone`,
  `preferredIntent`, `onboardedAt` (`onboardedAt==null` → show onboarding).

## Key Endpoints (see BE doc §3 for full)

- Meta: `GET /health`, `/health/db`, `/auth-providers`.
- Auth: `/auth/sign-up/email`, `/auth/sign-in/email`, `/auth/sign-out`,
  `/auth/get-session`, `/auth/sign-in/social?provider=google`.
- Readings: `POST /readings/generate` (SSE), `POST /readings/daily`,
  `GET /readings/daily-today` (204 if none), `GET /readings/:id`,
  `PATCH /readings/:id` (share), `GET /readings` (cursor history).
- Reflections: `POST /readings/:id/reflect`, `GET /readings/:id/reflections`.
- Profile: `PATCH /profile`, `POST /profile/onboard`, `DELETE /account`,
  `GET /quota`.
- Ko-fi: `POST /kofi/claim` (webhook/admin not in app).

SSE detail (`/readings/generate`): `text/event-stream`, events `card` → many
`delta` → `done`|`error`. POST body → use `URLSession.bytes(for:)`, cancel on
dismiss to abort gen. See BE doc §4 + `readings.md`.

## BE Items (resolved 2026-05-17 by BE; verify in auth phase)

- `set-auth-token`: header (Better Auth `bearer()` expected). Verify on live
  1.6.3 build by logging sign-in response headers. — near-certain.
- Google native flow: **BE decision in auth phase.** FE design assumption =
  native idToken flow. Not FE-settleable; track as BE task before Google
  sign-in ships (email/password unblocked regardless).
- `oracleRemaining: Infinity` → `JSON.stringify` → **`null`** on the wire. FE
  rule: `oracleRemaining == null` (or missing) ⇒ unlimited, hide the count;
  show a number only when finite. Still render from `GET /quota`, never
  hardcode (free launch ⇒ almost always `null`). Confirm when hitting live
  endpoint. — resolved.
