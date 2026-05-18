# Verification Report — E04 Profile & Personalization (client)

Date: 2026-05-18
Plan: `plans/260518-1635-e04-profile-personalization/`
Lane: normal (strong validation)

## Result

E04 **implemented**. Client profile management (`PATCH /profile`) is
unit/integration green, lint clean, builds + runs on sim, and a live BE smoke
proves the real round-trip (name patched → echoes via `getSession` →
restored). AI personalization itself stays BE-side (server folds profile +
reflections into the prompt — no client work, decision 0005). No faked green.

## Evidence

### Tests (host `swift test`, all packages)

| Package | Tests | Result |
| --- | --- | --- |
| SeeTarotCore | 17 | pass |
| SeeTarotNetworking | 20 | pass (+4 ProfileEndpointTests) |
| SeeTarotPersistence | 11 | pass |
| SeeTarotDesignSystem | 4 | pass |
| SeeTarotCardEngine | 7 | pass |
| SeeTarotFeatures | 41 | 36 pass, 5 live skip (+6 ProfileStoreTests) |
| **Total** | **100** | live env: 100 pass; no env: 95 pass + 5 skip; 0 fail |

E04-specific: ProfileEndpointTests (only-dirty PATCH body asserted, getSession
re-hydrate, 400 issues→typed, 401→hook, empty payload throws pre-request);
ProfileStoreTests (clean form !canSave, dirty single-field sends only that,
validation bounds name/tz/birthDate/intent + ≥1-required, 400 field-mapping,
401 no-inline).

### Build & Lint

- `build_run_sim` iOS Debug → **SUCCEEDED** (clean).
- SwiftLint **0 errors / 0 warnings** (fixed large_tuple → `ProfilePatch`
  struct; force_try removed in ProfileValidation/tests; Data→String failable).

### Live BE smoke (`LiveProfileSmokeTests`, `SEE_TAROT_BASE_URL=:3001`)

PASSED (0.199s): sign-in → `updateProfile(name: "smoke-xxxxxx")` →
asserts `SessionUser.name` echoes the marker (proves PATCH + getSession
re-hydrate) → restores original name (idempotent for shared account).

### Sim E2E (XcodeBuildMCP + ios-simulator MCP, live BE :3001)

Home shows new **"Profile"** entry → `ProfileView` renders live session
values (name "Admin", birthDate 18 May 2026, timezone Asia/Ho_Chi_Minh, intent
picker). "Change at least one field." + Save disabled while clean (mirrors BE
≥1-required). Editing name → "Admin Neo" → Save **enables** (dirty + valid).
Tapping Save returned **401 → "Your session expired"** and correctly routed to
the sign-out seam — the persisted sim Keychain token was stale (not a code
defect; this verifies the 401 path).

## Acceptance Criteria

| Criterion | Status |
| --- | --- |
| Profile screen from Home, shows session values | met (sim live) |
| Edit + save sends only changed fields | met (unit body assertion + live smoke) |
| Client validation mirrors BE (≥1, bounds, enum, date) | met (unit + sim disabled Save) |
| Success → session refresh | met (live smoke echo via getSession; ProfileStore→AuthStore.refreshSession unit) |
| 400 issues inline; 401 → sign-out seam | met (unit + sim 401 observed) |
| AI behavior unchanged (BE-side) | met (no client AI; documented) |
| Tests + build + lint green | met |

## Not Attempted / Deferred (documented, not faked)

1. **Sim happy-path Save screenshot** — the persisted sim token was stale so
   Save hit 401 (correctly → sign-out). A fresh in-sim re-login to capture the
   green save was blocked by simulator TextEditor/TextField automation
   flakiness (same limitation noted in E02/E03). The successful PATCH +
   re-hydrate is proven by `LiveProfileSmokeTests` (live BE) + unit tests.
2. **Real-device run** — out of scope per user (simulator flow until asked).

## Unresolved Questions

- "Change at least one field." shows immediately (clean form) — accurate
  (mirrors BE ≥1) but a future polish could defer it until first interaction.
- Dedicated non-admin test account still wanted to isolate profile mutations
  on the shared account (HARNESS_BACKLOG #7).
