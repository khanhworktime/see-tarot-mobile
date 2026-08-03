# Phase 08 — Remaining Surfaces Re-skin

## Context Links
- `docs/product/ui-design-intake.md` §Surfaces to Redesign
- `Features/Auth/*`, `Features/Profile/*`, `Features/History/*`,
  `Features/Reading/{QuotaChip,DailySection,OracleFormView}.swift`
- Depends: Phase 02 (glass/scrim primitive)

## Overview
- Priority: P2
- Status: done
- Re-skin every remaining wired surface to Cosmic Mysticism using the Phase
  01/02 tokens + glass primitives. Presentation only — no store/validation/
  navigation change.
- **Completion evidence:** Auth, OracleForm, DailySection, QuotaChip, History,
  ReadingDetail, Reflections, Profile, error/retry/offline/empty states all
  re-skinned to Cosmic palette + glass. Tabular figures applied to quotas.
  All 56 Features tests PASS, no store/validation changes.

## Key Insights
- Surfaces: Auth/SignIn, Onboarding, OracleForm, DailySection, QuotaChip,
  History list (+rows), ReadingDetail + Reflections (+AddReflection,
  VisibilityToggle), Profile, error/retry (`502 ai_failed`, `403`
  entitlement, `429`), offline (cached artwork/readings), empty states.
- All consume `\.designTokens` already → palette/typography swap is largely
  free once Phase 01 lands; the work is applying `GlassSurface`/scrim,
  ornament accents at ceremonial moments only, and re-skinned error/empty
  copy + iconography.
- QuotaChip + any timer/quota counts must use the tabular-figures token
  (Phase 01) to avoid digit jitter.
- `CardImage.swift` is stabilized by Phase 04 — DO NOT edit here (ownership);
  History rows just reuse it.
- Functional UI stays clean; ornament moderate (glyph dividers/corner
  flourishes only at ceremonial beats — e.g. reading detail header, not list
  rows). SVG/vector icons, one family, no emoji.
- Offline + error + empty states must keep existing logic/copy semantics;
  only visual treatment changes (glass card, palette, accent icon). Retry
  actions call the same store methods.

## Requirements
Functional (per surface, visual only):
- Auth/SignIn, Onboarding: cosmic bg-consistent, glass form panels, Cinzel
  headings.
- OracleForm: glass form, accent controls; submit wiring unchanged.
- DailySection/QuotaChip: glass; quota uses tabular figures.
- History list/rows: glass rows, palette; reuse Phase-04 CardImage untouched.
- ReadingDetail + Reflections/AddReflection/VisibilityToggle: glass, ornament
  at header only; logic unchanged.
- Profile: glass; sign-out (relocated here by Phase 07) styled.
- Error/retry (502/403/429), offline, empty: re-skinned glass states, accent
  iconography; same retry/store calls + copy semantics.

Non-functional:
- Zero store/validation/navigation/network change.
- All text on Phase-02 scrim → ≥4.5:1 (audited Phase 09).
- No file owned by Phase 04/07 edited here.

## Architecture
Data flow: unchanged. Each view swaps raw containers/`Text` styling for
`GlassSurface` + palette/typography tokens; stores/bindings identical.

## Related Code Files
Modify (Phase-08-owned only):
- `Features/Auth/SignInView.swift`, `OnboardingView.swift`
- `Features/Profile/ProfileView.swift`
- `Features/History/HistoryListView.swift`, `HistoryRowView.swift`,
  `ReadingDetailView.swift`, `ReflectionsSection.swift`,
  `AddReflectionView.swift`, `VisibilityToggle.swift`
- `Features/Reading/QuotaChip.swift`, `DailySection.swift`,
  `OracleFormView.swift`
Do NOT edit: `CardImage.swift` (Phase 04), `RootView/HomeView/MainTabView`
(Phase 07), `ReadingView.swift` (Phase 05/06).

## Implementation Steps
1. Auth + Onboarding: glass panels, Cinzel headings, palette; verify
   AuthStore bindings untouched.
2. OracleForm: glass form controls; submit closure unchanged.
3. DailySection + QuotaChip: glass; tabular-figures token on counts.
4. History list + rows: glass rows; ReadingDetail header ornament; Reflections
   /AddReflection/VisibilityToggle glass; logic untouched.
5. Profile: glass; styled sign-out.
6. Error/retry/offline/empty states across surfaces: glass treatment, accent
   icons, same copy semantics + retry calls.
7. Build Features + app; spot-check each surface renders.

## Todo List
- [x] Auth/SignIn + Onboarding re-skinned
- [x] OracleForm re-skinned (submit unchanged)
- [x] DailySection + QuotaChip (tabular figures)
- [x] History list/rows + ReadingDetail + Reflections re-skinned
- [x] Profile re-skinned + styled sign-out
- [x] Error/retry/offline/empty states re-skinned (logic intact)
- [x] No Phase-04/05/06/07-owned file touched
- [x] Features + app build green

## Success Criteria
- [x] Every listed surface visually on-brand; diffs show only styling.
- [x] Stores/validation/navigation byte-identical.
- [x] Quota/timer digits don't jitter (tabular).
- [x] Contrast audited green in Phase 09.

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Accidental logic/validation edit | M×H | Visual-only rule; reviewer diffs for non-view changes |
| File-ownership overlap (CardImage/Reading/Root) | M×M | Explicit do-not-edit list; sequence after 04/05/06/07 |
| Inconsistent ornament overuse | L×M | Ornament only at ceremonial beats; functional UI clean |
| Error/empty copy drift | L×M | Preserve existing strings; only restyle |

## Security Considerations
No auth/entitlement logic change; 403/429/502 handling preserved.

## Next Steps
Feeds Phase 09 full-surface contrast/Dynamic-Type/reduced-motion audit.
