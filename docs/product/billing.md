# Billing — iOS IAP Subscription (deferred)

Status: planned, deferred. Direction set by decision 0007 (supersedes the
0005 free-launch / Ko-fi framing).

## v1 direction

- Monetization = **iOS In-App Purchase auto-renewable subscription** (StoreKit
  2). Ko-fi is **dropped** (no `kofi*` endpoints, no `kofiEmail` surfaced).
- Entitlement is read from `GET /quota` + session (`tier`,
  `subscriptionStatus`, `subscriptionRenewsAt`) — never hardcoded.
  `oracleRemaining` is `null` on the wire when unlimited (`Infinity` →
  `JSON.stringify` → `null`): `null`/missing ⇒ unlimited (hide count); show a
  number only when finite.
- BE owns receipt/transaction verification (App Store Server API) + ASSN v2
  webhooks → propagates entitlement to `/quota`/session. App does StoreKit 2
  purchase + `Transaction` listener + restore, then refreshes entitlement.
- iOS keeps the entitlement-gating seam (reads `/quota`/session) so a paywall
  drops in without rework.

## Deferred (no client work yet)

Implementation deferred per user (2026-05-18); BE IAP contract in planning
(5 phases), not live. E05 stays `planned`. No StoreKit code until BE publishes:

- Subscription product IDs + tier mapping.
- Entitlement/verification contract + ASSN v2 → `/quota` propagation timing.
- Restore / cross-platform (web) entitlement reconciliation on shared account.

## Open Questions

- Tier model, prices, trial / introductory offer.
- Grace period / billing-retry handling surfaced to the app.
