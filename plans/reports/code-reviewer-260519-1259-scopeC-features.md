# Adversarial Pre-Merge Review — SCOPE C: Features

Branch: `feat/ui-cosmic-redesign` | Date: 2026-05-19 13:05 GMT+7 | Reviewer: code-reviewer
Verdict gate: pre-merge | Method: read-only diff `main...feat/ui-cosmic-redesign` + logic mirror + test ground truth

## Scope
- 19 files, 2271 insertions / 314 deletions (App/Reading/Auth/Profile/History + tests)
- Ground truth: `swift test` SeeTarotFeatures = 61 exec, 0 fail, 5 expected skips (matches brief)
- Stores/Networking/Core/Persistence: ZERO diff (verified)

## Overall Assessment
Disciplined delta. H1 loader plumbing is **correct and complete**. The cardinal presentation-only invariant **HOLDS** — every store call site, validation predicate, nav route, and SSE lifecycle hook is byte-equivalent modulo reflow. M5 dedup, however, is **incompletely fixed**: a proven residual identity-jump bug remains in the realistic 3-card streaming case (Critical-for-its-stated-goal). One CRLF parser defect and one decorative-affordance UX issue also found.

---

## CARDINAL INVARIANT — PRESENTATION-ONLY PROOF: **PASS**

Evidence:
- `git diff main...branch` on `**/*Store.swift`, `*Route*`, `Validation*`, `SeeTarotNetworking/**`, `SeeTarotCore/**`, `SeeTarotPersistence/**` → **empty**. No store/contract/network change.
- `HomeRoute` enum: identical 5 cases, only **relocated** HomeView→(same file, top). Hashable conformance unchanged. Deep-link/route graph intact.
- `RootView`: single change `HomeView(...)` → `MainTabView(...)`; identical `init(client:user:auth:onSignOut:)` shape, identical `Task { await auth.signOut() }` closure. Auth `viewState` switch (`needsOnboarding`/`authenticated`) untouched. Bootstrap intact.
- `ReadingView`: `.task { store.submit(input) }`, `.onDisappear { store.stop() }` **unchanged** — SSE lifecycle/cancellation preserved (explicit Phase-05 constraint comment retained and honored).
- `DailySection`: `.task { if case .idle = store.state { await store.load() } }` and retry `store.load()` byte-identical; only presentation + loader param added.
- `SignInView`: sign-up→sign-in sequence, `disabled(email.isEmpty || password.count < 6)`, `isSignUp.toggle()`, Google seam `.disabled(true)` `{}` — all preserved.
- `OracleFormView`: `input.clientValidationError` gate, `onSubmit(input)`, spread tags (`.single`/`.three`, no celtic) preserved; only `.segmented`→`.menu` cosmetic.
- `AddReflectionView`: `valid = trimmed>=3 && trimmed<=2000 && mood.count<=24` and `store.add(body:mood:)` + reset-on-success identical.
- `HistoryListView`/`ReadingDetailView`: `store.loadFirst/loadMore/load(id:)`, pagination `onAppear` trigger identical.
- `VisibilityToggle`: `onToggle` + `busy` gate + owner-gating contract preserved.
- `HistoryRowView.relativeDate`: logic identical (brace reflow only).
- Celtic: `spreadKind` still maps 10→.celtic with no UI entry; OracleForm exposes only single/three. Hidden.

No behavioral/logic delta found. Presentation-only constraint satisfied.

---

## Critical

### C1 — M5 dedup still violates id-stability under realistic streaming (residual of prior M5)
`InterpretationBlocks.parse` — `flush()` increments `slugOccurrences[base]` **before** the `if !bodyText.isEmpty` emit guard. A withheld/empty-body section therefore *consumes* a slug-occurrence slot without emitting a block.

Proven (logic mirror, exact dedup code):
- `### Card\n### Card\nSecond body.` → emitted ids = **`["card-2"]`**
- `### Card\nFirst body.\n### Card\nSecond body.` → ids = **`["card", "card-2"]`**

