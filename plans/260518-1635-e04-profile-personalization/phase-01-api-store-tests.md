# Phase 01 — API surface + AuthStore.refreshSession + ProfileStore + unit tests

## Context Links

- Story: `docs/stories/epics/E04-profile-personalization.md`
- Plan: `plans/260518-1635-e04-profile-personalization/plan.md`
- Decisions: 0004 (SwiftUI/@Observable/iOS17), 0005 (Bearer; BE personalization),
  0006 (bearer-only)
- Reuse refs: `LiveAPIClient+History.swift` (extension pattern),
  `AuthStore.swift` (route/getSession), `StubAPIClient.swift`,
  E03 `phase-01-contract-api-stores.md`

## Overview

- Priority: P2 (foundation; blocks phase 02)
- Status: planned
- Add the non-UI surface: `updateProfile` on `APIClientProtocol` (+ Live + Stub),
  `AuthStore.refreshSession()`, and a `@MainActor @Observable ProfileStore`.
  Full unit coverage before any UI exists.

## Key Insights

- `send<T>` + `perform` + `ResponseHandler` already map 400 (typed
  `APIError.http(status:envelope:)`) and 401 (`onUnauthorized` → sign-out).
  No bespoke error handling — DRY.
- `Endpoint` already supports `.PATCH` + body. Mirror `setVisibility` shape.
- `updateProfile` must send **only non-nil** fields → encode a struct with all
  `Encodable?` optionals + `JSONEncoder` default (omits nil) OR build a
  `[String:String]` dict. Dict is simplest (KISS) and matches
  `completeOnboarding` precedent in `AuthStore`.
- After PATCH, decode `ProfileResponse` (sanity) then **re-hydrate via
  `getSession()`** — getSession is the single source of truth for `SessionUser`
  (ProfileResponse lacks `email/tier/onboardedAt`).
- `AuthStore` exposes `route(_:)` privately and `state` `private(set)`.
  `refreshSession()` lives ON `AuthStore` so it can call `route` + mutate
  `state` — do not externalize.
- Client validation MUST mirror BE exactly (no stricter/looser): name 1–60,
  timezone 1–64, birthDate `^\d{4}-\d{2}-\d{2}$`, intent ∈ 7-enum, ≥1 field
  present (cross-field).

## Requirements

Functional:
- `APIClientProtocol.updateProfile(name:birthDate:timezone:preferredIntent:)
  async throws -> SessionUser?` — all params `String?`; sends only non-nil;
  PATCH `/profile`; decodes `ProfileResponse`; returns `getSession()` result.
- `AuthStore.refreshSession() async` — calls `getSession()`; on user → `state =
  route(user)`; on nil → leave state (no forced sign-out; 401 path handles auth
  loss via existing hook).
- `ProfileStore` (`@MainActor @Observable`): editable fields seeded from
  `SessionUser`; `isDirty`; `validationErrors` (per-field, mirrors BE);
  `canSave` = dirty && valid && not saving; `save()` → updateProfile(only dirty)
  → `auth.refreshSession()`; phase state idle/saving/saved/failed(message).

Non-functional:
- Each new file < 200 lines; Swift PascalCase types; `Sendable` where crossing
  actors; no secrets.

## Architecture

```
APIClientProtocol  + updateProfile(...)
  ├─ LiveAPIClient+Profile.swift (NEW): build dict of non-nil → PATCH /profile
  │     → decode ProfileResponse → getSession() → SessionUser?
  └─ StubAPIClient: + var updateProfileResult: Result<SessionUser?,Error>?
        + captured(updateProfileArgs) for dirty-field assertions

AuthStore.refreshSession()  → client.getSession() → route → state

ProfileStore (@Observable)
  init(auth: AuthStore, user: SessionUser)
  fields: name, birthDate (Date? ↔ "YYYY-MM-DD"), timezone, preferredIntent
  validate() -> [Field: String]   (mirrors ProfileUpdateSchema)
  dirtyPayload() -> changed-only tuple
  save() async  → guard canSave → updateProfile(dirty) → auth.refreshSession()
```

Wire types (private to Networking, contract-exact):
`ProfileResponse { id: String; name: String?; timezone: String?;
preferredIntent: String?; birthDate: String? }`.

## Related Code Files

Create:
- `ios/Packages/SeeTarotNetworking/Sources/SeeTarotNetworking/LiveAPIClient+Profile.swift`
- `ios/Packages/SeeTarotFeatures/Sources/SeeTarotFeatures/Profile/ProfileStore.swift`
- `ios/Packages/SeeTarotFeatures/Sources/SeeTarotFeatures/Profile/ProfileValidation.swift`
  (pure rules, mirrors BE; reusable + cheaply unit-tested)
- `ios/Packages/SeeTarotNetworking/Tests/SeeTarotNetworkingTests/ProfileEndpointTests.swift`
- `ios/Packages/SeeTarotFeatures/Tests/SeeTarotFeaturesTests/ProfileStoreTests.swift`

