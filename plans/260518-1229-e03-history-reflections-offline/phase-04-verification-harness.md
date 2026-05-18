# Phase 04 — Verification & Harness Update

## Context Links

- Story: `docs/stories/epics/E03-history-reflections-offline.md` (§Validation, §Evidence, Done Definition)
- Plan: `plan.md`; depends on Phases 01–03 complete
- Harness: `docs/TEST_MATRIX.md`, `docs/HARNESS_BACKLOG.md`, `docs/HARNESS.md`
- Live smoke pattern: `SeeTarotFeaturesTests/LiveReadingSmokeTests.swift`
  (env-gated, `XCTSkip` clean, never fakes green)
- Sim E2E tooling: XcodeBuildMCP + ios-simulator MCP (standing flow)

## Overview

- **Priority:** P1 (gates story `implemented`)
- **Status:** planned
- Run full test suite + lint, env-gated live smoke + simulator E2E vs live BE
  at `localhost:3001`, then update TEST_MATRIX / story Status / plan status and
  write a verification report. NO real-device testing.

## Key Insights

- Story Done Definition: do NOT mark `implemented` without **live proof**.
  Unit/stub proves logic; sim E2E vs live BE proves the contract.
- Live BE reachability + creds is a known blocker class (E01/E02 smoke). If
  unreachable: full unit/stub green + report the blocker, story stays
  `in_progress` (mirror E02 phase-04 `done*` precedent).
- Env-gated live test must `XCTSkip` cleanly — never fake green (dev rules).

## Requirements

Functional:
1. `swift test` ALL packages green (Core, Networking, Persistence, Features).
2. Lint clean (project lint command/script).
3. App builds + runs on simulator (XcodeBuildMCP `build_run_sim`).
4. Add env-gated `LiveHistorySmokeTests.swift` (mirror
   `LiveReadingSmokeTests`): sign in → `history()` page → `reading(id)` →
   `addReflection` → `reflections()` contains it → `setVisibility` round-trip.
   `XCTSkip` without creds.
5. Simulator E2E vs live BE `localhost:3001`: history loads + scrolls; open
   reading; add + see reflection; toggle visibility; **offline artwork**:
   warm a card, enable airplane mode (sim), reopen → art still renders.
6. Update `docs/TEST_MATRIX.md` E03 row with evidence; story §Evidence +
   Status; `plan.md` phase statuses (`ck plan check` or edit Status column).
7. Verification report → `plans/reports/`.
8. If harness friction surfaced → append `docs/HARNESS_BACKLOG.md`.

## Architecture

```
swift test (4 pkgs) → lint → build_run_sim
  → [creds set?] LiveHistorySmokeTests (else XCTSkip, note blocker)
  → sim E2E script (ios-simulator MCP): nav Home→History→scroll→detail
       →add reflection→toggle vis→airplane→offline art renders
  → update TEST_MATRIX row + story Status + plan statuses
  → verification report (pass/fail/blocked per Validation layer)
  → HARNESS_BACKLOG append if friction
```

## Related Code Files

Create:
- `SeeTarotFeaturesTests/LiveHistorySmokeTests.swift` (env-gated)

Modify:
- `docs/TEST_MATRIX.md` (E03 row → evidence)
- `docs/stories/epics/E03-history-reflections-offline.md` (§Evidence, Status)
- `plan.md` + phase files (status columns)
- `docs/HARNESS_BACKLOG.md` (only if friction)

Delete: none. (P04 owns tests + docs only; reads impl, never edits impl.)

## Implementation Steps

1. `swift test` each package; fix-or-report failures (do not skip to go green).
2. Run lint; fix style/compile.
3. `build_run_sim` (verify `session_show_defaults` first).
4. Write `LiveHistorySmokeTests.swift` (env-gated, clean skip).
5. With BE at `localhost:3001` (+ `SEE_TAROT_BASE_URL`/creds): run live smoke.
6. Sim E2E walkthrough incl. airplane-mode offline-artwork check.
7. Capture evidence (test output, screenshots); update TEST_MATRIX/story/plan.
8. Verification report (per-layer Unit/Integration/E2E/Platform/Release
   pass|fail|blocked + evidence pointers).
9. HARNESS_BACKLOG append if friction (e.g. contract-shape fetch, no query
   support in Endpoint, BE unreachable).

## Todo List

- [ ] `swift test` all 4 packages green
- [ ] Lint clean
- [ ] `build_run_sim` clean
- [ ] `LiveHistorySmokeTests.swift` (env-gated, skips clean)
- [ ] Live smoke vs BE :3001 (or document blocker)
- [ ] Sim E2E incl. offline-artwork airplane check
- [ ] TEST_MATRIX E03 row + story Status + plan statuses updated
- [ ] Verification report in `plans/reports/`
- [ ] HARNESS_BACKLOG appended if friction

## Success Criteria

- All 4 packages `swift test` green; lint clean; app runs on sim. Live smoke
  passes OR is cleanly skipped with documented blocker. Sim E2E confirms
  history paging, detail, reflection add+see, visibility toggle, AND offline
  artwork renders with airplane mode. TEST_MATRIX/story/plan updated with real
  evidence (no faked green). Report written.

## Risk Assessment

| Risk | L×I | Mitigation |
|---|---|---|
| Live BE `:3001` unreachable / no creds | M×M | env-gated XCTSkip; unit/stub green; document blocker; story `in_progress` (E02 precedent) |
| Sim airplane mode doesn't disable loader network | L×M | loader uses real URLSession → airplane blocks it; assert cached bytes returned |
| Test "passes" only because endpoint never hit | M×H | live smoke asserts concrete data (reflection echoes back, visibility flips); never assert-trivial |
| Lint/format churn balloons diff | L×L | scope lint to changed files; functionality over style (dev rules) |

## Security Considerations

- Live smoke creds via env only — never hard-coded/committed. No tokens,
  reflection bodies, or PII in report/screenshots. Confirm 401 path still
  routes to sign-out seam during E2E (sign out mid-session, expect redirect).

## Next

On full pass: story → `implemented` with evidence. On blocker: story
`in_progress`, blocker logged in report + HARNESS_BACKLOG; plan phase 04
`done*` (verification done, live proof pending) per E02 precedent.
