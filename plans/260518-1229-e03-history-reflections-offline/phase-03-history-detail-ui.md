# Phase 03 — History / Detail / Reflections UI + Home Entry

## Context Links

- Story: `docs/stories/epics/E03-history-reflections-offline.md` (History/Detail/Reflections/Visibility AC)
- Plan: `plan.md`; depends on Phase 01 (stores) + Phase 02 (image loader)
- Reuse (E02): `SeeTarotFeatures/.../Reading/ReadingView.swift`,
  `RealCardSurface`/`.cardView(...)`, `IntentCopy.swift`, `App/HomeView.swift`
  (`HomeRoute`, `NavigationStack`), `Reading/QuotaChip.swift` style
- Design system: `SeeTarotDesignSystem` (`@Environment(\.designTokens)`,
  `PrimaryButton`, `LoadingView`)

## Overview

- **Priority:** P1 (delivers user-facing E03)
- **Status:** planned
- Build History list (infinite scroll), Reading detail (reuse E02 render +
  offline artwork), Reflections section + add form, visibility toggle, and a
  Home → History entry point.

## Key Insights

- `HomeView` already owns a `NavigationStack(path:)` with `HomeRoute` enum —
  add `.history` + `.readingDetail(id)` cases rather than a second stack.
- Card rendering must reuse E02 `RealCardSurface`/`.cardView` but feed bytes
  from Phase 02 `CardImageLoader` (cache-first) instead of raw `imageURL` so
  detail renders offline. A small `CardImage` view wraps the loader.
- Reflections add: client validation MUST mirror BE (3–2000 trimmed, mood ≤24)
  via `ReflectionsStore.validate` (P01) before POST; surface server 400
  `issues[]` if they slip through.
- Append-only: no edit/delete affordances anywhere.

## Requirements

Functional:
1. `HistoryListView`: `List` of rows; `.onAppear` on last row → `loadMore()`;
   empty state; error+retry; pull-to-refresh → `loadFirst()`. Row: kind/spread
   badge, preview, relative date (newest-first). Tap → detail.
2. `ReadingDetailView(id)`: drives `ReadingDetailStore.load`; renders
   interpretation + card(s) via reused E02 surface + `CardImage` loader;
   404 → friendly not-found; visibility toggle (owner only, `isOwner`).
3. `ReflectionsSection`: list (newest-first) + `AddReflectionView` (body
   editor, optional mood, char counter, inline validation, submit disabled
   until valid); on submit → store add → refetch list.
4. Home entry point: button/route Home → `HistoryListView`.

Non-functional: iOS17 SwiftUI; smooth scroll; files <200 lines; tokens not
hard-coded colors.

## Architecture

```
HomeView NavigationStack
  HomeRoute.history        → HistoryListView(store: HistoryStore(client))
  HomeRoute.readingDetail(id) → ReadingDetailView(store: ReadingDetailStore(client,id),
                                                  reflections: ReflectionsStore(client,id),
                                                  imageLoader: CardImageLoader)

HistoryListView
  .task → store.loadFirst()
  ForEach(rows) { row in row.onAppear { if last → store.loadMore() } }
  switch store.state: idle/loading→spinner, empty→EmptyState,
    loaded/paging→List(+footer spinner if paging), error→Retry

ReadingDetailView
  switch store.state: loading→spinner, notFound→message,
    loaded(reading)→ interpretation Text + cards(CardImage per card) +
      VisibilityToggle(isOwner) + ReflectionsSection
CardImage(cardId,url): .task { data = await loader.image(cardId,url) }
  data→Image else RealCardSurface placeholder
```

State ownership: views are thin; all logic in P01 stores. `@State` store
init in `init` (match `HomeView`/`ReadingView` pattern).

## Related Code Files

Modify:
- `SeeTarotFeatures/Sources/SeeTarotFeatures/App/HomeView.swift`
  (add `HomeRoute.history` + `.readingDetail(id)` + entry button + destinations)
