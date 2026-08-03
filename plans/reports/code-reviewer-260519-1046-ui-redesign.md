# Code Review — SeeTarot iOS Cosmic Mysticism Re-skin (Phases 01–08)

Date: 2026-05-19 | Reviewer: code-reviewer | Verdict gate: pre-ship

## Scope
- ~1726 insertions / 416 deletions, 23 modified + 13 new files
- Focus: DesignSystem, CardEngine, Features re-skin
- Build ground truth: xcodebuild SUCCEEDED (per task brief); stale-index noise ignored
- Method: full read of new files + diff of re-skinned views vs HEAD

## Overall Assessment
High quality, disciplined work. Strong separation of pure logic (CardBackURL, InterpretationBlocks, ParticleSystem, ContrastRatio) from SwiftUI, all unit-tested. Presentation-only constraint largely respected — store/nav/contract seams untouched. Two real correctness bugs found (H1 ritual cards never load artwork; H2 reduced-motion not reactive), several medium robustness gaps. No security/data-leak issues (presentation layer, no new I/O, loader hardening preserved).

---

## Critical
None.

---

## High

### H1 — Oracle ritual + done row never load card artwork (functional regression)
`ReadingView.swift` `ritualView(...)` passes `loader: nil`, and `ritualDoneCardsRow` / `interpretationBlockList` build `RealCardSurface(...)` with no loader. Comment says "Phase 08 threads the real loader here" but Phase 08 did not. `MainTabView` holds `imageLoader` and only passes it to `ReadingDetailView` — `ReadingView` (route `.reading`) is constructed with no loader at all.

Effect: every Oracle reading shows blank/placeholder cards (FlipCardView with `loader == nil` → `view.configure(frontData: nil, backData: nil)`). DailySection also constructs `RealCardSurface(name:reversed:)` with no loader — same blank card on Home. This is a visible product regression vs. the intake ("cards flip-reveal", artwork stretched to 95/155). Pre-existing `CardImage.swift` did wire the loader; the new flip path dropped it.

Fix: thread `imageLoader` from `MainTabView.destinationFor(.reading:)` into `ReadingView` (add `loader` init param), pass it to `SpreadRitualView(loader:)`, `ritualDoneCardsRow`, and `DailySection`. Bridge actor → closure:
```swift
let l = imageLoader
ReadingView(store: OracleReadingStore(client: client), input: input,
            loader: { id, url in await l.image(cardId: id, url: url) })
```
The closure literal is `@Sendable` (captures only the `Sendable` actor) — satisfies `CardImageLoaderClosure`.

### H2 — Reduced-motion / low-power state is read once, never reactive
`FlipCardView.updateUIView` and `RealCardSurfaceUIView.onChange` read `UIAccessibility.isReduceMotionEnabled` imperatively. `SpreadRitualView` takes `reduceMotion` as a one-shot init param resolved by the caller's `@Environment(\.accessibilityReduceMotion)` — fine for entry, but the ritual's `onAppear` branches once and never re-evaluates. `AmbientBackgroundView` correctly uses `@Environment` + `ProcessInfo.isLowPowerModeEnabled` but `isLowPowerModeEnabled` is read at body-eval time only — there is no `.NSProcessInfoPowerStateDidChange` observation, so toggling Low Power Mode mid-session does not switch to the static fallback until some other state change re-evaluates `body`. Intake requires "Full prefers-reduced-motion path" and "low-power static fallback". Acceptable for v1 if mid-session toggling is out of scope, but document it. Recommended: observe `Notification.Name.NSProcessInfoPowerStateDidChange` and store in `@State`, or accept as known limitation.

---

## Medium

### M1 — `FlipCardView` Coordinator marks `reversed: false` — reversed artwork never rotated in flip path
`Coordinator.load` calls `view.configure(frontData:..., backData:..., reversed: false)` (lines 172, 182) — hardcoded `false`. `FlipCardUIView.configure` applies the 180° transform based on that flag. The `reversed` init param of `FlipCardView` is stored but never forwarded into `configure`. Result: reversed cards show upright artwork in the 3D flip view; only the text label says "(Reversed)". Intake: "reversed → show reversed state (label + 180° artwork)". The label is correct, the artwork rotation is lost. Fix: pass `self.reversed` through `Coordinator.load` into both `configure` calls.

