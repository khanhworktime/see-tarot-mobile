# Phase 07 — Verification & Harness Update

Context: `plan.md`, story `validation.md`, `docs/TEST_MATRIX.md`,
`~/.claude/rules/documentation-management.md`.

## Overview

Priority: P0 (closes the story). Status: pending.
Run full verification, then update harness evidence per the Done Definition.

## Key Insights

- Harness Done Definition: change complete, docs/stories/test-matrix current,
  validation run, final report states what changed + what was not attempted.
- Live sign-in smoke may be `pending` if no BE test creds — record honestly,
  do not fake green.

## Requirements

- `xcodebuild build` + `xcodebuild test` (all package + Features tests) green.
- SwiftLint: no errors (warnings acceptable per dev rules).
- Manual simulator E2E: launch → sign-up/in → (onboarding route) → Home →
  relaunch restores → sign-out. Cold start measured (<2s skeleton baseline).
- Each SPM package `swift build` standalone.
- Update `docs/TEST_MATRIX.md` E01 row (Unit/Integration/E2E/Platform as
  achieved; Status `implemented` only if proof exists, else `in_progress` with
  reason).
- Fill `docs/stories/epics/E01-ios-foundation/validation.md` Acceptance
  Evidence (commands, logs, recording links).
- Update story `Status` + `plan.md` phase table to completed.
- Capture any harness friction → `docs/HARNESS_BACKLOG.md`.

## Related Code Files

Modify (docs only):
- `docs/TEST_MATRIX.md`
- `docs/stories/epics/E01-ios-foundation/validation.md`
- `docs/stories/epics/E01-ios-foundation/overview.md` (Status)
- `plan.md` (phase statuses)
- `docs/HARNESS_BACKLOG.md` (if friction)
Create:
- `plans/reports/verification-260517-{slug}.md` (results + unresolved)

## Implementation Steps

1. Run unit/integration tests; capture output.
2. Run live sign-in smoke if creds available; else mark pending.
3. Manual E2E walkthrough on simulator; record cold-start + a short capture.
4. Lint; ensure no errors.
5. Update TEST_MATRIX row with honest statuses + evidence links.
6. Fill validation.md Acceptance Evidence; bump story + plan statuses.
7. Write verification report (what changed, what was not attempted, unresolved
   questions: `set-auth-token` confirmation result, Google deferred, BE creds).
8. Note friction in HARNESS_BACKLOG if any.

## Todo List

- [ ] All tests green (unit + integration)
- [ ] Live sign-in smoke run or marked pending (honest)
- [ ] Manual E2E + cold-start recorded
- [ ] Lint clean (no errors)
- [ ] TEST_MATRIX E01 row updated with evidence
- [ ] validation.md evidence + story/plan status bumped
- [ ] Verification report written

## Success Criteria

Tests green; TEST_MATRIX reflects real proof (no inflated status); validation
evidence recorded; report states verified vs not-attempted; story marked done
only if criteria genuinely met.

## Risk Assessment

- Temptation to mark `implemented` without live proof → forbidden; use
  `in_progress` + documented blocker (dev rules: never fake green).

## Security Considerations

- Ensure no test credentials, tokens, or `.env` committed in evidence/logs
  (scan before writing report; `.gitignore` covers `*.env`).

## Next Steps

E01 done → unblocks E02 (reading/oracle/daily flow consuming the SSE seam).
