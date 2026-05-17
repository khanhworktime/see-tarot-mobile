# Phase 04 — Verification & Harness Update

Context: `plan.md`, story `E02-spread-reading-flow.md`, `docs/TEST_MATRIX.md`.

## Overview

Priority: P0 (closes story). Status: pending.
Full verification, then harness evidence per Done Definition. Honest status —
live SSE E2E pending BE (same blocker class as E01); unit/stub proof covers
logic.

## Requirements

- Full `swift test` all packages green (0 fail; document any skip).
- `xcodebuild` iOS build SUCCEEDED; each package standalone.
- SwiftLint 0 errors.
- Sim run: authenticated path with `StubAPIClient` SSE script → screenshot
  daily + oracle reveal + streaming (a debug/preview composition root).
- Manual 60fps flip observation noted.
- Update `docs/TEST_MATRIX.md` E02 row (proof columns; status `implemented`
  ONLY if proof exists, else `in_progress` + reason).
- Update story `Status` + Evidence; plan phase statuses.
- Verification report `plans/reports/verification-260517-e02-...md`.
- Friction → `docs/HARNESS_BACKLOG.md` if any.

## Implementation Steps

1. Run unit/integration; capture counts.
2. Build + lint.
3. Stub-driven sim E2E + screenshots; flip observation.
4. TEST_MATRIX honest update; story/plan status.
5. Verification report (verified vs not-attempted, unresolved).

## Todo List

- [ ] All tests green (counts recorded)
- [ ] iOS build + lint clean
- [ ] Stub sim E2E + screenshots; flip noted
- [ ] TEST_MATRIX E02 + story/plan status
- [ ] Verification report written

## Success Criteria

Tests green; TEST_MATRIX reflects real proof (no inflation); story closed only
if criteria genuinely met; report states verified vs deferred.

## Risk / Security

- Never mark `implemented` without proof (dev rules). Live SSE E2E deferred =
  documented blocker, not weakened. Scan evidence for leaked secrets.

## Next

E02 done → E03 (history + reflections + offline).
