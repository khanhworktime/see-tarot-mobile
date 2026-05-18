# Verification Report — Live BE Close E01 + E02

Date: 2026-05-18
Scope: Close E01 + E02 to `implemented` via live smoke against the real BE.
Lanes: E01 high-risk, E02 normal.

## Result

E01 + E02 **closed to `implemented`**. Live smoke against the running backend
(`http://localhost:3001`, Better Auth, BE mid-migration Fastify→NestJS) is
green. Closing surfaced a real client bug that unit/stub proof could not — it
was root-caused and fixed, not papered over (harness: never fake green).

## BE Connectivity

- `/health` 200; `/auth-providers` → `{"google":true,"apple":true}`.
- Drift noted: `apple:true` vs decision 0005 (SiwA dropped). iOS client does
  email/pw + Google only, so non-blocking. Flagged for contract reconciliation
  while BE migrates to NestJS (tarot-contract MCP = authoritative source).

## Bug Found & Fixed (decision 0006)

Better Auth sign-in returns a `set-auth-token` bearer AND a
`Set-Cookie tarot.session_token`. Client used `URLSession.shared` (disk-backed
`HTTPCookieStorage.shared`) → cookie auto-attached on later requests → Better
Auth enforced CSRF → `403 MISSING_OR_NULL_ORIGIN` on `/quota`, `/readings/*`,
re-sign-in. curl (no jar) masked it at the doc layer.

Fix: bearer-only, cookie-free client —
- `RequestBuilder`: `httpShouldHandleCookies = false` every request.
- `LiveAPIClient.makeBearerSession()`: ephemeral cfg, `httpCookieStorage=nil`,
  `httpShouldSetCookies=false`, `httpCookieAcceptPolicy=.never` (default).
- Injected/mock sessions unaffected.

Diagnosis method: curl matrix (token-only vs cookie+bearer vs stale cookie)
isolated the 403 to the cookie path; a temp `DiagAuthProbe` confirmed, then
was deleted.

## Evidence

### Live smoke (host `swift test`, `SEE_TAROT_BASE_URL=http://localhost:3001`)

| Test | Result |
| --- | --- |
| `LiveSignInSmokeTests` (E01: sign-in, set-auth-token, get-session) | pass (0.11s) |
| `LiveReadingSmokeTests.testLiveOracleSSEStream` (E02: real SSE card→delta→done) | pass (10.5s) |
| `LiveReadingSmokeTests.testLiveQuotaAndDaily` (E02: quota `plus`, daily draw) | pass (18.2s) |

### Regression (no live env → live tests skip)

| Package | Tests | Result |
| --- | --- | --- |
| SeeTarotCore | 14 | pass |
| SeeTarotNetworking | 10 | pass |
| SeeTarotFeatures | 25 | 22 pass, 3 live skip |

Total 64: live env → 64 pass; no env → 61 pass + 3 skip. Persistence (4),
DesignSystem (4), CardEngine (7) unchanged from prior verification.

## Acceptance

| Criterion | Status |
| --- | --- |
| E01 live email sign-in + set-auth-token + session hydrate | met (live) |
| E01 BE open item: confirm `set-auth-token` on live build | met (header delivered, token captured) |
| E02 live Oracle SSE card→delta→done | met (live) |
| E02 live quota (null⇒unlimited path: `plus`) + daily draw | met (live) |
| No regression in unit/integration suites | met |

## New / Added

- `LiveReadingSmokeTests.swift` (env-gated E02 live E2E, durable proof).
- Decision `0006-bearer-only-no-cookie-client.md`.
- Config for on-device testing: Debug `API_BASE_URL=http://192.168.1.50:3001`,
  `Info.plist NSAllowsLocalNetworking`, `project.yml` DEVELOPMENT_TEAM
  2BMZMX95V3 + automatic signing (separate from this close; same batch).

## Not Attempted / Deferred

- Physical-device run (signing wired; no device connected this session).
- Animated-flip frame capture (logic-tested; needs device recording).
- Contract reconciliation for `apple:true` drift + full NestJS-migration
  re-audit via tarot-contract MCP — folds into E03/E04 prep.

## Unresolved Questions

- BE migration Fastify→NestJS may shift error envelopes / headers; re-run
  this live smoke after migration milestones.
- `.mcp.json` carries a machine-absolute path to `see-tarot-be` — left
  untracked (not committed) to avoid leaking a local path into the repo.