### M2 — Sendable warnings at FlipCardView.swift:144/151 — benign but should be silenced
The warnings ("converting non-Sendable function value to '@Sendable ... async -> Data?'") arise because `loader` is `CardImageLoaderClosure` (already `@Sendable`) but is passed through `Coordinator.load(loader:)` whose parameter type is the typealias and then captured in a `Task { @MainActor }`. Not a real data race: the closure is `@Sendable` by typealias definition, `Coordinator` is `@unchecked Sendable`, the captured `view` is only touched inside `@MainActor`. The diagnostic is a Swift 6/5-mode interop artifact, not a hazard. Recommended fix to remove noise: annotate `Coordinator.load`'s `loader` parameter explicitly and the stored/captured value as `@Sendable`, or capture `loader` into a `let sendableLoader: CardImageLoaderClosure = loader` immediately before the `Task` (the same pattern already used successfully in `SpreadRitualView.dealtCardsLayer:271`). Apply that one-line local binding inside `Coordinator.load`.

### M3 — `CardBackURL.derive` does not validate path-only / scheme-less URLs
`derive(from:)` uses `URLComponents` and only nils on parse failure. Edge cases:
- imageURL with no host (e.g. `file:///x.svg` or a relative `cards/x.svg`): produces `comps?.url` like `file:///cards/back.png` or a host-less URL — `CardImageLoader.session.data(from:)` then fails the fetch (graceful → placeholder), so no crash, but the synthetic cache key falls to `_back@unknown` (see M4).
- scheme without host but with path is technically valid; result is a non-loadable URL. Acceptable (degrades to placeholder) but worth a guard: return `nil` when `comps?.host == nil` so callers get an explicit "no back" rather than a junk URL. Tests cover https/http/port/query/nil but not the no-host case — add one.

### M4 — Synthetic cache key `_back@<host>` collision/aliasing risks
Two real concerns:
1. Port ignored in `cacheKey` but preserved in `derive`. `host:8080` and `host:9090` (e.g. local dev vs. staging proxy on same host) → same key `_back@host` but different `derive` URLs. First-loaded back wins for both. Low real-world impact (one BE host in prod) but a latent dev/staging aliasing bug. Recommend including port: `_back@\(host):\(port)` when port present.
2. Scheme ignored: `http://host` and `https://host` share a key. Same low impact, same easy fix.
3. Collision with a real card whose `cardId` is literally `_back@host`: card ids are server slugs (`the-sun`), `@` not in slug charset → effectively impossible. Documented as acceptable.

### M5 — `InterpretationBlocks` duplicate-heading slug collision → ForEach identity crash risk
`slug(from:)` is deterministic; two sections with the same heading (e.g. AI emits `### Card` twice, or `### The Star` for two Star cards in a spread) produce identical `id`. `InterpretationBlock` is `Identifiable` by `id`; SwiftUI `ForEach(blocks)` with duplicate ids causes undefined rendering / dropped views / console warning, and `revealedBlockIDs` Set membership makes the second block reuse the first's reveal state (no animation). Streaming oracle text realistically repeats card-name headings in 3-card spreads. Fix: de-duplicate by appending an occurrence index to the slug on collision while keeping it stable across re-parses (track seen-slug counts during the single parse pass; same input → same suffixed ids). Add a test with repeated headings.

### M6 — `interpretationBlockList` re-parses full text every SwiftUI body eval during streaming
`InterpretationBlocks.parse(text)` runs on every `body` recomputation while `currentText` grows (O(n) per eval, O(n²) over the stream). For a single-reading SSE this is a few KB — acceptable but not free, and `body` evals are frequent under animation. Not blocking. If profiling shows jank, memoize parse keyed by text length/hash in the store rather than the view. Note only.

