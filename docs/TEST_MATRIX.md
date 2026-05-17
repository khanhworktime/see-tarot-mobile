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
| E01 iOS foundation | Modular iOS skeleton, APIClient (Live+Stub), Better Auth Bearer email sign-in + session bootstrap, persistence/design/animation seams | yes (46) | yes (mock URLProtocol, Keychain, SwiftData) | partial (sim launch; live BE sign-in pending creds) | yes (iOS17 build, cold start ~0.57s) | in_progress | `plans/reports/verification-260517-e01-ios-foundation.md`; commits 0c65fb1..483c5bb |
| E02 spread+reading | Card spread + AI reading flow + animation | no | no | no | no | planned | none |
| E03 history/offline | History + offline artwork cache | no | no | no | no | planned | none |
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
