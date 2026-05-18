# 0007 Monetization — StoreKit 2 IAP (Ko-fi dropped)

Date: 2026-05-18

## Status

Accepted — supersedes the monetization clause of decision 0005 and
`docs/product/billing.md` "free launch / Ko-fi" framing. Implementation
DEFERRED (BE in planning, 5 phases).

## Context

0005 assumed v1 = free launch, quota from `/quota`, Ko-fi server-side only,
StoreKit deferred to a later brainstorm. BE has since reversed direction
(2026-05-18): **drop Ko-fi entirely**, build native **iOS In-App Purchase
subscriptions** — StoreKit 2 + App Store Server API + App Store Server
Notifications v2 (ASSN v2). BE is in the planning stage (5 phases); not yet
live.

## Decision

1. v1 monetization = **iOS IAP auto-renewable subscription** via StoreKit 2.
   Entitlement still surfaces through `GET /quota` / session (`tier`,
   `subscriptionStatus`, `subscriptionRenewsAt`) — the iOS quota/entitlement
   seam from 0005 is retained and is the integration point.
2. **Ko-fi is removed** from the product. `POST /kofi/claim` / `kofi*`
   endpoints and `kofiEmail` are no longer surfaced or planned in the app.
3. BE owns server-side receipt/transaction verification (App Store Server API)
   and ASSN v2 webhooks; the app does StoreKit 2 purchase + transaction
   listener + restore, then refreshes entitlement from `/quota`/session.
4. **Implementation deferred** (user instruction 2026-05-18). E05 stays
   `planned`; no IAP code now. The entitlement-gating seam stays inert until
   the BE IAP contract is published.

## Consequences

- Story E05 reframed: Ko-fi → StoreKit 2 IAP; remains `planned`/deferred.
- `billing.md` updated to the IAP direction; Ko-fi references retired.
- App Store 4.8 / IAP policy: digital subscription unlocked in-app MUST use
  IAP — now satisfied by design (no Ko-fi gating digital features).
- New cross-repo BE dependency: published IAP product IDs, the
  entitlement/verification contract, ASSN v2 → `/quota` propagation. Tracked
  in `HARNESS_BACKLOG.md`.
- No client work until BE publishes the IAP contract (honest deferral, not a
  silent gap).

## Alternatives Rejected

- Keep Ko-fi for v1: BE dropped it; would also risk App Store 4.8 if it gated
  digital features.
- Implement StoreKit 2 now against an unpublished BE contract: would be
  guess-coded / unverifiable — violates "no fake green".
