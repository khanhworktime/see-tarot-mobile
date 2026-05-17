# Overview — E01 iOS Foundation

## Status

in_progress (2026-05-17) — implementation + 46 automated proofs complete and
verified; story stays `in_progress` pending the live BE email sign-in smoke
(needs BE test creds). See
`plans/reports/verification-260517-e01-ios-foundation.md`.

## Current Behavior

No mobile app. Repo holds harness only. BE (`api.seetarot.com`) is live with
auth, readings (SSE + daily), profile/onboarding, reflections, quota — contract
in `see-tarot-be/docs/api-reference-mobile-swift.md`. No AI personalization
module yet.

## Target Behavior

iOS skeleton under `ios/`: modular SPM packages, SwiftUI shell, real
`APIClient` (Better Auth Bearer) + stub for tests, networking core (Keychain
token, `authed()` builder, `{error,message,issues}` decoding, 401→sign-out,
429 backoff), launch session bootstrap via `/auth/get-session`, onboarding gate
seam (`onboardedAt`), `DesignSystem` (native + brand accent), `CardEngine`
animation seam (+ Metal ambient spike), SSE consumer seam. App builds, runs,
email/password sign-in works against live BE, lands on placeholder Home. Sets
contract seams for E02–E05.

## Affected Users

- iOS end users (future).
- Agents building E02–E06.

## Affected Product Docs

- `docs/product/overview.md`, `api-conventions.md`, `readings.md`,
  `personalization.md`, `billing.md`

## Non-Goals

- Real spread/oracle flow + reading UI (E02).
- History list/detail (E03), personalization provider impl (E04),
  monetization (deferred), Android (E06).
- Sign in with Apple (dropped, decision 0005).
