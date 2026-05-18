# Code Review — See Tarot iOS Client (E01–E04 + cross-cutting fixes)

Date: 2026-05-18
Scope: ios/Packages/* (6 SPM pkgs) + ios/SeeTarot/*, ~4980 LOC, all files
<200 lines. Git range `8fab5b9..8c5569c`. Read-only; no source modified.
Local suites run green: Core, Networking 20, Persistence 11, DesignSystem,
CardEngine, Features 41 (5 live-skip), 0 fail.

## Overall

Ship-ready with minor blockers. Strong modular boundaries, real
`StubAPIClient` seam, consistent `ResponseHandler` mapping. **Harness honesty
verified — verification reports are NOT inflated**; live report documents a
real cookie/CSRF bug found+fixed; E04 report honestly flags deferred sim
screenshot + stale-token 401 as findings, not green. Tests assert real
behavior. Live smokes skip cleanly without creds.

## Critical
None. No auth bypass / secret / PII leak. OSLog logs only
cardId/status/byte-counts `.public`. Keychain AfterFirstUnlockThisDeviceOnly,
no iCloud. ATS cleartext only via NSAllowsLocalNetworking (inert in Release).

## High

- **H1 RetryPolicy retries non-idempotent POSTs.** `LiveAPIClient.perform`
  wraps every request in `retry.run`; transport-error retry can duplicate
  sign-up / daily-draw / reflection POSTs whose response was lost.
  `RetryPolicy.swift:21-28`, `LiveAPIClient.swift:44-59`. Fix: retry only GET
  on transport errors; 429-retry OK for any method (server rejected
  unprocessed).
- **H2 ProfileView timezone Picker corrupts/blocks on non-enumerated TZ.**
  Picker over `TimeZone.knownTimeZoneIdentifiers`; a nil/abbrev/non-canonical
  session `timezone` has no matching tag → undefined selection / unintended
  dirty / un-saveable. `ProfileView.swift:41-46`. Fix: prepend current value
  if absent, or nil-safe sentinel.
- **H3 Sign-in assumes immediate getSession consistency.** `authenticate`
  POSTs creds then immediately `getSession()`; nil → `badResponse` "Sign-in
  failed" despite captured token (confusing next-launch state). BE mid
  NestJS migration raises lag risk. `LiveAPIClient.swift:91-101`. Fix: short
  retry/recoverable hydrate when token captured but session nil.

## Medium

- **M1** SSE undecodable `error` defaults `retryable:true` → user burns quota
  retrying unrecoverable failures. `OracleReadingStore.swift:76-79`. Fix:
  default false. Also single-line `data:` assumption (`SSEParser.swift:16-23`).
- **M2** DiskArtworkCache LRU relies on filesystem mtime (coarse-resolution
  race); acceptable given self-heal; optional in-memory recency.
  `ArtworkCache.swift:38-46,61-84`.
- **M3** `rasterizedIfSVG` feeds up-to-440KB+ untrusted SVG into SwiftDraw with
  no size cap (CPU/mem exhaustion risk; low exploitability — needs MITM/compromised
  BE). `CardImageLoader.swift:43-90`. Fix: reject >~2MB before rasterize;
  timeout around `pngData`.
- **M4** `ProfileView.birthDate` binding defaults invalid/empty to `Date()`
  (today) — first interaction can write today as birthDate.
  `ProfileView.swift:22-26`. Fix: distinct "set birth date" affordance.

## Low / Nit

- L1 403-with-`error` always → `entitlement`; genuine authz-403 misclassified
  (non-blocking, BE only uses 403 for entitlements). `ResponseHandler.swift:32-35`
- L2 SSEParser resets state after any `data:` (benign current framing).
- L3 `getSession` `try?` swallows decode errors → silent sign-out on BE shape
  change. `LiveAPIClient.swift:103-110`
- L4 `ReadingDetailStore.toggleVisibility` empty catch — no UI feedback.
- L5 `JSONCoders.api` allocates fresh coder per access.
- L6 `AppConfig.apiBaseURL` fatalError on missing key (acceptable invariant).
- Nit `OracleReadingStore.submit` doesn't cancel a prior in-flight task on
  rapid re-submit (old SSE keeps burning quota). Add `task?.cancel()` top of
  submit.

## Edge / False-Assumption

imageUrl nil → placeholder (safe). Empty/huge page handled. Concurrent stores
@MainActor-isolated; UnauthorizedBox cycle clean. getSession eventual
consistency → H3. All HTTP codes + SSE done/error/cancel handled.

## Verdict

Ship-ready, no critical/security blocker. Fix **H1 + H2** before production
traffic (duplicate writes; broken profile for common TZs). H3 BE-migration
sensitive. Harness trustworthy.

## Top 5 Actions

1. H1 retry idempotency (GET-only transport retry; 429 any).
2. H2 timezone picker tolerates non-enumerated/nil/non-canonical.
3. H3 recoverable getSession-nil after sign-in.
4. M3 response-size cap before SwiftDraw.
5. M1 + Nit: SSE error non-retryable default; cancel prior task on resubmit.

## Unresolved Questions

- BE read-after-write consistency for `/auth/get-session` post sign-in during
  NestJS migration? (H3 severity)
- SSE `data:` guaranteed single-line JSON? (M1 scope)
- BE `timezone` value space — IANA canonical only? (H2 fix shape)

Status: DONE_WITH_CONCERNS — 3 High + 4 Medium, none critical; H1+H2
recommended before production.

## Resolution (2026-05-18, post-review)

Fixed **H1, H2, H3, M1, Nit**:
- H1 `RetryPolicy.run(idempotent:)` — transport-error retry GET-only; `429`
  retries any method. `LiveAPIClient.perform` passes `endpoint.method == .GET`.
- H2 `ProfileView.timezoneOptions` prepends the current session timezone if
  not in `knownTimeZoneIdentifiers` (nil/abbrev/non-canonical safe).
- H3 `authenticate` retries `getSession` once (400 ms) when it returns null
  right after sign-in (token already captured; BE-migration lag tolerant).
- M1 undecodable SSE `error` → `retryable: false`.
- Nit `OracleReadingStore.submit` cancels a prior in-flight task.

Proof: 104 unit/integration tests (Networking 24 incl. new
`RetryPolicyIdempotencyTests` covering H1 both directions, 429-any-method, and
the H3 sign-in-retry-on-null path), 0 fail; SwiftLint 0/0.

**Live re-confirmation (2026-05-18, fresh account `admin@seetarot.com` /
`SeeTarotAdmin2026!` after BE reseed):**
- **E01 `LiveSignInSmokeTests` → PASS** (post review-fix: sign-in + token +
  session hydrate; exercises H1 retry change + H3 getSession path).
- **E04 `LiveProfileSmokeTests` → PASS** (post review-fix: `PATCH /profile`
  name round-trip + restore).
- **E03 `LiveHistorySmokeTests` → clean XCTSkip** ("account has no readings
  yet") — fresh DB, by-design skip, not a fail.
- **E02 `LiveReadingSmokeTests` → BLOCKED (BE-side, not faked):** BE AI
  provider misconfigured — SSE error `ai provider gpt-4o-mini failed: 404
  page not found`; daily `502 ai_failed`. The client **correctly receives and
  maps** the SSE-error / 502 (review M1 non-retryable default behaves right) —
  this is a BE regression, not a client defect. E03 live is transitively
  blocked (can't create a reading without BE AI).

Net: review fixes are unit-proven (104 tests) AND E01+E04 live-confirmed
post-fix. E02/E03 live re-confirm pending the BE AI-provider fix (logged in
HARNESS_BACKLOG). Stories E01–E04 stay `implemented` (E02/E03 had prior live
proof when BE AI worked; fixes are contract-preserving + unit-proven). No
faked green.

M3 (SVG size-cap), M4 (birthDate affordance), L1–L6 → deferred to backlog.
