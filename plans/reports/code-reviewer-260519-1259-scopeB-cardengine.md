# Scope B — CardEngine Adversarial Pre-Merge Review

Branch: `feat/ui-cosmic-redesign` | Date: 2026-05-19 13:05 GMT+7
Scope: SeeTarotCardEngine logic-heavy files (M1 fix, SpreadRitual split, Sendable warnings, particle perf)
Ground truth verified: `swift test` 49/49 PASS; M1 fix diff inspected vs prior review.

---

## Verdict on the 2 Sendable Warnings (FlipCardView:144/151) — DEFINITIVE

**Benign. Not a real Swift 6 data race. Already correctly mitigated. Warnings are now SUPPRESSED in the fixed code.**

Reasoning (independent adjudication):
- `CardImageLoaderClosure = @Sendable (String, URL?) async -> Data?` — the typealias is `@Sendable` by definition.
- `Coordinator` is `@unchecked Sendable` (line 157). Its mutable state (`lastFrontURL`, `task`, etc.) is only ever touched from `load(...)`, which is called from `makeUIView`/`updateUIView` — both **@MainActor-isolated** by `UIViewRepresentable` contract. So the `@unchecked` is sound *in practice* for this usage (single-threaded MainActor access).
- `view: FlipCardUIView` (a `UIView`, non-Sendable) is captured into `Task { @MainActor in ... }` — capture is safe because the closure body runs on MainActor and `UIView` is MainActor-bound anyway.
- The fix at line 175 (`let sendableLoader: CardImageLoaderClosure? = loader` before the `Task` capture) is the **correct minimal mitigation** and matches the pattern in `SpreadRitualView.dealtCardsLayer:242`. The lines that previously warned (144/151 = the `context.coordinator.load(...)` callsites) no longer carry the diagnostic because the non-Sendable widening happens at the `Task` capture, which is now pre-bound.

Residual nit (LOW, non-blocking): `@unchecked Sendable` on `Coordinator` is a *promise*, not a *proof*. Access is MainActor-safe today only because `UIViewRepresentable` callbacks are MainActor. This is correct but undocumented. Add a one-line comment on the class declaration stating "all access is MainActor via UIViewRepresentable callbacks; @unchecked is sound under that invariant." No code change required.

**Action: ACCEPT. No fix needed. Warnings, if any remain in xcodebuild, are stale-index / interop noise — do not block merge.**

---

## M1 Fix Verification — CORRECT

Prior review (260519-1046) flagged: `Coordinator.load` called `configure(..., reversed: false)` hardcoded; reversed artwork never rotated in the flip path.

Fixed code (verified line-by-line + git diff `fd25494~1..HEAD`):
- `Coordinator.load(front:back:reversed:loader:into:)` now takes `reversed: Bool` (line 163).
- `lastReversed` tracked as dedupe key (lines 160, 167, 170) — re-loads when reversed flips even if URLs unchanged. Correct for cell reuse.
- Both `configure` paths forward the real `reversed`: nil-loader branch line 178-179, loaded branch line 188-189.
- `FlipCardUIView.configure` (line 67-72) applies `CGAffineTransform(rotationAngle: .pi)` to `frontImageView` only when `reversed`. **Back image is never rotated** — correct (back.png has no orientation). **No double-rotation**: transform is set absolutely (`reversed ? .pi : .identity`), not accumulated, so repeated `configure` calls are idempotent.
- Label consistency: `RealCardSurface.labelText` (line 134-136) appends "(Reversed)" independently from the same `reversed` input. Art + label driven by the same source value → consistent.

**Verdict: M1 FIX CORRECT. ACCEPT.** State tracked across reuse via `lastReversed`; no double-rotation; art/label consistent.

---

## SpreadRitualView Split — BEHAVIOR IDENTICAL (no regression possible)

Investigated: `RitualTimeline.swift`, `RitualCardState.swift`, and `SpreadRitualView.swift` were **all committed together in a single commit (09818d7)**. There was **no pre-split monolithic version on `main`** — this is the original structure of the feature on this branch, not a refactor of existing behavior.

- Public API intact & self-consistent: `SpreadRitualView`, `RitualCard`, `RitualPhase`, `SpreadKind`, `ParticleConvergeAction`, `particleConverge` environment key — all `public`, all referenced consistently.
- State (`@State phase/deckScale/fanCards/dealtCards/holdTask/...`) lives entirely in `SpreadRitualView`. `RitualTimeline`/`RitualCardState` are **pure stateless value builders** (`enum` with `static` funcs, plain structs). No `@State` was "moved" — animation continuity cannot break because the helpers hold no animation state.

