# Phase 07 — Immersive Nav Hub + 4-Tab Bottom Bar + Today/Daily Anchor

## Context Links
- `docs/product/ui-design-intake.md` §Navigation
- `Features/App/RootView.swift`, `Features/App/HomeView.swift`
- Depends: Phase 02 (glass bar), Phase 03 (ambient bg)

## Overview
- Priority: P2
- Status: done
- Restructure the authenticated shell into an immersive hub with a 4-tab
  glass bottom bar (`Today · Oracle · History · Profile`), Home = Today with
  the Daily card as the large center anchor. Navigation GRAPH/destinations and
  deep links unchanged.
- **Completion evidence:** MainTabView implemented with 4 NavigationStacks,
  per-tab state preservation, glass bar styling (accentBright active/accentDim
  inactive), sign-out moved to Profile. RootView routes authenticated to
  MainTabView; ambient bg stays continuous.

## Key Insights
- Current `HomeView` is a single `NavigationStack(path:)` with buttons
  pushing `oracleForm/history/profile`. New shell = `TabView` with 4 tabs,
  each its own `NavigationStack`; the *destinations and routes are reused*
  (`HomeRoute`, `OracleFormView`, `HistoryListView`, `ProfileView`,
  `ReadingView`, `ReadingDetailView`) — no graph rewrite, just reparented.
- "Home = Today, Daily card large center anchor": Today tab hosts
  `DailySection` enlarged as the hero + `QuotaChip`; "Ask the Oracle" still
  reachable (Oracle tab is primary entry; Today may keep a CTA into Oracle
  tab/flow — keep deep links unchanged).
- `RootView` injects `.designTokens` + `AmbientBackgroundView` at the root
  and routes by `AuthState`. Keep auth routing exactly; only the
  `.authenticated` branch swaps `HomeView` → new `MainTabView`. Ambient bg
  stays root-level so it's continuous behind the tab bar (immersive).
- Bottom bar must be glass (Phase 02) over the starfield; active tab uses
  `accentBright`, inactive `accentDim`; icon+label; one icon family,
  consistent stroke (SF Symbols acceptable as single family, vector).
- Back behavior preserves scroll/state: each tab keeps its own
  `NavigationStack` path `@State` so switching tabs doesn't reset; deep links
  resolve to the same routes.
- Sign-out currently a button in Home — relocate into Profile tab (it already
  routes Profile); keep `onSignOut` closure wiring through.

## Requirements
Functional:
- `TabView` 4 tabs: Today, Oracle, History, Profile (icon+label, glass bar).
- Today = Daily hero anchor + QuotaChip; Oracle tab = OracleForm→Reading;
  History tab = list→detail; Profile tab = profile + sign out.
- Per-tab `NavigationStack` preserving path/scroll across tab switches.
- Deep links + existing `HomeRoute` destinations unchanged.
- Active tab visually active (`accentBright`); ambient bg continuous behind.

Non-functional:
- No change to stores, route enums' cases, or deep-link handling.
- Auth routing in RootView untouched except the `.authenticated` view swap.

## Architecture
Data flow: `RootView.authenticated(user)` → `MainTabView(client,user,auth,
onSignOut)` → `TabView(selection:)` with 4 `NavigationStack`s; each reuses
the existing destination switch. Ambient bg remains in RootView background
(immersive, continuous). Bottom bar styled via `UITabBar` appearance + glass
(or custom `safeAreaInset` bar) using Phase-02 surface + palette.

## Related Code Files
Modify:
- `Features/App/RootView.swift` (swap `HomeView` → `MainTabView` in
  `.authenticated`; keep bg + token injection + auth routing)
- `Features/App/HomeView.swift` (becomes the Today tab content, or is
  superseded by MainTabView hosting a `TodayView`; reuse its
  daily/quota wiring — no logic change)
Create:
- `Features/App/MainTabView.swift` (tab shell, 4 NavigationStacks, reuses
  HomeRoute destinations)

## Implementation Steps
1. Extract Today content (DailySection hero + QuotaChip + Oracle CTA) — reuse
   `DailyReadingStore`/`client.quota()` wiring from current HomeView; no
   store change.
2. Create `MainTabView`: `TabView(selection:)`, 4 tabs each
   `NavigationStack(path:)` with the existing `navigationDestination(for:
   HomeRoute.self)` switch reused per relevant tab.
3. Style bottom bar: glass (Phase 02) + palette; active `accentBright`,
   inactive `accentDim`; one icon family; icon+label.
4. Move sign-out into Profile tab; thread `onSignOut`.
5. Swap `RootView` `.authenticated` to `MainTabView`; keep `AmbientBackground
   View()` + `.environment(\.designTokens,…)` + auth `.task` bootstrap.
6. Verify deep links / route enums unchanged; tab state persists on switch.
7. Build Features + app.

## Todo List
- [x] MainTabView 4-tab shell, per-tab NavigationStack
- [x] Today = Daily hero anchor + QuotaChip + Oracle CTA
- [x] Reused HomeRoute destinations (no graph rewrite)
- [x] Glass bottom bar, active/inactive palette, icon+label
- [x] Sign-out relocated to Profile; onSignOut threaded
- [x] RootView auth routing + ambient bg intact
- [x] Tab/scroll state preserved on switch; deep links unchanged
- [x] Features + app build green

## Success Criteria
- [x] 4-tab glass bar over continuous starfield; Today shows Daily as hero.
- [x] Switching tabs preserves each stack's scroll/path.
- [x] Route enums, deep links, stores byte-identical (diff = view structure only).
- [x] Auth flow (loading/signedOut/onboarding/authenticated) unchanged.

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Tab refactor drops a destination/deep link | M×H | Reuse exact `HomeRoute` switch; route enum untouched; manual nav matrix in Phase 09 |
| Ambient bg restarts per tab (jank) | M×M | Keep bg at RootView level, single instance behind TabView |
| Tab state reset on switch | M×M | Per-tab `@State` path; verify in 09 |
| Glass bar contrast on labels | L×M | Phase-02 scrim/palette; audited in 09 |

## Security Considerations
No auth/route changes; sign-out path preserved.

## Next Steps
Feeds Phase 09 nav matrix + contrast audit.
