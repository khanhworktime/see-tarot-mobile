# Test Matrix

This file maps product behavior to proof.

No product behavior has been defined or implemented yet. Do not mark a row
implemented until tests or validation evidence exist.

## Status Values

| Status | Meaning |
| --- | --- |
| planned | Accepted as intended behavior, not implemented |
| in_progress | Actively being built |
| implemented | Implemented and proof exists |
| changed | Contract changed after earlier implementation |
| retired | No longer part of the product contract |

## Matrix

| Story | Contract | Unit | Integration | E2E | Platform | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E01 iOS foundation | Modular iOS skeleton, APIClient (Live+Stub), Better Auth Bearer email sign-in + session bootstrap, persistence/design/animation seams | yes (46) | yes (mock URLProtocol, Keychain, SwiftData) | yes (live BE sign-in smoke green; `set-auth-token` + get-session hydration confirmed) | yes (iOS17 build, cold start ~0.57s) | implemented | `verification-260518-1201-live-be-close-e01-e02.md`; commits 0c65fb1..483c5bb + live-close |
| E02 spread+reading | Daily + Oracle reading flow (SSE), card flip animation, quota display | yes (Core/Net/Features stores, FlipDecision, IntentCopy, QuotaDisplay) | yes (stub SSE script, mock URLProtocol) | yes (live BE: real Oracle SSE card→delta→done, quota, daily draw) | yes (iOS17 build; flip via Core Animation) | implemented | `verification-260518-1201-live-be-close-e01-e02.md`; commits 7826846..a547773 + live-close |
| E03 history/offline | Cursor-paginated history, reading detail, append-only reflections, owner visibility toggle, bounded offline artwork cache | yes (Core/Net/Persistence/Features: pagination, validation, eviction, decode) | yes (mock URLProtocol history/reflect/visibility; ArtworkCache disk round-trip + eviction) | yes (live BE: history→reading→reflection echo→visibility round-trip; sim nav Home→History→Detail) | yes (iOS17 build; sim run) | implemented | `plans/reports/verification-260518-1229-e03-history-reflections-offline.md`; commits 9e760ab..34d2b8f + phase 04 |
| E04 personalization | BE-centric: profile + reflections; provider seam (AI module future BE) | no | no | no | no | planned | none |
| E05 monetization | Deferred — quota/tier display from /quota; paywall TBD (separate brainstorm) | no | no | no | no | planned | none |
| E06 android | Android app mirrors iOS contract | no | no | no | no | planned | none |

## Evidence Rules

- Unit proof covers pure domain and application rules.
- Integration proof covers backend enforcement, data integrity, provider
  behavior, jobs, or service contracts.
- E2E proof covers user-visible browser flows.
- Platform proof covers only shell, deployment, mobile, desktop, or runtime
  behavior that cannot be proven in lower layers.
- A story can be implemented without every proof column if the story packet
  explains why.