**Verdict: ACCEPT. No behavior-divergence risk (no prior baseline to diverge from).**

---

## Findings by Severity

### HIGH

**H-B1 — Hold-gesture `beginHold` can fire `convergeHook`/animation repeatedly; `endHold` guard lets a stray `.fan`-phase release trigger an unintended deal.**
File: `SpreadRitualView.swift:170-194, 299-323`
The deck attaches **two overlapping gesture recognizers** doing the same thing: a `LongPressGesture.simultaneously(with: DragGesture)` (line 171) AND a separate `.simultaneousGesture(DragGesture)` (line 181). Both call `beginHold()` onChanged and `endHold(triggeredDeal: true)` onEnded. `beginHold` is guarded by `guard !isHolding` (line 300) so double-converge is prevented — OK. But on release **both** gestures' `.onEnded` fire `endHold(triggeredDeal: true)`. First call: `isHolding` true → deals, sets `isHolding = false`. Second call: `guard isHolding || phase == .fan` — `isHolding` is now false, but if the deal transition hasn't moved `phase` off `.fan` yet (it sets `phase = .dealing` synchronously inside `performDeal`, so `phase == .fan` is already false) → guarded out. **This is safe by a narrow margin** (synchronous `phase = .dealing` in `performDeal` line 328 closes the window before the second `.onEnded`). However it is fragile: any future reordering that defers the phase change re-opens a double-deal. Also a fast tap (no perceptible hold) still triggers `beginHold`+`endHold` → instant deal, bypassing the "deep breath" beat entirely — arguably acceptable UX but not the spec's intended ritual.
Fix: collapse to a single gesture (drop the redundant `.simultaneousGesture` at 181-190 — the `LongPressGesture.simultaneously(with: DragGesture)` already covers press+drag), and make `endHold` idempotent with an explicit `guard phase == .hold || phase == .fan else { return }` plus a `dealt` flag so a second invocation is a hard no-op regardless of phase-change timing.

### MEDIUM

**M-B1 — `CardBackURL.cacheKey` ignores scheme & port → dev/prod cache aliasing.**
File: `CardBackURL.swift:20-27`
`cacheKey` = `_back@<host>`. `derive` correctly keeps scheme+port, but the cache key only keys on host. `http://localhost:8080` and `https://localhost:443` (or a TLS-vs-plain dev proxy on the same host) collide to `_back@localhost`. In practice prod is a distinct host (`api.seetarot.com`) so prod/prod is fine, but **two environments sharing a hostname on different ports/schemes will serve a stale or wrong back.png from cache**. Test `testCacheKeyForLocalhost` even encodes this lossy behavior as expected. Low real-world blast radius (back.png is visually identical across envs, only host differs) but it is a latent correctness bug.
Fix: include scheme and port in the key: `_back@\(scheme)://\(host):\(port)`. One-line change; update `testCacheKeyForLocalhost`/`testCacheKeyFormat` accordingly.

**M-B2 — `AmbientBackgroundView` low-power / reduced-motion is evaluated once, not reactive to runtime change.**
File: `AmbientBackgroundView.swift:24`
`ProcessInfo.processInfo.isLowPowerModeEnabled` is read inside `body` but there is no observation of `NSProcessInfoPowerStateDidChange`. `reduceMotion` (Environment) *is* reactive. If the user enables Low Power Mode **while** the particle field is running, the canvas keeps ticking until some unrelated `body` re-eval. Spec: "static-gradient fallback for reduced-motion and low-power" — implies responsiveness to the toggle. Battery/perf risk on exactly the device state the fallback exists to protect.
Fix: observe `Notification.Name.NSProcessInfoPowerStateDidChange` (e.g. via `.onReceive` on a publisher) and store low-power in `@State`, or gate behind a small ObservableObject. Minor.

**M-B3 — `.task(id: tl.date)` recreates a Task every animation frame to drive a fixed-`dt` step.**
File: `AmbientBackgroundView.swift:56-64`
`TimelineView(.animation)` changes `tl.date` ~60×/s; `.task(id:)` therefore **cancels and spawns a new Task ~60 times per second**, each doing one synchronous `system.advance(dt: 1/60, ...)`. The body is trivial so the structured-concurrency churn is the dominant cost, not the math. It also uses a *fixed* `dt = 1/60` regardless of actual elapsed time, so under frame drops the simulation slows down (no catch-up) rather than tunneling — acceptable given the `min(dt, 1/30)` clamp is then moot here. Functionally correct & the per-frame Task is cheap on modern hardware, but it is wasteful and not the idiomatic pattern.
Fix (perf, non-blocking): drive the step synchronously from the `TimelineView` content closure using `tl.date` deltas (compute real `dt` from previous date) instead of `.task(id:)`. Keeps the `min(dt,1/30)` clamp meaningful and eliminates 60 Task allocations/sec. Defer if perf is acceptable on target device — no correctness issue.

