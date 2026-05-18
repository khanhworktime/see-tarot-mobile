# Phase 02 — ProfileView + Home entry + DEBUG stub fixture + verification

## Context Links

- Story: `docs/stories/epics/E04-profile-personalization.md`
- Plan: `plans/260518-1635-e04-profile-personalization/plan.md`
- Depends on: phase-01 (ProfileStore, refreshSession, updateProfile)
- Reuse refs: `HomeView.swift` (NavigationStack + `HomeRoute`),
  `IntentCopy.swift` (intent labels), `AppComposition.swift`
  (`makeStubAuthStore`), `LiveHistorySmokeTests.swift` (env-gated pattern),
  `docs/TEST_MATRIX.md`, `docs/HARNESS_BACKLOG.md`

## Overview

- Priority: P2
- Status: planned
- Build `ProfileView` (form), add the Home entry + route, extend the DEBUG
  stub fixture, then run full verification (unit + lint + sim E2E vs live BE +
  env-gated live smoke) and update harness/story/plan status.

## Key Insights

- `HomeView` owns `NavigationStack(path:)` + `HomeRoute` enum + a button list.
  Add `.profile` case + a "Profile" button + `navigationDestination` arm. Pass
  `auth` is NOT available in `HomeView` (it takes `client` + `user`); the
  `AuthStore` is held by `RootView`. **Decision:** thread the `AuthStore` (or a
  `refreshSession` closure) from `RootView` → `HomeView` → `ProfileView`.
  Minimal seam: add `onProfileSaved: () async -> Void` injected from `RootView`
  wired to `auth.refreshSession`, mirroring the existing `onSignOut` closure
  pattern (no new HomeView↔AuthStore coupling, DRY with `onSignOut`).
- Intent picker reuses `IntentCopy.all` (label/detail) — no new copy.
- birthDate: SwiftUI `DatePicker` (date only) ↔ `"YYYY-MM-DD"` via a fixed
  `DateFormatter` (en_US_POSIX, UTC) — keep formatting in `ProfileStore`/helper
  from phase 01, not duplicated in the view.
- Stub fixture: `makeStubAuthStore` user already has name/birthDate/timezone/
  preferredIntent — add `stub.updateProfileResult` so save path works offline
  (`SEE_TAROT_UI_STUB=1`).
- Sim E2E target BE: `http://localhost:3001` (on-device/sim LAN BE already
  enabled per recent commits). ATS local exception already in place.

## Requirements

Functional:
- `ProfileView` form: name `TextField`, birthDate `DatePicker`, timezone
  picker (`TimeZone.knownTimeZoneIdentifiers`, client-validated 1–64),
  preferredIntent picker (`IntentCopy.all`). Save button disabled unless
  `store.canSave`. Inline per-field error text from `store.validationErrors`.
  Saving spinner; success dismiss/confirmation; failure banner.
- Home: "Profile" button → `HomeRoute.profile` → `ProfileView`.
- On successful save: session refreshes (via injected closure →
  `auth.refreshSession`) so Home/routing reflect new values.

Non-functional: files < 200 lines; iOS17; PascalCase; no secrets.

## Architecture

```
RootView.authenticated(user)
  → HomeView(client:, user:, onSignOut:, onProfileSaved: auth.refreshSession)
        HomeRoute.profile → ProfileView(store: ProfileStore(auth?/closure,user))
ProfileView → ProfileStore.save() → updateProfile → onProfileSaved()
        → AuthStore.refreshSession → RootView re-renders
```

Note: `ProfileStore.save()` already calls `auth.refreshSession()` internally
(phase 01). The `onProfileSaved` closure is the RootView→Home wiring path that
supplies that `AuthStore` reference; pick ONE mechanism during phase 01 store
design and keep it consistent (prefer: `ProfileStore` holds `AuthStore`,
`HomeView` receives `auth` — re-evaluate vs closure to minimize coupling, decide
in phase 01 step 6, document choice here before coding phase 02).

## Related Code Files

Create:
- `ios/Packages/SeeTarotFeatures/Sources/SeeTarotFeatures/Profile/ProfileView.swift`
- (optional, if ProfileView >200 lines) split pickers into
  `ProfileView+Fields.swift`
- `ios/Packages/SeeTarotFeatures/Tests/SeeTarotFeaturesTests/LiveProfileSmokeTests.swift`

Modify:
- `App/HomeView.swift` (+ `.profile` route, button, destination, threaded
  `auth`/closure)
- `App/RootView.swift` (pass `auth` / `onProfileSaved` into `HomeView`)
- `App/AppComposition.swift` (DEBUG: `stub.updateProfileResult`)
- `docs/TEST_MATRIX.md` (E04 row → status/evidence)
- `docs/stories/epics/E04-profile-personalization.md` (Status, Evidence)
- `plans/260518-1635-e04-profile-personalization/plan.md` (phase statuses)
- `docs/HARNESS_BACKLOG.md` (only if friction encountered)

