# Phase 03 — Networking Core

Context: `plan.md`, BE doc §2/§4, `docs/product/api-conventions.md`.

## Overview

Priority: P0. Status: done (2026-05-17).
`SeeTarotNetworking`: `APIClientProtocol`, real `URLSession` client, request
builder, error decoding, 401/429 handling, `set-auth-token` capture, and a
reusable SSE consumer primitive (not UI-wired — consumed in E02).

Evidence: `swift test` SeeTarotNetworking → 10/10 passed (URLProtocol mock:
auth-providers, token capture, 401+hook, 400 issues, 403 entitlement,
429→retry→200, sign-in→hydrate, sign-out clears, SSE parser). App BUILD
SUCCEEDED; lint no errors. Note: added `.macOS(.v13)` to all package
manifests so host `swift test` resolves modern availability (app still
builds iOS via xcodebuild).

## Key Insights

- `set-auth-token` arrives in the response header on sign-in/up — capture
  centrally on every response.
- SSE endpoint is a POST with streamed body → `EventSource` libs don't work;
  use `URLSession.bytes(for:)` line parsing (BE doc §4).
- 401 ⇒ drop token + route to sign-in (publish an auth-invalidated signal).
- Rate limits: 120/min global, 60/min `/auth/*`; handle 429 with backoff.

## Requirements

- `APIClientProtocol`: typed methods for E01 surface (`authProviders`,
  `signUpEmail`, `signInEmail`, `getSession`, `signOut`) + generic
  `send<T:Decodable>(Endpoint)` + `stream(Endpoint) -> AsyncThrowingStream<SSEEvent,Error>`.
- `LiveAPIClient` (URLSession) + `StubAPIClient` (deterministic fixtures).
- `authed()` request builder: base URL from `AppConfig`, JSON content type,
  `Authorization: Bearer` when token present.
- Central response handling: capture `set-auth-token` → token store delegate;
  decode `{error,message,issues}` on non-2xx → typed `APIError`; 401 →
  `onUnauthorized` hook; 429 → exponential backoff retry (cap attempts).
- SSE primitive: parse `event:`/`data:` frames, yield `SSEEvent`, finish on
  `done`/`error`, `onTermination` cancels task (aborts server gen).

## Architecture

- Token storage abstracted via `TokenStoring` protocol (impl in Phase 04
  Keychain) — Networking depends on the protocol, not Keychain.
- `Endpoint` value type (path, method, body, auth required) keeps client DRY.
- No third-party deps (KISS).

## Related Code Files

Create:
- `.../SeeTarotNetworking/APIClientProtocol.swift`
- `.../Endpoint.swift`
- `.../LiveAPIClient.swift` (split if >200 lines: `+Auth`, `+SSE`)
- `.../StubAPIClient.swift`
- `.../RequestBuilder.swift` (`authed()`)
- `.../ResponseHandler.swift` (envelope decode, 401, token capture)
- `.../RetryPolicy.swift` (429 backoff)
- `.../TokenStoring.swift` (protocol)
- `.../SSEParser.swift`
- `Tests/SeeTarotNetworkingTests/*` (URLProtocol mock + stub tests)

## Implementation Steps

1. `TokenStoring` protocol + in-memory test impl.
2. `Endpoint` + `RequestBuilder.authed()`.
3. `ResponseHandler`: status routing, envelope decode, token capture, 401 hook.
4. `RetryPolicy`: 429 + transient network, capped exponential backoff + jitter.
5. `LiveAPIClient` implementing protocol via URLSession async.
6. `SSEParser` + `stream()` using `URLSession.bytes(for:)`; cancellation aborts.
7. `StubAPIClient` returning fixtures (incl. an SSE script).
8. Tests: `URLProtocol` mock for success/400(issues)/401/429-then-200; SSE
   parser frame sequence (`card`→`delta`×N→`done`/`error`); token capture.

## Todo List

- [ ] Protocol + Endpoint + RequestBuilder
- [ ] ResponseHandler (envelope/401/token capture)
- [ ] RetryPolicy (429 backoff)
- [ ] LiveAPIClient + StubAPIClient
- [ ] SSEParser + stream() with cancel-on-terminate
- [ ] Networking unit tests green (mock + stub)

## Success Criteria

`swift test` passes; mock-driven coverage of success/error/401/429/SSE; no
network calls in unit tests; SSE primitive cancels cleanly.

## Risk Assessment

- `set-auth-token` delivery (header vs body) unverified → capture from header
  per BE doc; add a TODO + assertion to verify in Phase 05 live smoke; keep
  capture point single-sourced for easy change.

## Security Considerations

- Token only via `TokenStoring` (Keychain in Phase 04); never logged. Redact
  `Authorization` in any debug logging.

## Next Steps

Phase 04 provides the Keychain `TokenStoring` impl + persistence/cache.
