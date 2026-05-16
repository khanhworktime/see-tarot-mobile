# Billing — v1 Free Launch (StoreKit deferred)

Status: planned. Reconciled per decision 0005.

## v1

- Free launch: every authed user is effectively `plus`.
- App renders quota/tier from `GET /quota` (`{ tier, dailyRemaining,
  oracleRemaining }`) — never hardcode. `oracleRemaining` is **`null` on the
  wire** when unlimited (`Infinity`→`JSON.stringify`→`null`): `null`/missing ⇒
  unlimited, hide count; show number only when finite. Free launch ⇒ almost
  always `null`.
- User object carries `tier`, `subscriptionStatus`, `subscriptionRenewsAt`,
  `kofiEmail` (display only in v1).
- Ko-fi is server-side (`POST /kofi/webhook` not called by app). `POST
  /kofi/claim { email }` MAY be surfaced to link a Ko-fi supporter email —
  treat as account-link, not an in-app purchase.

## Deferred (separate brainstorm)

StoreKit 2 / paid tiers / IAP not decided. User: tiers TBD. Before any paid
tier:

- App Store policy: in-app unlock of digital content must use IAP — Ko-fi
  cannot gate digital features purchased inside the app. Resolve in
  monetization brainstorm.
- iOS keeps an entitlement-gating seam reading from `/quota`/session so a
  paywall can be added without rework.

## Open Questions

- Tier model, prices, trial.
- Web/Ko-fi ↔ future IAP entitlement reconciliation on shared account.