### M7 — `AmbientBackgroundView` simulation cadence coupling
`.task(id: tl.date)` advances the system by a fixed `dt: 1.0/60.0` regardless of actual elapsed time. If TimelineView throttles (background, thermal), particles slow down rather than skip — visually acceptable (drift, not physics) and the `safeDt` clamp in `ParticleSystem.step` is moot here since dt is constant. Minor: pass real elapsed time (`tl.date` delta) for frame-rate independence, or accept fixed-step as a deliberate simplicity choice (KISS). Note only — current behavior is safe (no runaway, no NaN; `wrap` keeps positions bounded).

### M8 — Gesture conflict risk: ambient drag vs. ritual hold
`AmbientBackgroundView` attaches a full-screen `DragGesture(minimumDistance: 0)` on the background; `SpreadRitualView` attaches `LongPressGesture.simultaneously(DragGesture)` + a `simultaneousGesture(DragGesture)` on the deck. The ambient background sits behind content via `.background(AmbientBackgroundView())` in RootView, so hit-testing should route deck touches to the ritual first, but the redundant `.gesture` + `.simultaneousGesture` pair on the deck both call `beginHold()`/`endHold()` on every change/end — `beginHold` is idempotent (`guard !isHolding`) and `endHold` guards on `isHolding || phase == .fan`, so double-invocation is safe. Verify on device that a hold over the deck doesn't also perturb particles distractingly (cosmetic). No correctness bug.

---

## Low

