---
title: E02 Spread + AI Reading Flow
status: in_progress
lane: normal
created: 2026-05-17
story: docs/stories/epics/E02-spread-reading-flow.md
blockedBy: []
blocks: []
---

# E02 Spread + AI Reading Flow — Implementation Plan

Daily 1-card + Oracle (1 & 3-card) reading flow with card-flip animation and
streaming AI interpretation. Builds on E01 networking/SSE/Core seams.
History list + reflections journal are E03 (out of scope).

## Authoritative Context

- Story: `docs/stories/epics/E02-spread-reading-flow.md`
- Locked contract: `docs/product/readings.md`, `api-conventions.md`
- Decisions: `0004` (Core Animation for cards), `0005` (BE contract)
- BE: `see-tarot-be/docs/api-reference-mobile-swift.md` §3.2–3.3, §4, §5

## Constraints

- iOS 17+. SwiftUI + `@Observable`. Core Animation flip via
  `UIViewRepresentable` (NOT Metal — decision 0004).
- Reuse E01 `APIClientProtocol`/`LiveAPIClient.stream`/Core models.
- File <200 lines; `.swift` PascalCase. No secrets.
- Out of scope: history (E03), reflections (E03), monetization, Android.

## Phases

| # | Phase | Status | Output |
|---|-------|--------|--------|
| 01 | [Reading API surface + stores](phase-01-reading-api-and-stores.md) | done | APIClient reading methods, Daily/Oracle stores + tests |
| 02 | [Card flip animation](phase-02-card-flip-animation.md) | done | Real CardSurface (Core Animation) replacing placeholder |
| 03 | [Reading UI screens](phase-03-reading-ui-screens.md) | done | Home daily section, Oracle form, Reading view, QuotaChip |
| 04 | [Verification & harness update](phase-04-verification-harness-update.md) | pending | Tests, sim E2E, TEST_MATRIX/evidence |

## Dependencies

Linear 01→02→03→04. 02 is parallelizable with 01 (independent), kept linear
for a solo pass.

## Success Criteria

- Daily flow: daily-today 204→draw, render, 502 retry, 403 handled.
- Oracle flow: validated form → SSE → card reveals (flip) → streamed text →
  done; error retry; cancel-on-dismiss aborts.
- Quota chip from `/quota` (null⇒unlimited hidden).
- 60fps flip; unit tests (stub SSE + state machines) green; app builds + runs.
- `docs/TEST_MATRIX.md` E02 row → evidence; story Status updated.

## Stop Conditions (harness)

Pause if: BE SSE shape diverges from `api-reference-mobile-swift.md` §4;
animation requires Metal (it must not — Core Animation only); validation would
be weakened; architecture (Approach A) changes.

## Unresolved Questions

- Live SSE E2E needs BE reachable + creds (same blocker as E01 smoke);
  unit/stub proof covers logic meanwhile.