Modify:
- `APIClientProtocol.swift` (+ `updateProfile` decl, E04 section)
- `StubAPIClient.swift` (+ `updateProfileResult`, captured args, impl)
- `AuthStore.swift` (+ `refreshSession()`)

Delete: none.

## Implementation Steps

1. Add `updateProfile(...)` to `APIClientProtocol` under a `// Profile (E04
   surface)` comment.
2. `LiveAPIClient+Profile.swift`: build `var body: [String:String]`, insert
   each param if non-nil; guard `!body.isEmpty` else throw
   `APIError.transport("updateProfile: no fields")` (defensive — store also
   guards); `Endpoint(path:"profile",method:.PATCH,body:encoder.encode(body))`;
   `_ = try await send(.., as: ProfileResponse.self)`; `return try await
   getSession()`. Add private `ProfileResponse`.
3. `StubAPIClient`: add `updateProfileResult: Result<SessionUser?,Error>?`,
   `private(set) var lastUpdateProfileArgs`; impl records args, returns result
   (default: echo merged onto `sessionUser`).
4. `AuthStore.refreshSession()`: `if let u = try? await client.getSession() {
   state = route(u) }`.
5. `ProfileValidation.swift`: pure funcs/regex mirroring `ProfileUpdateSchema`
   (name 1–60 trimmed, timezone 1–64, birthDate regex, intent enum set,
   atLeastOne). No UIKit/SwiftUI import.
6. `ProfileStore.swift`: `@MainActor @Observable`; seed from user; computed
   `isDirty` / `validationErrors` / `canSave`; `save()` calls updateProfile with
   only dirty fields then `auth.refreshSession()`; map `APIError.http(400,env)`
   issues → per-field; `.unauthorized` → no inline (sign-out seam handles).
7. Tests — `ProfileEndpointTests` (MockURLProtocol): PATCH body contains only
   set fields; 200 → getSession re-hydrate returns merged user; 400 →
   `APIError.http(400, envelope.issues)`; 401 → `APIError.unauthorized`.
8. Tests — `ProfileStoreTests` (StubAPIClient + stub AuthStore): dirty-tracking
   (no change ⇒ !canSave), each validation bound (name 0/1/60/61, tz 0/1/64/65,
   birthDate good/bad, intent valid/invalid), ≥1-required, save success →
   `auth.refreshSession` ran (state user updated), save 400 → inline errors,
   save 401 → no crash.
9. `swift test` for `SeeTarotNetworking` then `SeeTarotFeatures`; fix until
   green.

## Todo List

- [ ] `updateProfile` added to `APIClientProtocol`
- [ ] `LiveAPIClient+Profile.swift` (non-nil dict, decode, re-hydrate)
- [ ] `StubAPIClient` extended (result + captured args)
- [ ] `AuthStore.refreshSession()`
- [ ] `ProfileValidation.swift` mirrors BE schema exactly
- [ ] `ProfileStore.swift` (dirty/valid/canSave/save)
- [ ] `ProfileEndpointTests` (200/400/401 + body assertion)
- [ ] `ProfileStoreTests` (validation/dirty/state-machine/refresh)
- [ ] `swift test` green for both packages

## Success Criteria

- Both packages `swift test` pass with new tests.
- PATCH body provably contains ONLY dirty/non-nil fields (asserted).
- 400 maps to per-field inline errors; 401 routes to sign-out seam (no inline).
- `refreshSession` mutates `AuthStore.state` to updated user.
- No file > 200 lines.

## Risk Assessment

| Risk | L×I | Mitigation |
|------|-----|------------|
| BE `issues[]` shape ≠ assumed (key/path) | M×M | Decode defensively; map by first path segment to field; unknown → form-level banner; assert in endpoint test against contract sample |
| `getSession` returns user lacking patched field (eventual consistency) | L×H | Stop condition in plan; test asserts merged user; flag as contract mismatch |
| Encoder emits `null` for nil (sends unintended field) | M×H | Use `[String:String]` dict (only inserted keys serialize) — avoids optional-encoding ambiguity |
| `refreshSession` nil-session silently strands UI | L×M | Leave state; rely on existing 401 hook for true auth loss; documented |
| Cross-field ≥1 enforced only client-side | L×M | Store `canSave` guards; Live also guards empty body → throws before request |

## Security

- No secrets; bearer attached by `RequestBuilder` via `TokenStoring` (unchanged).
- 401 continues to flow through `ResponseHandler` → `onUnauthorized` →
  `handleUnauthorized` (Keychain token cleared) — not bypassed.
- No PII logged; birthDate handled in-memory only.

## Next

Phase 02 consumes `ProfileStore` + `refreshSession` to build `ProfileView`,
the Home entry, DEBUG stub fixture, and full verification.