So during streaming, when a later identical card-name heading (`### The Star`) arrives **before** an earlier `### The Star`'s body has streamed, the first visible block is rendered with id `the-star-2`, then **flips to `the-star`** once the earlier body arrives. `ReadingView.revealedBlockIDs` is a `Set<String>` keyed on `block.id`; an id flip = the block is treated as new → magic-reveal animation **re-fires / flickers** mid-stream. This is the exact failure M5 was filed to prevent, and 3-card oracle readings realistically repeat card-name headings (Unresolved Q3 from prior review — still open and now demonstrably load-bearing).

Existing M5 tests pass only because they never exercise the "earlier duplicate still body-less while later duplicate has body" interleaving — `testDuplicateSlugStableUnderIncrementalStreaming` streams bodies in order. Coverage gap.

Fix: only advance the occurrence counter for blocks that are actually emitted. Move the `slugOccurrences` bump inside the `if !bodyText.isEmpty` branch:
```swift
if !bodyText.isEmpty {
    let blockID: String
    if currentIsIntro { blockID = "-intro" }
    else {
        let base = slug(from: currentTitle)
        let count = (slugOccurrences[base] ?? 0) + 1
        slugOccurrences[base] = count
        blockID = count == 1 ? base : "\(base)-\(count)"
    }
    blocks.append(InterpretationBlock(id: blockID, title: currentTitle, body: bodyText))
}
```
Add a test: stream where the 2nd duplicate heading+body arrives a delta before the 1st duplicate's body; assert the 1st-emitted block's id never changes across the accumulation sequence.

Severity rationale: not a crash, but it defeats the stated purpose of the M5 fix under the documented real BE behavior; visible reveal-flicker regression. Blocking for the fix's own acceptance criteria.

---

## High
None beyond C1. (H1 is correctly fixed — see below.)

---

## Medium

### Mx1 — CRLF heading pollutes id and title
`text.components(separatedBy: "\n")` leaves `\r` on each line under CRLF SSE. Proven: `### Card\r\nBody\r\n` → id **`card-`** (trailing hyphen — `\r` split by `.whitespacesAndNewlines` in `slug` yields an empty component → joined `card-`), title **`"Card\r"`** (raw CR in displayed heading). Two defects: (a) CRLF id `card-` ≠ LF id `card` so the same logical reading from a CRLF-emitting proxy gets different identity than LF; (b) `block.title` carries a CR control char into `ScrimText`. Fix: split on `.newlines` (`text.split(omittingEmptySubsequences:false, whereSeparator: \.isNewline)`) or `.trimmingCharacters(in: .whitespacesAndNewlines)` the line before prefix checks and the title. Add a CRLF test. Real-world likelihood depends on BE/proxy; cheap to harden.

---

## Low

### L1 — CardDetailSheet decorative "drag handle" is a non-functional affordance
`CardDetailSheet.swift:33-36` renders a `Capsule()` styled as a grab handle with `.presentationDragIndicator(.hidden)` ("custom handle above"). The capsule has **no gesture and no dismiss action**; there is no Done/Close button and no `@Environment(\.dismiss)` invocation (the property is declared but unused). The sheet is still dismissable — no `.interactiveDismissDisabled` anywhere (verified), so the default `.sheet(item:)` swipe-down works. But: (a) the visible handle mimics an interactive control yet does nothing; (b) no explicit dismiss for discoverability; (c) VoiceOver users get no escape action (swipe-down sheet dismissal is gesture-only). Recommend either wire a tap/drag on the capsule to `dismiss()` or add a top-trailing Close button. Not a behavioral regression (sheet presentation/dismiss path unchanged from before).

