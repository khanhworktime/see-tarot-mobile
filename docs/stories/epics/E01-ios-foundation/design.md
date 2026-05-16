# Design — E01 iOS Foundation

## Domain Model

- `Session` (Bearer token + user: id, name, email, `tier`,
  `subscriptionStatus`, `birthDate`, `timezone`, `preferredIntent`,
  `onboardedAt`).
- `CardArtworkRef` (card id → cached asset).
- Spread/reading/reflection domain models per BE doc §5 — declared in `Core`,
  exercised in E02/E03.

## Application Flow

- Launch → read token (Keychain) → `GET /auth/get-session` → if user &
  `onboardedAt==null` route to onboarding seam, else Home; if no/invalid →
  sign-in.
- Email sign-up/in → capture `set-auth-token` header → Keychain → session in
  `@Observable` app state. Google gated on `GET /auth-providers` (seam only in
  E01). Design assumption = native idToken flow (app → Google SDK idToken →
  BE); BE has no native config yet, final flow is a BE decision in the auth
  phase, so full Google flow may slip to E02. Email/password is the E01
  end-to-end path and is unblocked.

## Interface Contract

`APIClientProtocol` (Networking):

- `authProviders() -> {google:Bool}`
- `signInEmail/signUpEmail -> Session` (captures `set-auth-token`)
- `getSession() -> Session?`
- `signOut()`
- Generic `authed(path,method,body)` builder; error decode `{error,message,
  issues}`; `401`→sign-out; `429`→backoff.
- SSE seam: `AsyncThrowingStream<SSEEvent,Error>` via
  `URLSession.bytes(for:)`, cancel-on-terminate (impl consumed in E02).
- Real impl targets live BE; deterministic stub for unit tests.

## Data Model

- Keychain: `see-tarot.session-token`.
- SwiftData: cache entities placeholder (reading/history models land E02/E03).
- Artwork disk cache: immutable, keyed by card id; eviction deferred.

## UI / Platform Impact

- iOS 17+. SwiftUI shell + navigation. `DesignSystem` package: tokens
  (color/typography/spacing/motion), native HIG base + brand accent.
- `CardEngine`: `UIViewRepresentable` seam + Metal ambient-bg spike (no real
  card animation yet).
- Capabilities: Associated Domains / URL scheme for Google callback (doc only,
  pending BE redirect decision). No Sign in with Apple capability.

## Observability

- Structured client logging, no PII. Network error categorization (4xx/5xx/
  SSE error). No audit at foundation.

## Alternatives Considered

1. Stub-only (no live BE in E01) — rejected; contract now concrete, real
   email/password sign-in is the cheapest end-to-end proof.
2. SwiftData vs GRDB — SwiftData (native, KISS); revisit if query needs grow.
3. EventSource lib for SSE — rejected; POST-streamed body needs
   `URLSession.bytes`.