### LOW

- **L-B1** `FlipCardView.swift:183` — front cache key is `front.lastPathComponent` (e.g. `the-sun.svg`), not the card id. Two different cards whose image filenames collide across hosts/paths would alias in the loader cache. Edge-case; filenames are card-unique in practice. Note only.
- **L-B2** `ParticleField.swift:197` `nextFloat()` = `Float(next() >> 40) / Float(1<<24)`. `next()` can return 0 on the very first call only if `state == 0`; `Xorshift64` with `state: 0` is a fixed point (stays 0 forever → all particles at origin, zero velocity). `init` seeds with `UInt64.random(in: 1...max)` (never 0) and tests pass explicit non-zero seeds, so unreachable in practice. Recommend a `precondition(state != 0)` or seed-sanitize for defense. Non-blocking.
- **L-B3** `GlowBurstModifier.swift:219-228` spawns an unstructured `Task {}` on every `trigger` change with `Task.sleep`; rapid flip toggling spawns overlapping glow tasks that each animate `opacity`. Last-writer-wins on `@State opacity` so it self-heals visually, but overlapping `withAnimation` on the same state during rapid toggles can produce a brief flicker. Cosmetic, reduced-motion path correctly bypasses it (`flipStyle != .threeDFlip` → no-op). Accept.
- **L-B4** `Coordinator` `@unchecked Sendable` soundness is invariant-dependent and undocumented (see Sendable verdict). Add a comment. Non-blocking.

---

## Spec Compliance Checklist (Hard Constraints)

| Constraint | Status | Evidence |
|---|---|---|
| Card forced 95/155 | PASS | `FlipCardUIView` frame 95×155 (`FlipCardView.swift:141`); `RealCardSurfaceUIView` `.frame(95,155)` (:101); `SpreadLayout.cardWidth/Height` 95/155 |
| Art stretched not letterboxed | PASS | `frontImageView.contentMode = .scaleToFill` (:55), `clipsToBounds` |
| Same stretch on back | PASS | `backImageView.contentMode = .scaleToFill` (:42) |
| Card surface fill #010726 | PASS | `UIColor(red:1/255,green:7/255,blue:38/255,alpha:1)` front & back (:40,:53); Canvas bg `tokens.palette.bg` |
| Back = /cards/back.png runtime-derived (scheme+host, no hardcode) | PASS | `CardBackURL.derive` sets `comps.path="/cards/back.png"`, preserves scheme/host/port, strips query/fragment. No hardcoded base. |
| Name BELOW card | PASS | `RealCardSurfaceUIView` `VStack { FlipCardView; Text(labelText) }` — label outside flip frame (:91-120). UIKit `nameLabel` removed from `FlipCardUIView`. |
| Reversed → artwork 180° + label | PASS | `configure` rotates `frontImageView` by π when reversed (:69); `labelText` appends "(Reversed)" (:135); both from same `reversed` input |
| 3D Y-flip + silver glow at half-flip | PASS | `UIView.transition(.transitionFlipFromLeft/Right)` (:88); `GlowBurstModifier` sleeps `flipDuration/2` then peaks (:223) |
| Reduced-motion → crossfade (no flip) | PASS | `FlipDecision.style` returns `.crossFade` when reduceMotion; `setFaceUp` uses `.transitionCrossDissolve` (:82) |
| Particles TimelineView+Canvas, NO Metal | PASS | `ParticleCanvas` uses `TimelineView(.animation)`+`Canvas`; pure-Swift `ParticleSystem`/`Xorshift64`, no Metal import |
| Reduced-motion/low-power static gradient fallback | PARTIAL | reduced-motion reactive; low-power read once, not reactive (M-B2) |
| Particle count cap | PASS | `ParticleSystem.maxCount = 150`, `min(count,maxCount)` (:54); test `testCountCapEnforced` |
| Pause off-screen / scenePhase | PASS | `.onDisappear → isPaused=true`, `.onChange(scenePhase) → isPaused = phase != .active` (:73-78) |
| CardSurface protocol ADDITIVE only | PASS | `CardSurface` protocol unchanged (`cardView(imageURL:faceUp:position:)`); `RealCardSurface` added optional defaulted `name/reversed/loader` params — backward compatible |
| Celtic logic present, hidden v1 | PASS | `SpreadLayout.celticSlots` defined, only reachable via `count: 10`; `SpreadKind.celtic` defined but no UI entry; `slots(default)` returns `[]` |

