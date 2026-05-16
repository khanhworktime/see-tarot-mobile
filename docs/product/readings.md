# Readings — Spreads, Intents, Flow (v1)

Status: planned. Contract from BE doc §3.2–3.6.

## v1 Reading Types (user-confirmed)

| Type | kind | spread | intent | question |
| --- | --- | --- | --- | --- |
| Daily energy | `daily` | `single` | `general` (forced server-side) | none |
| Oracle 1-card | `oracle` | `single` | user-picked topic | required (10–500) |
| Oracle 3-card | `oracle` | `three` | user-picked topic | required (10–500) |

`celtic` spread is hidden in v1 (BE rejects `403 celtic_coming_soon`).

## Intents (topic picker — oracle only)

iOS owns all user-facing copy (BE stores no labels). Values:
`general, love, career, finances, feeling, action, yesNo`.

- Daily card: no topic picker (always `general`).
- Oracle: user picks one of the 7. `yesNo` is both a topic and a structural
  mode → always needs a question; renders verdict → reasoning → reflection.

Client-side validation mirrors server:
- `daily` ⇒ `spread=single`, no question.
- `oracle` ⇒ question required (10–500).
- `yesNo` ⇒ question required.

## Flow

- **Daily**: on open `GET /readings/daily-today`; if `204` → `POST
  /readings/daily { tz: TimeZone.current.identifier }` (synchronous, draws once
  per day, never re-rolls). `502 ai_failed|ai_empty` → retry UI.
- **Oracle**: form → `POST /readings/generate` SSE. Render `card` reveals (flip
  animation) first, stream `delta` into interpretation text, finalize on
  `done`. Cancel stream on view dismiss (aborts gen, saves quota).
- Entitlement errors: `403 daily_already_drawn | oracle_weekly_limit`.

## History & Reflections

- `GET /readings?cursor=&limit=` → `{ items: HistoryRow[], nextCursor }`.
- Detail `GET /readings/:id` (public viewable by anyone; private → 404 for
  non-owner). Share toggle `PATCH /readings/:id { isPublic }`.
- Reflections (journal, append-only, server-side): `POST /readings/:id/reflect
  { body 3–2000, mood ≤24? }`, `GET /readings/:id/reflections`.

## Quota

`GET /quota` → `{ tier, dailyRemaining, oracleRemaining }`. Render chips from
endpoint, never hardcode. Free launch: everyone effectively `plus`;
`oracleRemaining` is `null` on the wire when unlimited (`null`/missing ⇒
unlimited, hide the count; show a number only when finite).

## Offline

Cache hydrated past readings + card artwork (immutable, keyed by card id) for
offline replay. New draw + SSE require network.
