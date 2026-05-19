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
| E01 iOS foundation | Modular iOS skeleton, APIClient (Live+Stub), Better Auth Bearer email sign-in + session bootstrap, persistence/design/animation seams | yes (46) | yes (mock URLProtocol, Keychain, SwiftData) | yes (live BE sign-in smoke green; `set-auth-token` + get-session hydration confirmed) | yes (iOS17 build, cold start ~0.57s) | implemented | `verification-260518-1201-live-be-close-e01-e02.md`; commits 0c65fb1..483c5bb + live-close; auth surfaces re-skinned 2026-05-19 (E07) |
| E02 spread+reading | Daily + Oracle reading flow (SSE), card flip animation, quota display | yes (Core/Net/Features stores, FlipDecision, IntentCopy, QuotaDisplay) | yes (stub SSE script, mock URLProtocol) | yes (live BE: real Oracle SSE card→delta→done, quota, daily draw) | yes (iOS17 build; flip via Core Animation) | implemented | `verification-260518-1201-live-be-close-e01-e02.md`; commits 7826846..a547773 + live-close; spreads/reading surfaces re-skinned 2026-05-19 (E07) |
| E03 history/offline | Cursor-paginated history, reading detail, append-only reflections, owner visibility toggle, bounded offline artwork cache | yes (Core/Net/Persistence/Features: pagination, validation, eviction, decode) | yes (mock URLProtocol history/reflect/visibility; ArtworkCache disk round-trip + eviction) | yes (live BE: history→reading→reflection echo→visibility round-trip; sim nav Home→History→Detail) | yes (iOS17 build; sim run) | implemented | `plans/reports/verification-260518-1229-e03-history-reflections-offline.md`; commits 9e760ab..34d2b8f + phase 04; history surfaces re-skinned 2026-05-19 (E07) |
| E04 personalization | Client profile edit (PATCH /profile) — name/birthDate/timezone/intent; session refresh. AI personalization itself is BE-side (folds profile+reflections, no client work) | yes (Core/Net/Features: ProfileValidation bounds, dirty-tracking, store SM, decode) | yes (mock URLProtocol PATCH 200/400/401, only-dirty body, getSession re-hydrate) | yes (live BE: PATCH /profile name round-trip + restore; sim Profile renders live + validation + 401→sign-out) | yes (iOS17 build; sim run) | implemented | `plans/reports/verification-260518-1635-e04-profile-personalization.md`; commits 1050716 + phase 02; profile surfaces re-skinned 2026-05-19 (E07) |
| E07 UI redesign (cosmic) | Presentation-only re-skin: DesignSystem (cosmic navy + moonlight silver palette, Cinzel+Lora fonts bundled), particle starfield (TimelineView+Canvas), glassmorphic surfaces (contrast-guarded inner scrim), 3D card flip + flip animation, spread ritual (shuffle→fan→hold→deal), SSE interpretation block reveal, immersive hub + bottom-bar tabs (Today·Oracle·History·Profile). No contract/state/nav/API change. | yes (ContrastRatio 10/10, ParticleSystem, CardBackURL, InterpretationBlocks, spread layout tests) | yes (mock SSE block parse; card back URL; particle seeded determinism; card dims 95×155) | yes (live BE E01–E04 re-verified; all surfaces smoke-tested; 177/177 SPM tests pass) | yes (iOS17 build clean; 3 known pre-existing warnings; cold start ≈0.57s unchanged) | implemented | `plans/reports/tester-260519-1046-ui-redesign.md`; `plans/reports/code-reviewer-260519-1046-ui-redesign.md`; commits cbb3826 + phase 01–08 |
| E05 monetization | StoreKit 2 IAP subscription (Ko-fi dropped); entitlement via /quota+session. Deferred — BE IAP contract in planning (decision 0007) | no | no | no | no | planned | none (deferred) |
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