Delete: none.

## Implementation Steps

1. Finalize the AuthStore-threading decision from phase 01; document the chosen
   mechanism at top of this file before coding.
2. `ProfileView.swift`: `@State private var store: ProfileStore`; `Form` with
   the 4 fields; bind to store; disabled Save = `!store.canSave`; inline errors;
   saving/failed states. Reuse `IntentCopy.all`. Keep < 200 lines (split fields
   if needed).
3. `HomeView`: add `onProfileSaved` (or `auth`) param + "Profile" button +
   `case profile` in `HomeRoute` + `navigationDestination` arm building
   `ProfileView(store: ProfileStore(...))`.
4. `RootView`: wire `onProfileSaved: { await auth.refreshSession() }` (or pass
   `auth`) into `HomeView` — mirror `onSignOut` closure style.
5. `AppComposition` DEBUG: set `stub.updateProfileResult = .success(updated
   user)` so `SEE_TAROT_UI_STUB=1` save works offline.
6. `LiveProfileSmokeTests.swift`: copy `LiveHistorySmokeTests` env-gate
   (`SEE_TAROT_TEST_EMAIL`/`PASSWORD`, `SEE_TAROT_BASE_URL` default
   `http://localhost:3001`); sign in → `updateProfile(name: "smoke-<uuid>")`
   → assert returned `SessionUser.name` echoes the marker → restore original
   name. Skips clean without creds (never fakes green).
7. Build + full `swift test` for `SeeTarotNetworking` + `SeeTarotFeatures`.
8. Lint per repo lint command; fix.
9. Sim E2E (XcodeBuildMCP + ios-simulator MCP) vs live BE `:3001`: open Profile
   → edit a field → Save → confirm value persists + Home reflects it after
   session refresh. Capture screenshots to `{plan_dir}/visuals/`.
10. Run env-gated `LiveProfileSmokeTests` with creds against `:3001`.
11. Update `TEST_MATRIX.md` E04 row, story `Status`/`Evidence`, plan phase
    statuses (`ck plan check` or edit Status column).
12. Write verification report →
    `plans/260518-1635-e04-profile-personalization/reports/verification-report.md`.
    Log any harness friction in `docs/HARNESS_BACKLOG.md`.

## Todo List

- [ ] AuthStore-threading mechanism documented
- [ ] `ProfileView.swift` (form, validation, states) < 200 lines
- [ ] Home entry + `.profile` route wired
- [ ] `RootView` passes refresh seam
- [ ] DEBUG stub `updateProfileResult` fixture
- [ ] `LiveProfileSmokeTests.swift` (env-gated, asserts echo)
- [ ] Full `swift test` green (both packages)
- [ ] Lint pass
- [ ] Sim E2E vs live BE `:3001` (screenshots saved)
- [ ] Env-gated live smoke run
- [ ] TEST_MATRIX + story Evidence + plan status updated
- [ ] Verification report written

## Success Criteria

- Profile reachable from Home; shows current session values.
- Save sends only dirty fields; disabled until valid & dirty; 400 inline; 401
  → sign-out.
- Post-save session refresh observable (Home/routing reflect new values) in
  sim E2E.
- All unit tests green; lint clean; live smoke passes (or skips clean if no
  creds — documented, story NOT marked implemented without live proof).
- Docs/story/matrix/plan synced.

## Risk Assessment

| Risk | L×I | Mitigation |
|------|-----|------------|
| HomeView↔AuthStore coupling regresses RootView contract | M×M | Use `onProfileSaved` closure mirroring existing `onSignOut`; no direct AuthStore type in HomeView signature if avoidable |
| ProfileView exceeds 200 lines | M×L | Pre-plan split: `ProfileView+Fields.swift` for pickers |
| Live BE `:3001` down during E2E | M×H | Stub fixture proves UI offline; record blocker; do NOT mark story implemented; HARNESS_BACKLOG entry |
| Timezone identifier list huge/slow picker | L×L | Searchable/sectioned picker or plain Picker; still client-validated 1–64 |
| DatePicker timezone skews stored YYYY-MM-DD | M×M | Format via en_US_POSIX + UTC formatter from phase-01 helper (single source); unit-covered in phase 01 |
| Smoke test mutates shared account name permanently | L×M | Restore original name in test teardown (idempotent), like E03 visibility restore |

## Security

- No secrets in code or fixtures; smoke creds via env only.
- 401 path unchanged (sign-out seam); birthDate/PII not logged.
- Stub fixture DEBUG-only (`#if DEBUG`), never in Release.

## Next

On green verification: story → `implemented` (only with live proof), plan
`status: completed`. No follow-up phases (E04 client scope complete; AI
personalization remains BE-side, out of scope).