---

## Adversarial Verdicts

| Attack | Outcome | Verdict |
|---|---|---|
| Rapid `faceUp` toggling mid-flip | `setFaceUp` uses `FlipDecision` on `wasFaceUp` vs `isFaceUp`; UIKit `UIView.transition` queues; `faceUp` updated before transition. Worst case: visual flip glitch, no crash/state corruption. `Coordinator` dedupes loads. | **Accept** |
| Cell reuse with changed reversed | `lastReversed` dedupe key forces reload + re-`configure` with absolute transform; idempotent. | **Accept** |
| Rapid hold press/release / double gesture | Double `.onEnded` deal is prevented only by synchronous `phase=.dealing` in `performDeal` — fragile (H-B1). | **Reject — fix H-B1** |
| `CardBackURL.derive` nil / no host / no scheme | nil→nil (tested). No-scheme relative URL (`URL(string:"/cards/x.svg")`) → `URLComponents` has nil host; `derive` still sets path → returns `/cards/back.png` with nil scheme/host (a relative URL — loader would fail to fetch but no crash). | **Accept** (degrades safely) |
| `file://` / `data:` URL | `file:///x.svg` → derive yields `file:///cards/back.png` (host nil → cacheKey `_back@unknown`); `data:` URL → `URLComponents` host nil → `_back@unknown`, derive sets path on opaque URL → may produce odd URL but no crash. Loader fetch fails gracefully (nil Data → blank back over #010726 fill). | **Accept** |
| IPv6 / uppercase / IDN host | `URLComponents.host` preserves case → `_back@API.SeeTarot.com` ≠ `_back@api.seetarot.com` would double-cache (cosmetic, harmless). IPv6 `[::1]` host preserved by derive. No crash. | **Accept** (note: case-insensitive host would be tidier — LOW) |
| Particle zero bounds | `step` guards `w>0,h>0` → early return, positions unchanged. Tested `testZeroBoundsDoesNotCrash`. | **Accept** |
| Huge dt tunnelling | `safeDt = min(dt, 1/30)`; tested `testLargeDtDoesNotTunnel` (dt=5.0). Positions stay normalized via `wrap`. | **Accept** |
| NaN injection | `wrap` only handles `<0`/`>1`; NaN fails both → returned as-is. NaN can only enter via NaN bounds/impulse. `bounds` from `geo.size` (never NaN); `impulse` from gesture location (finite). Unreachable in practice; no test. | **Accept** (defer: optional `isFinite` guard, LOW) |
| Resource exhaustion | Particle count hard-capped 150; single `holdTask`/`task` cancelled on replace; deal spawns N short Tasks (N≤10) that self-complete. No unbounded growth. | **Accept** |
| Animation ignoring reduced-motion / blocking input | Flip→crossfade via `FlipDecision`; hold beat skipped in `startReducedMotionPath`; glow no-op when not `.threeDFlip`; particles→static gradient. Gestures use `minimumDistance:0`/`minimumDuration:0` — non-blocking, `.allowsHitTesting(false)` on glow overlay. | **Accept** |

---

## Scope Sub-Score: 8.0 / 10

Strong: M1 fix correct & well-guarded, Sendable handled properly, spec compliance near-complete, excellent pure-function test coverage (49/49), particle sim defensively clamped. Deductions: H-B1 fragile double-gesture deal path (−1.0), M-B1 cache-key aliasing + M-B2 non-reactive low-power (−0.7), M-B3 per-frame Task churn + minor LOW notes (−0.3).

**Recommendation: Fix H-B1 before merge (single-gesture + idempotent `endHold`). M-B1/M-B2 fix-now-or-fast-follow. M-B3 + LOWs defer.**

---

## Unresolved Questions

1. Is instant-deal-on-fast-tap (no perceptible hold) an acceptable ritual UX, or must a minimum hold duration be enforced before deal triggers? Spec describes hold as the "deep breath beat" — current double-gesture allows bypassing it with a tap.
2. M-B1: are there real deployments sharing a hostname across scheme/port (e.g. staging proxy)? If never, M-B1 is purely theoretical and can be deferred.

---

**Status:** DONE_WITH_CONCERNS
**Summary:** M1 fix correct; 2 Sendable warnings definitively benign & already mitigated; SpreadRitual "split" is original structure (no regression risk). Spec compliance near-complete. One HIGH concern: fragile double-gesture deal path (H-B1) should be fixed before merge.
**Concerns/Blockers:** H-B1 (correctness/fragility — recommend fix before merge); M-B1/M-B2 (medium, fast-follow acceptable).