- **L1** `FlipCardView.makeUIView` hardcodes `CGRect(... 95, 155)` then SwiftUI `.frame(width:95,height:155)` re-applies; harmless duplication, keep for clarity.
- **L2** `RealCardSurface` non-UIKit branch returns a plain rect with no name label — only hit in test host, but it diverges from the documented "always render name below"; fine for tests, note it.
- **L3** `Tokens.swift` keeps legacy `accent/background/surface/textPrimary/textSecondary` remapped — good backward-compat, but `palette.surface` (#050B2E) is now used by old callers expecting a "card surface" tint; verify no re-skinned screen relies on old contrast assumptions. Spot-checked QuotaChip/DailySection — fine.
- **L4** `SpreadRitualView` is 546 lines — exceeds the 200-line project guidance. Functionally cohesive but a candidate for extracting `FanCardState`/`DealtCardState` builders + the deal timeline into a `RitualChoreographer`. Non-blocking; flagged for tech-debt.
- **L5** `FontRegistrar.register` uses `print(...)` for the skip path — prefer `os.Logger` for consistency with the rest of the codebase (CardImageLoader uses `Logger`). Cosmetic.
- **L6** `ContrastRatio.swift` header documents verified ratios in a comment; good. The `alphaComposite` helper assumes `bg` is opaque — true for `#010726`; document the precondition.

---

## Nits
- `InterpretationBlocks.parse` heading branch: `line.hasPrefix("##") && line.contains(" ")` will treat a body line that happens to start with `##` and contains a space (a markdown sub-bullet or literal `## note`) as a heading. AI output is `###`-structured so low risk; tighten to `hasPrefix("## ")`/`### ` only if BE variance is a concern.
- `CardDetailSheet.FlowLayout.placeSubviews` trailing `_ = containerWidth // suppress warning` — dead local; remove the unused `containerWidth` instead of suppressing.
- `AmbientBackgroundView.swift:76` `.onChange(of:scenePhase){ phase in ... }` single-param closure is deprecated in iOS 17. Build is clean (deployment target / 5-mode), but migrate to `onChange(of:initial:_:)` two-param form to future-proof. Non-blocking.

---

## Constraint Compliance Checklist (vs intake)

| Constraint | Status | Note |
|---|---|---|
| bg `#010726` screen + card fill | PASS | `Palette.cosmic.bg`/`background` = 0x010726; FlipCardUIView faces filled with 1/7/38 |
| Card forced 95/155 + stretch incl. back | PASS | `.scaleToFill` both image views; `.frame(95,155)`; back uses same contentMode |
| Card back `/cards/back.png` runtime-derived from imageUrl host | PASS | `CardBackURL.derive` scheme+host+port, no hardcode; tested |
| Card name always rendered below card | PASS | `RealCardSurfaceUIView` VStack label outside flip frame; reversed appends "(Reversed)" |
| Reversed → 180° artwork | **FAIL (M1)** | Label correct; flip-path Coordinator hardcodes `reversed:false`, artwork not rotated |
| Glass text on inner scrim ≥4.5:1 / ≥3:1 | PASS | GlassSurface scrim bg@0.82; ContrastRatio tests assert 16.79:1 / 6.40:1; ScrimText routes color by style |
| Particles TimelineView+Canvas, no Metal | PASS | `ParticleCanvas` TimelineView+Canvas; pure `ParticleSystem`; no Metal import |
| Reduced-motion + low-power fallback | PARTIAL (H2) | Static gradient gated on env reduceMotion + isLowPowerModeEnabled; not reactive to mid-session power toggle |
| Fonts bundled Cinzel/Lora via FontRegistrar (not CDN) | PASS | Resources/Fonts/*.ttf + OFL; FontRegistrar CTFont register; UIAppFonts belt; no network |
| Token env-injection, no singletons | PASS | `DesignTokensKey` EnvironmentKey; no shared mutable singletons added |
| Celtic hidden v1 | PASS | `spreadKind` maps 10→.celtic but no UI entry; OracleForm unchanged; gated by BE 403 |
| No networking/state/nav/contract change | PASS | Stores/`HomeRoute`/API untouched; MainTabView preserves init shape + destinations; presentation-only |
| Per-card detail from in-payload ReadingCard, no endpoint | PASS | `CardDetailSheet` renders only `card.*`; zero network calls |
| Artwork actually displayed in Oracle/Today | **FAIL (H1)** | `loader: nil` everywhere in ReadingView/DailySection → blank cards (regression) |

---

## Recommended Actions (priority order)
1. **H1** — thread `imageLoader` closure into `ReadingView` → `SpreadRitualView`/done-row, and into `DailySection`. Blocking: visible artwork regression.
2. **M1** — forward `reversed` through `FlipCardView.Coordinator` into `FlipCardUIView.configure`. Blocking: violates hard constraint.
3. **M5** — de-duplicate interpretation block slugs (stable per parse) + test. Blocking: ForEach identity hazard on repeated headings (realistic in 3-card readings).
4. **M2** — silence Sendable warnings via local `let` binding in `Coordinator.load` (zero-cost, matches existing pattern).
5. **M3/M4** — add no-host guard + include scheme/port in cache key; add tests.
6. **H2** — observe power-state notification or document the mid-session limitation.
7. Low/Nit — address opportunistically; L4 file-size → tech-debt backlog.

## Metrics
- New pure logic test coverage: strong (CardBackURL 8 cases, InterpretationBlocks 14, ParticleSystem, ContrastRatio). Gaps: no-host derive, duplicate-heading slug.
- Type safety: clean; 2 benign Sendable warnings (M2).
- Linting: 1 deprecated API (onChange), `print` vs Logger.
- File-size rule: 1 violation (SpreadRitualView 546 LOC).

## Unresolved Questions
1. Is mid-session Low Power Mode toggle in scope for v1, or accept H2 as documented limitation?
2. Confirm intended: should `ReadingView` Oracle cards use the same `CardImageLoader` instance as History (cache sharing across tabs)? Recommended yes — single `imageLoader` already on `MainTabView`.
3. Does the BE oracle SSE ever emit duplicate `###` headings (e.g. per-card name repeats)? Confirms M5 severity.

---

**Status:** DONE_WITH_CONCERNS
**Summary:** Solid, well-tested re-skin that respects the presentation-only seam, but two blocking correctness issues (H1 artwork never loads in Oracle/Today; M1 reversed artwork not rotated) and a ForEach identity hazard (M5) must be fixed before ship.
**Concerns/Blockers:** H1, M1, M5 are ship-blockers (correctness/constraint). H2 needs a scope decision. Sendable warnings (M2) benign.

Overall score: **7.5/10** — high craft, but ships with a visible regression and one hard-constraint miss until H1/M1/M5 are addressed. Ship verdict: **NO-GO until H1, M1, M5 fixed**; re-review delta only.
