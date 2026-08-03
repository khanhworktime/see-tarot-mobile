# Code Review — SCOPE A: DesignSystem Foundation

Branch `feat/ui-cosmic-redesign` vs `main`. Presentation-only re-skin. Read-only review.
Independent verification (math recomputed in Python, font names extracted from TTF binary + CoreText probe). Prior review consulted, not echoed.

## Scope
- Tokens.swift, FontRegistrar.swift, GlassSurface.swift, ContrastRatio.swift, Components.swift, Package.swift, ContrastRatioTests.swift, Info.plist, SeeTarotApp.swift
- ~749 LOC added. Fonts bundled (Cinzel.ttf 125KB, Lora.ttf 212KB) + OFL committed.

## Overall Assessment
Solid foundation. Palette exact, contrast math correct and conservatively robust, env-injection preserved, zero singletons, no legacy-field rename → no Features break. One real correctness-doc defect (Lora PostScript name comment is false; fonts still render correctly via CoreText fuzzy match — robustness risk not visual bug). FontRegistrar has a benign-in-practice unsynchronized static + a silent-failure path worth tightening.

---

## SPEC COMPLIANCE CHECKLIST (vs ui-design-intake.md)

| Item | Result |
|---|---|
| `bg` #010726 | PASS (Tokens.swift:49) |
| `bgLayer1` #050B2E / `bgLayer2` #0A1140 | PASS (50–51) |
| `accentSilver` #C9D2E3 | PASS (52) |
| `accentBright` #E8EDF7 | PASS (53) |
| `accentDim` #8A93A8 | PASS (54) |
| `starlight` white @ low α (α at use site) | PASS (55; doc’d "apply alpha at use site") |
| Legacy fields RETAINED, not renamed | PASS — accent/background/surface/textPrimary/textSecondary still present (14–22), values remapped, no caller in Features uses them |
| Legacy remap semantically consistent | PASS — accent→silver, background→bg, surface→bgLayer1, textPrimary→accentBright, textSecondary→accentDim |
| Typography Cinzel display/title/heading | PASS (95–97); names resolve EXACT via CoreText |
| Typography Lora body/caption | PARTIAL — body `Lora-Regular` EXACT; caption `Lora-Medium` does NOT match a registered PostScript name, CoreText fuzzy-resolves to `Lora-Regular_Medium` (correct weight 0.2). Renders correctly but by fuzzy fallback, not exact contract. See H1. |
| quotaFigures tabular | PASS (100) `.monospacedDigit()` on Lora-Regular |
| `relativeTo:` Dynamic Type scaling | PASS (95–100) all tokens use `relativeTo:` |
| Env injection, ZERO singletons | PASS — DesignTokens is a value struct via EnvironmentKey (139–148); no shared mutable token state |
| Fonts bundled .ttf NOT CDN | PASS — Resources/Fonts/*.ttf, `.process("Resources")` (Package.swift:12); UIAppFonts set (Info.plist:30–34) |
| OFL committed | PASS — OFL-Cinzel.txt, OFL-Lora.txt (SIL OFL 1.1, correct copyright headers; Lora RFN "Lora") |
| Scrim α=0.82 ≥4.5:1 bright / ≥3:1 dim | PASS — independently recomputed: bright 16.79:1, dim 6.40:1 |
| WCAG formula correctness | PASS — threshold 0.04045 (correct modern value, NOT the legacy-wrong 0.03928), coeffs 0.2126/0.7152/0.0722, (L+0.05) ratio all correct |

---

## FINDINGS

### High

**H1 — Lora bold/medium/semibold PostScript names in code & doc-comment are factually wrong; rendering survives only by CoreText fuzzy matching.**
`Tokens.swift:76` comment claims `"Lora-Regular", "Lora-Medium", "Lora-SemiBold", "Lora-Bold"` are "PostScript names verified from bundled variable TTFs." Verified against the TTF binary: Lora is a single-axis (`wght` 400–700) variable font. Its named instances carry **no** PostScript-name records. CoreText auto-derives instance faces with PostScript names in **underscore** form: `Lora-Regular_Medium`, `Lora-Regular_SemiBold`, `Lora-Regular_Bold`. The token `caption = .custom("Lora-Medium", …)` (Tokens.swift:99) and `Components.swift:24` `body.weight(.semibold)` therefore request names that do not exist as registered PostScript names. CoreText’s family fuzzy-matcher *does* resolve `"Lora-Medium"` → `Lora-Regular_Medium` (confirmed: weight trait 0.2 = true Medium), so text renders at the correct weight today. Risk: relies on undocumented CoreText fuzzy behavior, not a guaranteed contract — a future OS/toolchain change in name resolution could silently degrade caption to Regular weight with no error. Cinzel by contrast has explicit instance PostScript names (`CinzelRoman-Bold/-Black`) and resolves EXACT.
Fix: either (a) use the exact registered names `Lora-Regular_Medium` etc., or (b) drive weight via SwiftUI `.fontWeight(.medium)` on the base `Lora-Regular` family, or (c) at minimum correct the false "verified" comment on Tokens.swift:74–76 to state the names are CoreText-fuzzy-resolved instance aliases, and add a unit test asserting `CTFontCopyTraits` weight for the caption font ≈ 0.2 so a future resolution regression fails CI.

### Medium

**M1 — FontRegistrar.isRegistered: unsynchronized static mutable across non-isolated API.**
`FontRegistrar.swift:17,23,28` — `private static var isRegistered` is read+written with no isolation/lock in a `nonisolated` enum API. Package builds in `swiftLanguageMode(.v5)` so Swift 6 strict-concurrency does not flag it. Today it is only called once from `SeeTarotApp.init()` (SeeTarotApp.swift:8) on the main thread, so no race occurs in practice. But `registerAll()`'s signature invites off-main / concurrent calls; two concurrent first-calls could double-invoke `CTFontManagerRegisterFontsForURL` (CoreText is internally safe and treats re-register as non-error, so worst case is a benign log line). Defer-grade. Fix: annotate `@MainActor public static func registerAll()` (matches its real call context and documents the contract) or guard with `dispatch_once`/`os_unfair_lock`.

**M2 — Silent registration-failure path can mask a real packaging/corruption fault.**
`FontRegistrar.swift:40–43` — on `CTFontManagerRegisterFontsForURL` error the code `print`s and continues; `isRegistered` is still set `true` at line 23 regardless of per-file outcome. If `Cinzel.ttf` is corrupt/unregisterable in a release build, the app silently falls back to system serif with only a `print` (invisible in production) and the idempotency guard then blocks any retry. Acceptable as a graceful-degradation choice, but the success flag should reflect actual success. Fix: only set `isRegistered = true` if every file registered without error; on partial failure leave it false (allows a later retry) and surface via a returned `Bool`/`os_log` at `.error` rather than `print`.

### Low

**L1 — ContrastRatioTests does not test the true in-context stack the spec mandates.**
Spec line 61: "Verify both in-context, not in isolation." The test composites only `bg@0.82 over bgLayer1` (ContrastRatioTests.swift:30–32), omitting the `.ultraThinMaterial` + tint layers that sit *below* the 0.82 (non-opaque) scrim — ~18% of material/starfield bleeds through. I recomputed the realistic worst case (scrim over a pure-white starfield pixel): accentBright 10.45:1, accentDim 3.98:1 — still passes ≥4.5/≥3.0, so the simplification is safe. But the test’s comment overstates rigor. Fix: add a worst-case test asserting accentDim ≥3.0 with under-scrim = white, documenting the bleed-through margin.

**L2 — GlassMetrics.scrimAlpha and ContrastRatioTests.scrimAlpha are duplicated constants (DRY).**
`GlassSurface.swift:12` and `ContrastRatioTests.swift:25` both hardcode `0.82` with a "must stay in sync" comment. The boundary-guard test (testScrimAlphaIsAtLeastSpec) checks the *test’s* copy, not GlassMetrics — lowering `GlassMetrics.scrimAlpha` would NOT fail CI. Fix: expose `GlassMetrics.scrimAlpha` (or a public constant) and have the test import it so the guard actually protects the production value.

### Nit

**N1 — Tokens.swift:78–79 comment "System .serif (New York) is the automatic fallback … SwiftUI resolves Font.custom gracefully."** True for missing font, but the practical fallback here for an unmatched weight is *Lora-Regular*, not New York (CoreText finds the family). Comment slightly misleads about which fallback fires. Tie to H1 fix.

**N2 — `starlight: .white` (Tokens.swift:55):** correct per spec ("apply alpha at use site"), but no compile-time guard prevents a caller using it at α=1.0 on the scrim (white@1 on scrim = 18.9:1, fine) — non-issue, noted only because adversarial brief asked. No action.

---

## ADVERSARIAL RED-TEAM VERDICTS

| Attack | Verdict | Notes |
|---|---|---|
| Lora-Medium/SemiBold/Bold names don’t exist as PostScript names | **Accept (must-fix → H1)** | Renders correctly *now* via CoreText fuzzy match; doc comment is false; no regression test guards it |
| Missing font file | Reject (false-positive) | Handled: `assertionFailure` (debug) + graceful return; UIAppFonts is belt-and-suspenders |
| Corrupt TTF / registration failure swallowed → silent fallback masks bug | **Accept (must-fix → M2)** | `print` invisible in prod; `isRegistered=true` set despite failure blocks retry |
| Concurrent registerAll() calls / data race on isRegistered | **Defer (M1)** | Real unsynchronized static but single main-thread caller today; harden with @MainActor |
| nil rgbaComponents | Reject | iOS path uses UIColor.getRed (always succeeds for sRGB Color); macOS path guarded; documented nil contract |
| P3 / extended-range color into luminance | Reject (out of scope) | All palette colors are sRGB hex literals; getRed clamps to sRGB; no P3 token exists |
| .white starlight at low α breaking contrast | Reject | white over scrim ≥18:1 at any α; not used as scrim text |
| Palette remap silently changes a legacy caller’s appearance | Reject | Only legacy consumers are in-scope (PrimaryButton/LoadingView); zero Features references to legacy fields; old `Palette.system` factory removed but no external caller |
| Hardcoded hex vs token drift | Reject | All hex centralized in `Palette.hex(_:)`; tests mirror exact hex; no stray Color(red:…) in scope files |
| Removed Palette.system breaks SeeTarotDesignSystemTests | Reject | testEnvironmentDefaultIsSystemPalette only asserts spacing; no `.system` reference |
| WCAG threshold uses legacy-wrong 0.03928 | Reject (false-positive) | Code uses correct 0.04045 (ContrastRatio.swift:38); brief’s "0.03928" was a trap |
| Scrim not opaque enough in realistic stack | Reject | Worst-case (white starfield bleed-through) still 3.98:1 dim / 10.45:1 bright |

---

## Positive Observations
- WCAG implementation textbook-correct (correct 0.04045 threshold — many impls ship the erroneous 0.03928).
- `SRGBColor` deliberately named to dodge QD.framework `RGBColor` collision on macOS targets — good defensive call.
- Legacy fields preserved verbatim → genuine zero-break presentation refactor; verified no Features regression.
- Env-injection token pattern fully intact; DesignTokens remains a Sendable value type, no singleton introduced.
- OFL licenses correctly committed with intact copyright + Reserved Font Name.
- Cinzel typography names verified EXACT against TTF instance PostScript records.

## Recommended Actions (priority order)
1. H1 — correct Lora name comment + use registered/exact weight path or `.fontWeight`; add weight-trait regression test.
2. M2 — gate `isRegistered=true` on full success; replace `print` with `os_log(.error)`; return Bool.
3. M1 — `@MainActor` on `registerAll()` to document/enforce real call contract.
4. L1/L2 — add white-starfield worst-case contrast test; single-source scrimAlpha so the guard protects production.

## Metrics
- Spec compliance: 17/19 PASS, 1 PARTIAL (Lora caption), 1 expected-partial (in-context test).
- Contrast: independently recomputed, matches file claims to 3 d.p.
- Tests in ContrastRatioTests: 10 (per build-is-ground-truth note: green).
- Scope sub-score: **8.0 / 10** (−1.0 H1 false "verified" comment + fragile name resolution, −0.5 M2 silent-failure masking, −0.5 M1/L2 hardening/DRY).

## Unresolved Questions
1. Is the Lora weight fuzzy-resolution (`Lora-Medium` → `Lora-Regular_Medium`) stable across the target OS range (iOS 17 + macOS 13 deployment)? Verified on this host’s CoreText only; recommend an on-simulator weight-trait assertion before merge.
2. Was the deletion of `Palette.system` (adaptive light/dark platform palette) an intended product decision (app is now fixed-dark everywhere, ignoring system appearance)? Spec implies yes (cosmic dark) but confirm no light-mode requirement exists for any surface.

---
**Status:** DONE_WITH_CONCERNS
**Summary:** Palette/contrast/env-injection/no-rename all PASS and independently verified; one High (false Lora PostScript-name comment + fragile fuzzy resolution, renders OK today but unguarded) and two Medium (silent font-failure masking, unsynchronized static) to fix before merge.
**Concerns/Blockers:** H1 is a correctness-documentation defect with latent regression risk — recommend addressing + adding the weight-trait test prior to landing Scope A.
