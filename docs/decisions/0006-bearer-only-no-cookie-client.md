# 0006 Bearer-Only, Cookie-Free iOS Networking

Date: 2026-05-18

## Status

Accepted (refines 0004 networking; consistent with 0005 Better Auth Bearer)

## Context

Live smoke against the real BE (local `localhost:3001`, Better Auth, BE
migrating Fastify → NestJS) surfaced a real client bug that unit/stub proof
could not — exactly why the harness forbids faking green.

Better Auth sign-in returns BOTH a `set-auth-token` header (the bearer token)
AND a `Set-Cookie: tarot.session_token` session cookie. The iOS client used
`URLSession.shared`, whose `HTTPCookieStorage.shared` is disk-backed and
persists that cookie across requests (and across process runs on macOS / app
launches on device). On any subsequent request the cookie was auto-attached;
Better Auth then enforces CSRF on cookie-authenticated state-changing calls and
rejects them with `403 {"code":"MISSING_OR_NULL_ORIGIN"}` (no Origin header
from a native client). Result: first sign-in worked, then `/quota`,
`/readings/*`, and re-sign-in failed 403. curl (no cookie jar) always passed,
masking the bug at the contract-doc layer.

## Decision

The iOS API client is **bearer-only and cookie-free** by design:

1. `RequestBuilder` sets `httpShouldHandleCookies = false` on every request —
   the BE never sees a session cookie; auth is solely the captured
   `set-auth-token` bearer.
2. `LiveAPIClient` default session = `makeBearerSession()`:
   `URLSessionConfiguration.ephemeral`, `httpCookieStorage = nil`,
   `httpShouldSetCookies = false`, `httpCookieAcceptPolicy = .never`.
3. Injected sessions (unit tests / `URLProtocol` mocks) are unaffected.

## Consequences

- Eliminates the CSRF/Origin 403 class entirely; client stays pure bearer,
  matching Better Auth bearer mode and 0005.
- No reliance on cookie behaviour that may shift during the BE NestJS
  migration (see memory: BE migrating to NestJS).
- Verified: E01 live sign-in + E02 live quota/daily/Oracle-SSE smoke all green
  against the live BE after the fix (`verification-260518-1201-...`).

## Alternatives Rejected

- Sending an `Origin` header to satisfy CSRF: fragile, couples the native
  client to web CSRF semantics; bearer mode is meant to be cookie-independent.
- Per-call cookie clearing: leaky; one missed path reintroduces the 403.
