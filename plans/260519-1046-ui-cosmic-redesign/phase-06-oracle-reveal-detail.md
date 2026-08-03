# Phase 06 — Oracle SSE Block Magic-Reveal + Card Detail Sheet

## Context Links
- `docs/product/ui-design-intake.md` §AI interpretation
- `Features/Reading/ReadingView.swift`
- `SeeTarotCore/Models/Reading.swift` (`ReadingCard` fields)
- Depends: Phase 02 (glass/scrim), Phase 04 (card surface), sequenced after
  Phase 05 ReadingView wiring

## Overview
- Priority: P2
- Status: done
- Render the streamed whole-reading interpretation as ordered, sequentially
  magic-revealed block sections (split on markdown `###`), with the cards row
  pinned above (names beneath each) and a tap-to-detail sheet driven entirely
  by the in-payload `ReadingCard`.
- **Completion evidence:** InterpretationBlocks parser + 14 tests (split/intro/
  partial/none), CardDetailSheet renders ReadingCard only, pinned cards row
  wired. Magic-reveal gates on block id first appearance. Reduced-motion
  crossfade. 56 Features tests PASS + M5 fix (slug de-duplication + 4 tests).

## Key Insights
- Today `ReadingView` renders interpretation as a single
  `Text(currentText)` / `Text(text)` blob. Replace with block parsing:
  split `delta`/final text by `###` headings into ordered sections; render
  each as a fade+rise "magic-reveal" as it streams in.
- SSE is the WHOLE reading (not token-budget chunks of distinct messages) —
  parsing is on accumulated text; re-parse cheaply as text grows; reveal a
  block once its heading + some body present; stable identity per heading so
  earlier blocks don't re-animate.
- No per-card endpoint. Detail sheet renders ONLY from `ReadingCard`:
  `name, arcana, suit, number, reversed, keywords, uprightMeaning,
  reversedMeaning, imageUrl, position`. Show upright OR reversed meaning per
  `reversed`. No network call.
- Cards row pinned above interpretation, names beneath each (Phase 04
  surface already renders the name); tap a card → sheet.
- All interpretation/detail text on Phase-02 `GlassSurface` scrim → ≥4.5:1.
- ReadingView is edited by Phase 05 (ritual wiring) FIRST; this phase edits
  the interpretation render region only, after 05 lands (blocked-by 05).
- States to preserve: `.composing/.revealing/.done/.invalid/.blocked/.failed`
  — only the *presentation* of cards+text changes; error/blocked/retry copy
  re-skinned but logic identical (`store.submit(input)` retry stays).

## Requirements
Functional:
- Parse interpretation into ordered blocks by `###` headings (text before
  first heading = intro block).
- Each block magic-reveals (fade + rise) once on first appearance; earlier
  blocks stay static as more stream in.
- Cards row pinned above; tapping a card opens a detail sheet from
  `ReadingCard` only (keywords, upright/reversed meaning by state,
  arcana/suit/number).
- Re-skinned `.invalid/.blocked/.failed` states; retry still
  `store.submit(input)`.
- Reduced-motion: blocks crossfade/appear without rise; no layout shift.

Non-functional:
- No new network. No store/state-machine change.
- All text passes Phase-02 contrast.

## Architecture
Data flow: `store.state` text (`revealing(_,t)` / `done(_,_,t)`) →
`InterpretationBlocks.parse(text)` → `[Block{id:headingSlug,title,body}]` →
`ForEach` renders each in a `GlassSurface`; a block animates in when its id
first enters the set (track revealed ids in `@State`). Cards row = Phase-04
surfaces in spread order; `.onTapGesture` → `selectedCard` → `.sheet`
`CardDetailSheet(card:)` reading only `ReadingCard`.

Parsing rule: split on lines matching `^#{3}\s+`; heading text = slug id;
robust to partial trailing heading mid-stream (don't reveal until body bytes
follow).

## Related Code Files
Modify:
- `Features/Reading/ReadingView.swift` (replace blob `Text` with block list +
  pinned cards row + sheet; keep state switch + retry)
Create:
- `Features/Reading/InterpretationBlocks.swift` (pure parser + `Block`)
- `Features/Reading/CardDetailSheet.swift` (renders from `ReadingCard`)
- `SeeTarotFeatures` test: `InterpretationBlocksTests` (heading split,
  intro block, partial-stream safety, no-heading fallback)

## Implementation Steps
1. `InterpretationBlocks.parse(_:) -> [Block]` pure; handle: no headings
   (single block), pre-heading intro, partial trailing heading. Tests.
2. `CardDetailSheet(card: ReadingCard)`: glass sheet; show name, arcana/suit/
   number, keywords, and `reversed ? reversedMeaning : uprightMeaning`; art
   via existing CardImage/Phase-04 surface. No fetch.
3. Rewrite ReadingView render: pinned cards row (Phase-04 surfaces, tap →
   sheet) + `ForEach(blocks)` each in `GlassSurface` with magic-reveal on
   first appearance (track revealed ids).
4. Reduced-motion gate: appear without rise; no shift.
5. Re-skin `.invalid/.blocked/.failed` with glass + palette; retry unchanged.
6. Confirm `.onDisappear { store.stop() }` and `.task { store.submit }`
   untouched.
7. Build Features + tests.

## Todo List
- [x] InterpretationBlocks parser + tests (split/intro/partial/none)
- [x] CardDetailSheet from ReadingCard only (no network)
- [x] Pinned cards row, names beneath, tap → sheet
- [x] Per-block magic-reveal, stable ids, earlier blocks static (M5 de-dupe)
- [x] Reduced-motion appear (no rise/shift)
- [x] Re-skinned invalid/blocked/failed; retry logic unchanged
- [x] store lifecycle untouched; Features build + tests pass

## Success Criteria
- [x] Streaming reading renders as sequential revealed blocks, not one blob.
- [x] Card tap opens detail purely from payload; zero new requests (verify no
  new client calls).
- [x] Error/blocked/retry behavior identical to pre-reskin.
- [x] Contrast ≥4.5:1 on all interpretation/detail text (Phase 09 confirms).

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| Mid-stream partial heading flicker | M×M | Reveal block only when body bytes follow heading; stable ids |
| Re-parse cost each delta | M×M | Parser is linear scan; cheap; parse on text change only |
| Same-file collision w/ Phase 05 | M×M | Blocked-by 05; edit after ritual wiring lands |
| Accidental network temptation for card meta | L×H | Hard rule: detail reads ReadingCard only; reviewer checks no client call |

## Security Considerations
No new endpoints; renders trusted in-payload model only.

## Next Steps
Feeds Phase 09 contrast/reduced-motion audit.
