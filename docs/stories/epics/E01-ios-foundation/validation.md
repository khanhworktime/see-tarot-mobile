# Validation — E01 iOS Foundation

## Proof Strategy

Done when: app builds + runs on simulator, packages compile independently,
email sign-in works end-to-end against live BE, auth/session/onboarding state
machine correct, seams for E02–E05 exist with tests. Google full flow may be
deferred (documented BE-config blocker, not a weakened requirement).

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | APIClient stub fixtures; auth state machine (signed-out → email sign-in → `set-auth-token` capture → Keychain persist → `get-session` restore → 401 → sign-out); error envelope `{error,message,issues}` decode; onboarding routing (`onboardedAt` null vs set); 429 backoff |
| Integration | Live BE smoke: sign-up/in returns token header; `get-session` hydrates user; `auth-providers` parsed. Keychain round-trip; SwiftData cache round-trip |
| E2E | Launch → email sign-in → (onboarding if needed) → placeholder Home → relaunch restores session → sign-out |
| Platform | Builds iOS 17+ device + simulator; 60fps CardEngine ambient spike |
| Performance | Cold start < 2s (skeleton baseline) |
| Logs/Audit | No PII in logs; network errors categorized (4xx/5xx/SSE) |

## Fixtures

- Deterministic stub `Session` + user.
- A BE test account (email/password) for the live smoke (documented, not
  committed).
- Fixed `CardArtworkRef` sample set for cache tests.

## Commands

`ios/` toolchain now exists. Validation ladder for E01:

```text
# unit + integration (per package, host)
cd ios/Packages/<Pkg> && swift test

# build (iOS simulator)
cd ios && xcodebuild -project SeeTarot.xcodeproj -scheme SeeTarot \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  -derivedDataPath ./.xcdd build

# lint
cd ios && swiftlint lint --quiet

# live BE sign-in smoke (env-gated; pending creds)
SEE_TAROT_TEST_EMAIL=… SEE_TAROT_TEST_PASSWORD=… \
  swift test --filter LiveSignInSmokeTests
```

## Acceptance Evidence

Verified 2026-05-17 — see
`plans/reports/verification-260517-e01-ios-foundation.md`.

- Tests: 47 total → 46 pass, 0 fail, 1 skipped (live smoke). Per package:
  Core 14, Networking 10, Persistence 4, DesignSystem 4, CardEngine 3,
  Features 12 (1 skipped).
- Build: `xcodebuild` → BUILD SUCCEEDED (clean); each SPM package builds
  standalone.
- Platform: app installs + launches on iOS 17 simulator; cold launch ≈0.57s
  (< 2s target); ambient bg = SwiftUI gradient (Metal deferred — toolchain).
- Lint: SwiftLint 0 warnings / 0 errors.
- Commits: 0c65fb1, f048615, f580bc5, cf98229, b4ac1a6, 483c5bb.

**Pending (documented, not faked):** live BE email sign-in smoke needs
`SEE_TAROT_TEST_EMAIL/PASSWORD`; also confirms `set-auth-token` header on the
live Better Auth 1.6.3 build. Story stays `in_progress` until this passes.
