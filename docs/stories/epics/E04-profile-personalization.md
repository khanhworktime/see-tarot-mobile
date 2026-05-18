# US-E04 Profile & Personalization (client)

## Status

planned

## Lane

normal (strong validation)

Intake: Public contract (consume-only), New UI surface, Weak proof (new).
No hard gate (auth done E01; no data migration; iOS-only). AI personalization
itself is **BE-side** (server folds profile + reflections into the prompt —
decision 0005 reconciliation); the client scope here is profile management
only.

## Product Contract

An authenticated user can view and edit their profile — display name, birth
date, timezone, preferred reading intent — which the BE uses server-side to
personalize AI readings (no client AI work). Changes persist via the profile
endpoint and the in-app session reflects them immediately. Onboarding
(`POST /profile/onboard`, E01 seam) already sets the initial birthDate/name;
this story adds ongoing editing. Out of scope: AI prompt logic (BE),
monetization (E05, deferred — decision 0007), Android (E06).

## Relevant Product Docs

- `docs/product/personalization.md` (BE-centric personalization, 0005)
- `docs/product/overview.md`
- Contract: `tarot-contract` MCP (authoritative)

## Authoritative Contract (tarot-contract MCP, 2026-05-18)

- `PATCH /profile` 🔒 `ProfileUpdateSchema` — all optional but **≥1 field
  required** (cross-field): `name` 1–60, `timezone` 1–64,
  `preferredIntent` enum(general|love|career|finances|feeling|action|yesNo),
  `birthDate` `^\d{4}-\d{2}-\d{2}$`. 400 (Zod issues) / 401. →
  `ProfileResponse { id, name?, timezone, preferredIntent?, birthDate? }`.
- Current values: read from `SessionUser` (`GET /auth/get-session`) —
  `name, birthDate, timezone, preferredIntent` already on the model.
- `POST /profile/onboard` `OnboardingSchema { birthDate (required), name? }`
  — already wired (`AuthStore.completeOnboarding`); not re-implemented here.

## Acceptance Criteria

- Profile screen (entry from Home) shows current name / birthDate / timezone /
  preferredIntent from the session user.
- Edit + save → `PATCH /profile` with only changed fields; client mirrors BE
  (≥1 field, name 1–60, timezone 1–64, birthDate `YYYY-MM-DD`, intent enum);
  Save disabled until valid & dirty.
- On success, the in-app session refreshes so Home/onboarding routing and any
  intent defaults reflect new values; 400 `issues[]` surfaced inline; 401 →
  existing sign-out seam.
- Append-only AI behavior unchanged (personalization is BE-side; no client AI).
- Unit tests (validation, dirty-tracking, store state machine, session
  refresh) green; app builds; sim E2E vs live BE; env-gated live smoke.

## Design Notes

- API surface: extend `APIClientProtocol` —
  `updateProfile(name:birthDate:timezone:preferredIntent:) -> SessionUser?`
  (send only non-nil fields; decode `ProfileResponse`, then re-hydrate via
  `getSession`). Live in `LiveAPIClient+History.swift` sibling or a new
  `LiveAPIClient+Profile.swift`.
- AuthStore: add `refreshSession()` (re-`getSession` → `route`) so RootView
  re-renders with the updated `SessionUser`.
- Domain: `ProfileStore` (`@Observable`) — loads from session user, tracks
  dirty fields, `validate()` mirroring BE, `save()` → updateProfile →
  `auth.refreshSession()`.
- UI: `ProfileView` (form: name, date picker→`YYYY-MM-DD`, timezone, intent
  picker reusing `IntentCopy`); Home entry button/route.
- Stub `StubAPIClient` extended with `updateProfileResult`.

## Validation

| Layer | Expected proof |
| --- | --- |
| Unit | ProfileStore validation (name/tz/birthDate/intent bounds, ≥1 required, dirty-tracking), session-refresh path; updateProfile decode |
| Integration | mock URLProtocol: PATCH /profile 200 / 400-issues / 401; getSession re-hydrate |
| E2E | Sim vs live BE: open Profile, edit a field, save, value persists + session reflects it |
| Platform | iOS17 build; sim run |
| Release | full suite + lint before merge |

## Harness Delta

Story sliced from the unsliced E04 row (`TEST_MATRIX`). AI personalization
provider work is BE-side (no client dependency) — this story is profile
management only, so it is not blocked. Builds on E01 auth/session seams +
E03 networking patterns (`implemented`).

## Evidence

(pending — populate on verification per Done Definition; no `implemented`
without live proof)
