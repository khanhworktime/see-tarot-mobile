---
title: "E04 — Profile & Personalization (iOS client profile management)"
description: "Authenticated user views/edits name, birthDate, timezone, preferredIntent via PATCH /profile; session refreshes in-app."
status: completed
lane: normal
priority: P2
effort: 5h
branch: main
tags: [ios, swiftui, profile, networking, e04]
created: 2026-05-18
story: docs/stories/epics/E04-profile-personalization.md
blockedBy: []
blocks: []
---

# E04 — Profile & Personalization (client)

## Overview

Add ongoing profile editing for an authenticated user. Scope is **client
profile management only** — AI personalization is BE-side (decision 0005).
Onboarding (`POST /profile/onboard`) already wired in `AuthStore` and is NOT
re-implemented. Reuse all existing E01/E03 networking + auth seams; add the
minimum new surface: `updateProfile` on the client, `AuthStore.refreshSession`,
a `ProfileStore`, and `ProfileView` reachable from Home.

Decisions honored: 0004 (SwiftUI + @Observable MVVM, iOS17), 0005 (Better Auth
Bearer; personalization BE-side), 0006 (bearer-only cookie-free). 0007
(monetization) is out of scope.

### Data Flow

```
ProfileView (form)
  → ProfileStore (loads from SessionUser; tracks dirty; validate() mirrors BE)
  → save(): APIClient.updateProfile(only dirty non-nil fields)
      → PATCH /profile  ProfileUpdateSchema  (≥1 field required)
      → decode ProfileResponse  →  re-hydrate via getSession()  → SessionUser
  → AuthStore.refreshSession()  (getSession → route → state mutate)
  → RootView re-renders authenticated(user) → Home/Profile reflect new values
```

Errors: 400 `{error,issues[]}` → inline field messages; 401 → existing
`ResponseHandler` → `onUnauthorized` → `AuthStore.handleUnauthorized` sign-out.

## Phases

| # | Phase | Status | Deps |
|---|-------|--------|------|
| 01 | API surface + AuthStore.refreshSession + ProfileStore + unit tests | done | — |
| 02 | ProfileView + Home entry + DEBUG stub fixture + verification | done | 01 |

## Dependencies

- Phase 02 depends on Phase 01 (needs `updateProfile`, `refreshSession`,
  `ProfileStore` API surface).
- External: live BE reachable at `http://localhost:3001` (or
  `SEE_TAROT_BASE_URL`) for sim E2E + env-gated `LiveProfileSmokeTests`.
- Builds on E01 auth/session seams + E03 networking patterns (`implemented`).

## Success Criteria

- Profile screen reachable from Home; shows current name / birthDate /
  timezone / preferredIntent from session user.
- Edit + Save → `PATCH /profile` with only changed (dirty) fields; client
  validation mirrors BE; Save disabled until valid AND dirty.
- On 200: session refreshes in-app (Home/routing/intent defaults reflect new
  values). 400 `issues[]` surfaced inline; 401 → sign-out seam.
- Unit tests (validation bounds, ≥1-required, dirty-tracking, store state
  machine, session-refresh, updateProfile decode) green.
- Full `swift test` per touched package + lint pass; sim E2E vs live BE;
  env-gated `LiveProfileSmokeTests` (skips clean without creds).
- `TEST_MATRIX.md` E04 row updated; story Evidence populated; plan statuses
  flipped; verification report written.

## Stop Conditions

- Contract drift: tarot-contract MCP diverges from the snapshot in this plan
  → STOP, re-read MCP, revise phase 01 before coding.
- Live BE unreachable at `:3001` → E2E/live-smoke cannot prove; do NOT mark
  story `implemented`; record blocker in verification report.
- Any touched file would exceed 200 lines → split before continuing.
- `getSession` re-hydrate returns a user missing the patched field → treat as
  contract mismatch, STOP.

## Unresolved Questions

- Timezone input UX: free-text (1–64, BE-validated) vs curated `TimeZone`
  identifier picker. Plan assumes a picker over `TimeZone.knownTimeZoneIdentifiers`
  (still client-validated 1–64) for KISS + fewer 400s. Confirm acceptable.
- `ProfileResponse.timezone` is required in the response but optional in
  `SessionUser`; re-hydrate via `getSession` is authoritative regardless, so no
  action — flagged only if BE response is consumed directly later.