- `SeeTarotFeatures/Sources/SeeTarotFeatures/App/AppComposition.swift`
  (DEBUG stub: add history/reflection fixtures for UI-stub verification)

Create:
- `SeeTarotFeatures/.../History/HistoryListView.swift`
- `SeeTarotFeatures/.../History/HistoryRowView.swift`
- `SeeTarotFeatures/.../History/ReadingDetailView.swift`
- `SeeTarotFeatures/.../History/ReflectionsSection.swift`
- `SeeTarotFeatures/.../History/AddReflectionView.swift`
- `SeeTarotFeatures/.../History/VisibilityToggle.swift`
- `SeeTarotFeatures/.../History/CardImage.swift`
- Snapshot/logic-light tests where practical in `SeeTarotFeaturesTests`
  (state-driven view-model assertions already in P01; here keep UI tests
  minimal — E2E in P04).

Delete: none.

## Implementation Steps

1. Extend `HomeRoute` (+`history`, +`readingDetail(id:String)`); add Home
   entry button + `navigationDestination` cases.
2. `CardImage` wrapper over `CardImageLoader` (P02) with placeholder fallback.
3. `HistoryRowView` + `HistoryListView` (List, onAppear paging, empty/error,
   pull-refresh).
4. `ReadingDetailView` reusing E02 interpretation/card render + `CardImage`;
   404 not-found; mount `ReflectionsSection` + `VisibilityToggle`.
5. `AddReflectionView` with inline validation (mirror BE) + char counter;
   submit → `ReflectionsStore.add` → refetch.
6. `VisibilityToggle` (owner-only) → `setVisibility`; reflect server state;
   disable during in-flight; surface 400/404.
7. Extend DEBUG `StubAuthStore` with deterministic history/reflection fixtures
   so `SEE_TAROT_UI_STUB=1` renders offline for screenshots.
8. Build + run sim (`build_run_sim`); visual sanity (defer full E2E to P04).

## Todo List

- [ ] `HomeRoute` + Home History entry + destinations
- [ ] `CardImage` (loader-backed, placeholder fallback)
- [ ] `HistoryRowView` + `HistoryListView` (paging/empty/error/refresh)
- [ ] `ReadingDetailView` (reuse E02 render, 404 not-found)
- [ ] `ReflectionsSection` + `AddReflectionView` (mirror validation)
- [ ] `VisibilityToggle` (owner-only)
- [ ] DEBUG stub history/reflection fixtures
- [ ] Build + sim run clean

## Success Criteria

- From Home: open History → rows render newest-first; scroll appends until
  `nextCursor==null`; empty state on no rows. Tap → detail renders
  interpretation + card art (from cache when warm); 404 → friendly message.
  Add reflection (valid) appears newest-first; invalid blocked client-side;
  server 400 issues shown. Owner toggles visibility, persists. Builds + runs
  on simulator. Files <200 lines.

## Risk Assessment

| Risk | L×I | Mitigation |
|---|---|---|
| `List` infinite scroll fires loadMore repeatedly | M×M | guard on store state (paging/end) — logic lives in P01 store; onAppear only triggers |
| Reusing E02 `RealCardSurface` assumes URL not bytes | M×M | `CardImage` resolves bytes via loader, passes faceUp; fall back to placeholder API already in `ReadingView` |
| Detail of public reading viewed as non-owner shows toggle | L×M | gate `VisibilityToggle` on `reading.isOwner` |
| View files >200 lines | M×L | split row/section/form into own files (already planned) |

## Security Considerations

- Visibility toggle only for `isOwner==true` (BE owner-only PATCH; UI must not
  offer it otherwise). No PII in row preview beyond server-provided `preview`.
  401 during any action → existing sign-out seam (via store/client). Don't log
  reflection bodies.

## Next

Unblocks Phase 04 verification. Consumes P01 stores + P02 loader (both must be
complete/merged before P03 integration).