### L2 — `## `-over-broad heading match (carried Nit, unchanged)
`line.hasPrefix("##") && line.contains(" ")` still treats any body line beginning `##` + space as a heading (and strips all leading `#`). AI output is `###`-structured so low risk; documented limitation. No code-fence awareness — a `### x` line inside a ``` block is parsed as a heading (oracle output is prose, not code; accept).

---

## Spec-Compliance Checklist (vs intake)

| Constraint | Status | Note |
|---|---|---|
| Immersive hub + 4-tab bar (Today·Oracle·History·Profile) | PASS | `AppTab` enum, `GlassTabBar`, SF Symbols single family |
| Icon+label, ≥44pt, active highlighted, safe-area | PASS | `TabBarButton` minHeight 44, `accentBright` selected, `safeAreaInset` bottom reserve |
| Per-tab NavigationStack path preservation | PASS | 4 distinct `@State [HomeRoute]` paths; opacity-switch keeps stacks alive (`allowsHitTesting` gates input) |
| Today = Daily anchor + DIRECT Oracle CTA | PASS | `TodayTabContent`: `DailySection` hero + `PrimaryButton("Ask the Oracle")` → `selectedTab=.oracle`; resolved decision 4 honored |
| Deep-link routes intact, sign-out wiring | PASS | `destinationFor` switches identical HomeRoute graph; sign-out in Profile toolbar → `onSignOut` |
| SSE parsed by ### into sequential magic-reveal blocks | PARTIAL (C1) | Parser splits + reveals correctly; id-stability breaks under interleaved duplicate streaming |
| CardDetailSheet from in-payload ReadingCard, no network | PASS | Zero URLSession/client/await/.task; renders only `card.*` |
| Glass + scrim text (≥4.5:1) | PASS | `GlassSurface`+`ScrimText`+`.glassPanel/.glassCard` reused; contrast verified in prior scope (DesignSystem) |
| Reduced-motion safe | PASS | `reduceMotion` gates tab anim, block rise, ritual; `nil` animation paths |
| Dynamic Type safe | PASS | token typography, `quotaFigures` tabular, `fixedSize(vertical)`, `lineLimit(2)` name labels |
| Celtic hidden | PASS | No UI entry; spread picker single/three only |

---

## H1 / M5 Fix-Correctness Verdict

**H1 — CardImageLoader plumbing: CORRECT (Accept).**
- Exactly **one** `CardImageLoader` instance live per app session: `MainTabView.init` calls `PersistenceContainer.makeArtworkLoader()` once → stored `let imageLoader`. (`makeArtworkLoader` constructs a fresh loader, not a global singleton, but it is invoked once and the instance is shared across all tabs via closures. `HomeView` also constructs one but `HomeView` is dead — `RootView` no longer instantiates it.) Cache shared across Today/Oracle/History as intended (resolves prior Unresolved Q2 = yes).
- Closure bridging correct: `{ id, url in await imageLoader.image(cardId: id, url: url) }` at MainTabView:117-119 (Today) and :187-189 (Oracle `.reading`). Typealias `@Sendable (String, URL?) async -> Data?`; closure captures only the `Sendable` actor → @Sendable-safe. No retain cycle (value-type View, actor not retaining View).
- Loaded path is actually taken: `FlipCardView.Coordinator.load` → `guard let sendableLoader` → loads front+back via `async let`; `nil` only hits the placeholder branch when loader is nil (no longer the case for Oracle/Today/Daily). `let sendableLoader` local binding applied (silences Sendable diagnostic, matches `SpreadRitualView` pattern).
- Threaded to: `ReadingView(loader:)` → `SpreadRitualView(loader:)` (ritualView:87) + `ritualDoneCardsRow` `RealCardSurface(loader:)` (:101) + `DailySection(loader:)` (:232 / DailySection:loadedContent). History `ReadingDetailView` still receives `imageLoader` directly (path unchanged, still works).
- Cancellation preserved: `Coordinator.load` `task?.cancel()` + `guard !Task.isCancelled` after await; actor reentrancy safe (image() is actor-isolated). Verdict: **Accept**.

**M5 — slug dedup: INCORRECT/INCOMPLETE (Reject — see C1).**
- Per-parse dedup for fully-bodied duplicates: correct (`card`,`card-2`,`card-3`; non-dup unaffected; tests pass).
- Across streaming with bodies arriving in heading order: stable (covered test passes).
- **Fails** the interleaved case (later duplicate gets body before earlier duplicate): id of first visible block flips `card-2`→`card` → ForEach identity jump → reveal re-animation. The occurrence counter increments for withheld empty-body sections. Verdict: **Reject** until counter bump is moved inside the emit guard + interleaved-streaming test added.

---

## Adversarial Verdicts

| Probe | Result | Verdict |
|---|---|---|
| `###` mid-line | → body (`-intro`), not heading | Accept |
| `######` (h6) | → treated as heading (`deep`) | Accept (intake tolerates ##/####) |
| `###` only / `##` no-space | → `-intro` fallback, no crash | Accept |
| code fence with `###` | parsed as heading (no fence awareness) | Defer (prose-only BE; L2) |
| CRLF heading | id `card-`, title `Card\r` | **Reject → Mx1** |
| duplicate headings, in-order streaming | stable | Accept |
| duplicate headings, interleaved streaming | id flips → re-animate | **Reject → C1** |
| H1 loader nil at first frame | placeholder then loads on updateUIView re-call | Accept |
| H1 actor reentrancy / cancellation | guarded (`task?.cancel`, `Task.isCancelled`) | Accept |
| re-skin dropped accessibilityLabel/action | none found; VisibilityToggle gained 44pt target; tab buttons keep `.isSelected` trait | Accept |
| modal/sheet lost dismiss | sheets remain swipe-dismissable (no interactiveDismissDisabled); CardDetailSheet handle non-functional | Defer → L1 |
| Dynamic-Type truncation | token fonts + fixedSize/lineLimit; no fixed-height text container | Accept |

---

## Recommended Actions (priority)
1. **C1** — move `slugOccurrences` bump inside `if !bodyText.isEmpty`; add interleaved-streaming test. Blocking (M5 acceptance).
2. **Mx1** — split on `.isNewline` or trim CR before prefix/title; add CRLF test.
3. **L1** — wire CardDetailSheet handle to `dismiss()` or add Close button (a11y/discoverability).
4. **L2** — opportunistic; document parser limitation.

## Metrics
- Presentation-only proof: PASS (0 logic deltas across 19 files)
- Tests: 61 pass / 5 skip / 0 fail
- H1: correct. M5: residual Critical (C1). New defect: Mx1 (CRLF).
- Type safety: clean; Sendable diagnostics silenced via local binding.

## Unresolved Questions
1. Does BE oracle SSE emit CRLF or LF line endings? Determines Mx1 real severity.
2. Confirmed-realistic: 3-card spread repeats identical card-name `###` headings AND streams them such that a later duplicate can complete before an earlier one's body? If headings always arrive top-down with bodies before the next heading, C1 is latent-only (still recommend the fix — cheap, correctness).
3. Is gesture-only sheet dismissal (no Close button) acceptable for v1 a11y, or is L1 a ship requirement?

---

**Status:** DONE_WITH_CONCERNS
**Summary:** Presentation-only invariant PASS (zero logic delta), H1 loader fix correct and complete; but M5 is incompletely fixed — a proven residual id-stability bug (C1) defeats its own purpose under interleaved duplicate-heading streaming, plus a CRLF id/title defect (Mx1).
**Concerns/Blockers:** C1 blocks M5 acceptance (one-line fix + test). Mx1 medium hardening. L1 a11y. No security/data-leak issues; no contract drift.

Scope C sub-score: **8.0/10** — excellent invariant discipline and a correct H1, dragged down by an incomplete M5 (the scope's CARDINAL fix under review) and a CRLF edge defect. Ship verdict: **NO-GO until C1 fixed**; Mx1/L1 fast-follow acceptable if Q1/Q3 answered favorably.
