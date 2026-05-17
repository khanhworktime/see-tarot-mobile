# US-E02 Spread + AI Reading Flow

## Status

in_progress

## Lane

normal (strong validation)

Intake: External systems (AI SSE, consume-only), Public contract (consume),
Weak proof (new). No hard gate (auth done E01; no data migration; iOS-only).

## Product Contract

User can draw a **Daily** 1-card energy reading (once/day, synchronous) and an
**Oracle** reading (1 or 3 cards) by picking a topic + question, watching cards
reveal (flip animation) then the AI interpretation stream in. Quota/tier shown
from `/quota`. Out of scope: history list, reflections journal (E03).

## Relevant Product Docs

- `docs/product/readings.md` (locked v1 contract)
- `docs/product/api-conventions.md` (SSE §4, errors)
- `docs/product/overview.md`, `billing.md` (quota display)

## Acceptance Criteria

- Daily: open authenticated Home → `GET /readings/daily-today`; if `204` →
  `POST /readings/daily {tz}`; render card + interpretation; `502
  ai_failed|ai_empty` → retry UI; `403 daily_already_drawn` handled.
- Oracle: topic picker (7 intents, iOS-owned copy) + question (10–500, `yesNo`
  always needs question); `POST /readings/generate` SSE → card reveals (flip)
  first, then `delta` stream into interpretation, finalize on `done`; `error`
  event → retry; cancel on view dismiss (aborts gen).
- Client-side validation mirrors BE before request.
- Quota chip from `GET /quota` (`null` oracleRemaining ⇒ unlimited, hidden).
- 60fps card flip animation (Core Animation per decision 0004).
- Unit tests (stub SSE script + state machine); app builds + runs on sim.

## Design Notes

- Commands/Queries: extend `APIClientProtocol` — `dailyToday()->Reading?`
  (204⇒nil), `drawDaily(tz)->Reading`, `generate(input)->SSE stream`,
  `quota()->Quota`.
- Domain: reuse Core models; `ReadingStore` (`@Observable`) per-flow state
  machines (idle→loading→revealing→streaming→done|error|entitlementBlocked).
- UI: Daily section in `HomeView`; `OracleFormView` (topic+question);
  `ReadingView` (card reveals + streaming text); `QuotaChip`.
- Animation: real `CardSurface` impl = UIKit/Core Animation flip via
  `UIViewRepresentable` (decision 0004); replaces `PlaceholderCardSurface`.
- SSE consumer = existing `LiveAPIClient.stream` seam from E01.

## Validation

| Layer | Expected proof |
| --- | --- |
| Unit | ReadingStore daily/oracle state machines; SSE script (card→delta×N→done/error); client validation; quota null⇒unlimited |
| Integration | Stub SSE end-to-end; mock URLProtocol for daily 204/200/403/502 |
| E2E | Sim: authenticated → daily renders; oracle form→reveal→stream (against live BE when creds exist) |
| Platform | iOS17 build; 60fps flip; cancel-on-dismiss aborts stream |
| Release | full suite + lint before merge |

## Harness Delta

Story sliced from E02 (was unsliced). Backlog/TEST_MATRIX updated. Depends on
E01 networking/SSE/Core seams (in_progress; live-smoke blocker is orthogonal —
E02 builds against the unit-proven stack).

## Evidence

Verified 2026-05-17 — `plans/reports/verification-260517-e02-spread-reading-flow.md`.
62 tests (61 pass / 0 fail / 1 live-smoke skip); iOS BUILD SUCCEEDED; 0 source
lint; DEBUG stub composition visually confirms Home (quota `Oracle ∞`, daily
flip card) + Oracle form (validation/celtic-hidden/spread). Commits
7826846 (API+stores), 59a962c (flip animation), a547773 (UI screens), Phase 04.
Status stays `in_progress`: live BE SSE/daily E2E pending creds (not faked).
