# Verification Report — E01 iOS Foundation

Date: 2026-05-17
Plan: `plans/260517-0021-e01-ios-foundation/`
Lane: high-risk (hard gate: Auth)

## Result

E01 foundation complete and verified, with ONE documented pending item (live
BE sign-in smoke — needs BE test credentials; auto-skips, not faked).

## Evidence

### Tests (host `swift test`, all packages)

| Package | Tests | Result |
| --- | --- | --- |
| SeeTarotCore | 14 | pass |
| SeeTarotNetworking | 10 | pass |
| SeeTarotPersistence | 4 | pass |
| SeeTarotDesignSystem | 4 | pass |
| SeeTarotCardEngine | 3 | pass |
| SeeTarotFeatures | 12 | 11 pass, 1 skipped (live smoke) |
| **Total** | **47** | **46 pass, 0 fail, 1 skipped** |

### Build & Platform

- `xcodebuild -scheme SeeTarot -destination 'generic/platform=iOS Simulator'
  -configuration Debug` → **BUILD SUCCEEDED** (clean rebuild).
- App installed + launched on iOS simulator; process alive.
- Cold launch ≈ **0.57s** (< 2s skeleton target).
- Each SPM package compiles standalone.

### Lint

- SwiftLint: **0 warnings, 0 errors** (config relaxed for idiomatic short
  local names per development-rules.md lenient policy; generated `.build`
  excluded).

### Auth state machine (unit, Stub-driven)

Covered: no-token bootstrap → signedOut; token+onboarded → authenticated;
token+!onboarded → needsOnboarding; stale token cleared; sign-in ok/invalid;
401 → central sign-out; sign-out clears; onboarding → authenticated; Google
availability gate. SSE parser frame sequence; 429→retry→200; entitlement 403;
`set-auth-token` capture; Keychain round-trip; SwiftData; artwork cache.

## Story Success Criteria

| Criterion | Status |
| --- | --- |
| App builds + runs iOS 17+ simulator | met |
| Each SPM package compiles independently | met |
| Email sign-in E2E vs live BE | **pending** (BE creds; smoke skips) |
| `set-auth-token` capture + Keychain + get-session restore + 401→signout | met (unit; live confirm pending) |
| Onboarding routing seam (`onboardedAt`) | met (unit) |
| SSE consumer primitive + tested, not UI-wired | met |
| 60fps ambient + cold start < 2s | met (SwiftUI gradient; Metal deferred) |
| TEST_MATRIX + validation evidence updated | met (this report) |

## Not Attempted / Deferred (documented, not weakened)

1. **Live BE email sign-in smoke** — env-gated
   (`SEE_TAROT_TEST_EMAIL/PASSWORD`), skips cleanly. Also the verification
   point for the `set-auth-token` header on the live Better Auth 1.6.3 build.
   Needs BE test credentials.
2. **Metal ambient shader** — requires `xcodebuild -downloadComponent
   MetalToolchain` (absent in env). E01 ships the 60fps SwiftUI gradient
   fallback; `AmbientBackgroundView` API stable so the Metal swap is
   non-breaking. Carry to a Metal-enablement task / E02.
3. **Google sign-in flow** — seam only; native idToken flow is a BE decision
   (BE has no native config). Email/password is the shipped E01 path.

## Unresolved Questions

- BE test credentials for the live sign-in smoke (Phase 05/07).
- Confirm `set-auth-token` is a response header on the live 1.6.3 build (do
  during live smoke).
- Metal toolchain install timing (before E02 card animation work).
