# Phase 05 — Auth + Session Bootstrap

Context: `plan.md`, BE doc §2, `docs/product/{api-conventions,personalization}.md`,
decision 0005.

## Overview

Priority: P0 (hard gate: Auth). Status: pending.
`SeeTarotFeatures` Auth: email sign-up/in end-to-end against live BE, launch
session bootstrap, onboarding gate seam, Google seam (no flow).

## Key Insights

- Email/password is the E01 end-to-end proof path. Google = protocol seam +
  hidden/disabled button gated on `/auth-providers` (native idToken flow is a
  BE decision — do NOT build a flow now). NO Sign in with Apple.
- `onboardedAt == null` ⇒ route to onboarding placeholder (real form is E04;
  here it's a seam that calls `POST /profile/onboard` minimally or stubs).
- 401 anywhere ⇒ central sign-out (Networking hook → AuthStore).

## Requirements

- `AuthStore` (`@Observable`): state machine
  `unauthenticated → authenticating → authenticated(needsOnboarding|ready) →
  unauthenticated`. Holds `SessionUser`.
- `AuthService`: `signUp`, `signIn` (capture `set-auth-token` via TokenStore),
  `bootstrap()` (read token → `GET /auth/get-session` → derive state),
  `signOut()`, `loadAuthProviders()`.
- SwiftUI: `SignInView`, `SignUpView` (minimal, validated), `RootView` routing
  by `AuthStore` state, placeholder `HomeView`, placeholder `OnboardingView`
  (seam → `POST /profile/onboard`).
- Wire Networking `onUnauthorized` → `AuthStore.signOut`.
- Live email sign-in smoke (integration test, scheme/env-gated, skipped if no
  test creds) that asserts `set-auth-token` present + session hydrates.

## Architecture

- DI: `AuthService` takes `APIClientProtocol` + `TokenStoring` (Stub in unit
  tests, Live+Keychain in app/smoke).
- App entry calls `AuthStore.bootstrap()` on launch.
- Google: `authProviders()` result toggles a disabled-with-note button;
  protocol method `signInGoogle` exists but throws `notImplemented` in E01.

## Related Code Files

Create:
- `.../SeeTarotFeatures/Auth/AuthStore.swift`
- `.../Auth/AuthService.swift` (split `+Bootstrap` if >200 lines)
- `.../Auth/SignInView.swift`, `SignUpView.swift`
- `.../Auth/OnboardingView.swift` (placeholder seam)
- `.../App/RootView.swift`, `HomeView.swift`
- App: update `SeeTarotApp.swift` to mount `RootView` + bootstrap + DI
- `Tests/SeeTarotFeaturesTests/AuthStateMachineTests.swift`
- `Tests/.../LiveSignInSmokeTests.swift` (env-gated)

## Implementation Steps

1. `AuthStore` state machine + transitions (pure, unit-tested with Stub).
2. `AuthService` methods on `APIClientProtocol`; token capture via TokenStore.
3. `bootstrap()`: token → get-session → authenticated/needsOnboarding/none.
4. Wire `onUnauthorized` → sign-out.
5. SwiftUI screens + `RootView` routing + placeholder Home/Onboarding.
6. App entry DI (Live client + Keychain) + bootstrap on launch.
7. Unit tests: full state-machine matrix with Stub (incl. 401 mid-session,
   onboarding routing). 
8. Live smoke: env `SEE_TAROT_TEST_EMAIL/PASSWORD`; assert header + hydrate;
   skip cleanly when absent.

## Todo List

- [ ] AuthStore state machine + unit tests
- [ ] AuthService (signUp/in/out, bootstrap, providers)
- [ ] set-auth-token capture verified path
- [ ] 401 → central sign-out wired
- [ ] SwiftUI auth screens + RootView routing + placeholders
- [ ] App entry DI + launch bootstrap
- [ ] Live email sign-in smoke (env-gated) passing with real creds

## Success Criteria

Unit auth state-machine matrix green; on a simulator with real BE + test creds:
sign-in succeeds, token persists in Keychain, relaunch restores session,
sign-out clears, 401 forces sign-in, onboarding routes when `onboardedAt==null`.

## Risk Assessment

- `set-auth-token` not in header on live build → smoke fails fast; single
  capture point makes switching to body trivial; STOP + report per harness if
  BE diverges.
- No BE test creds at run time → smoke auto-skips (not a failure); flagged in
  Phase 07 evidence as pending.

## Security Considerations

- Hard gate: Auth. Token only in Keychain; never logged; redact Authorization.
- No password retention beyond the request; no analytics on credentials.
- Account deletion / Google real flow explicitly out of E01.

## Next Steps

Phase 06 adds DesignSystem tokens + CardEngine seam (screens restyled later).
