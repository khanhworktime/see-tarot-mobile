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

No validation scripts yet (Harness v0). Add `xcodebuild test` + `swiftlint` to
the ladder when `ios/` toolchain exists.

```text
TBD
```

## Acceptance Evidence

Add xcodebuild test output, simulator recording, lint report, live sign-in
smoke log after implementation.
