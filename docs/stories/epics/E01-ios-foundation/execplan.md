# Exec Plan — E01 iOS Foundation

## Goal

A modular, buildable iOS skeleton with every contract seam (networking, auth,
persistence, design, animation, SSE) wired against the now-concrete BE
contract, so E02–E05 build in parallel without rework.

## Scope

In scope:

- `ios/` Xcode workspace + local SPM packages.
- Networking core: `API.base` config, Keychain token, `authed()` builder,
  error decode, 401→sign-out, 429 backoff.
- Auth: email sign-up/in against live BE (capture `set-auth-token`),
  `/auth/get-session` launch bootstrap, `/auth-providers` gate, onboarding gate
  seam (`onboardedAt`).
- `DesignSystem`, `CardEngine` seam (+ Metal ambient spike), `Persistence`,
  SSE consumer seam.
- Build + run + lint; unit tests (stub + auth state machine) + 1 live
  integration smoke (email sign-in).

Out of scope:

- Reading/oracle/daily UI + flow (E02), history (E03), personalization impl
  (E04), monetization (deferred), Android (E06).
- Full Google sign-in if BE redirect URI unresolved (seam only, defer flow).

## Risk Classification

Risk flags: Auth, External systems (Google OAuth), Public API contract,
Cross-platform, Multi-domain. (Weak-proof flag cleared — contract concrete.)

Hard gates: Auth.

## Work Phases

1. Discovery — confirm iOS target, package boundaries, BE base URL.
2. Design — package graph + protocol surface (this folder).
3. Validation planning — see `validation.md`.
4. Implementation — packages, app shell, real APIClient + stub, auth, seams.
5. Verification — build, lint, unit + live sign-in smoke, simulator run.
6. Harness update — TEST_MATRIX rows, evidence, backlog.

## Stop Conditions

Pause for human confirmation if:

- BE behavior diverges from `api-reference-mobile-swift.md`.
- Google redirect URI / `set-auth-token` delivery blocks auth meaningfully.
- Approach A architecture needs changing.
- Any validation requirement would be weakened.
