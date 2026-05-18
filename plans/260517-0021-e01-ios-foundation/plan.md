---
title: E01 iOS Foundation
status: done
lane: high-risk
created: 2026-05-17
story: docs/stories/epics/E01-ios-foundation/
decisions: [0004-native-ios-app-architecture, 0005-be-contract-reconciliation]
blockedBy: []
blocks: []
---

# E01 iOS Foundation — Implementation Plan

Modular iOS skeleton + every contract seam, wired to the concrete BE contract,
so E02–E05 build in parallel without rework. Scope = E01 only.

## Authoritative Context

- Story: `docs/stories/epics/E01-ios-foundation/` (overview/design/execplan/validation)
- Decisions: `docs/decisions/0004-*`, `0005-*`
- Product: `docs/product/{overview,api-conventions,readings,personalization,billing}.md`
- Upstream BE contract: `/Users/kristdev/Desktop/Work/Personal/see-tarot-be/docs/api-reference-mobile-swift.md`

## Constraints

- Harness v0: this story authorizes the first `ios/` source. Respect `AGENTS.md`.
- iOS 17+. SwiftUI + `@Observable` MVVM. Local SPM packages.
- Better Auth Bearer. Email/password = E01 end-to-end path. Google = seam only
  (native idToken assumption). NO Sign in with Apple.
- File <200 lines. `.swift` PascalCase; non-Swift kebab-case. No secrets committed.
- Out of scope: reading/oracle/daily UI flow (E02), history (E03),
  personalization impl (E04), monetization (deferred), Android (E06).

## Phases

| # | Phase | Status | Output |
|---|-------|--------|--------|
| 01 | [Workspace & SPM bootstrap](phase-01-workspace-spm-bootstrap.md) | done | Buildable empty app + package graph |
| 02 | [Core domain models](phase-02-core-domain-models.md) | done | Codable types + envelope/SSE types + tests |
| 03 | [Networking core](phase-03-networking-core.md) | done | APIClient protocol/real/stub, SSE seam |
| 04 | [Persistence & secure storage](phase-04-persistence-secure-storage.md) | done | Keychain, SwiftData, artwork cache |
| 05 | [Auth + session bootstrap](phase-05-auth-session-bootstrap.md) | done* | Email sign-in E2E, onboarding gate seam |
| 06 | [DesignSystem & CardEngine seams](phase-06-designsystem-cardengine-seams.md) | done | Tokens + SwiftUI ambient (Metal deferred) |
| 07 | [Verification & harness update](phase-07-verification-harness-update.md) | done* | Tests, smoke, TEST_MATRIX/evidence |

\* Phase 05 `done*` = implementation + unit proof complete; the **live BE
sign-in smoke is pending BE test credentials** (auto-skips, not faked). Resolve
in Phase 07 once creds are provided.

## Dependencies

Linear: 01 → 02 → 03 → 04 → 05 → 06 → 07. 02 and 06 (DesignSystem half) are
partially parallelizable but keep linear for a solo high-quality pass.

## Success Criteria (story-level)

- App builds + runs iOS 17+ simulator; each SPM package compiles independently.
- Email sign-up/in works end-to-end against live BE (`set-auth-token` captured,
  Keychain persisted, `/auth/get-session` restores, 401 → sign-out).
- Onboarding routing seam correct (`onboardedAt` null vs set).
- SSE consumer primitive exists + unit-tested (not UI-wired).
- 60fps CardEngine ambient spike; cold start < 2s (skeleton baseline).
- `docs/TEST_MATRIX.md` E01 row updated with evidence; `validation.md` filled.

## Stop Conditions (harness)

Pause for human confirmation if: BE behavior diverges from
`api-reference-mobile-swift.md`; `set-auth-token` delivery or Google flow
blocks auth meaningfully; Approach A needs changing; any validation requirement
would be weakened.

## Unresolved Questions

- `set-auth-token` header confirmed-expected; verify on live build (Phase 05).
- Google native idToken flow is a BE decision — Google stays seam-only in E01.
- BE test account for live sign-in smoke (Phase 05/07) — user to provide.
