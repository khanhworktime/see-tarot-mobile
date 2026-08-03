# Phase 01 — Design Tokens + Bundled Fonts + Color Foundation

## Context Links
- `docs/product/ui-design-intake.md` §Color, §Typography
- Seam: `ios/Packages/SeeTarotDesignSystem/Sources/SeeTarotDesignSystem/Tokens.swift`
- `ios/SeeTarot/Info.plist`

## Overview
- Priority: P1 (unblocks all phases)
- Status: done
- Replace indigo brand palette with Cosmic Mysticism palette, bundle
  Cinzel/Lora `.ttf`, expose Dynamic-Type-scaled font tokens. Keep the
  environment-injection token pattern.
- **Completion evidence:** Tokens.swift rewritten with Cosmic palette (0x010726 bg,
  Cinzel/Lora typography + UIFontMetrics), FontRegistrar registered at app launch,
  DesignSystem + Features + app target build green (xcodebuild clean PASS).

## Key Insights
- `DesignTokens` already injected via `EnvironmentValues.designTokens`
  (`DesignTokensKey`). Pattern stays — only values change.
- `Typography` currently uses system `Font.largeTitle` etc. Must become
  bundled-font-backed and scale via `UIFontMetrics` so Dynamic Type works.
- `DesignSystem/Package.swift` has NO `resources:` declaration — must add one
  with `.process` for the fonts; SPM bundle = `Bundle.module`.
- App target `Info.plist` is at `ios/SeeTarot/Info.plist`. `UIAppFonts` must
  list the bundled filenames AND the font files must ship in the app bundle.
  Because fonts live in the SPM resource bundle, register them at runtime via
  `CTFontManagerRegisterFontsForURL` from `Bundle.module` (Info.plist UIAppFonts
  alone won't see SPM-bundled files). Provide a `FontRegistrar.registerAll()`
  called once at app launch.
- Palette must add: `bg #010726`, `bgLayer1 #050B2E`, `bgLayer2 #0A1140`,
  `accent #C9D2E3`, `accentBright #E8EDF7`, `accentDim #8A93A8`,
  `starlight #FFFFFF` (low α applied at use site).
- Existing `palette` fields (`accent/background/surface/textPrimary/
  textSecondary`) are consumed across Features — keep these names, remap their
  values, ADD new fields. Renaming would break callers (out of scope).

## Requirements
Functional:
- New palette values exact-hex; old field names retained, remapped:
  `background→bg`, `surface→bgLayer1`, `accent→accent (silver)`,
  `textPrimary→accentBright`, `textSecondary→accentDim`.
- Add fields: `bg, bgLayer1, bgLayer2, accent, accentBright, accentDim,
  starlight`.
- Typography tokens backed by Cinzel (display/title/heading) + Lora (body/
  caption), scaled with `UIFontMetrics` per text style; system `.serif` (New
  York) fallback if glyph/weight missing. Tabular figures variant for
  quota/timer.
- Fonts registered at launch from `Bundle.module`.

Non-functional:
- No singletons; environment injection preserved.
- DesignSystem package + dependents still compile (Swift 6, language mode v5).
- SIL OFL license files committed alongside `.ttf`.

## Architecture
Data flow: app launch → `FontRegistrar.registerAll()` (idempotent, reads
`Bundle.module` font URLs) → `DesignTokens.default` Typography returns
`Font.custom("Cinzel-..." , size:relativeTo:)` wrapped by
`UIFontMetrics`-scaled sizes → views read `\.designTokens` unchanged.

## Related Code Files
Modify:
- `DesignSystem/Sources/SeeTarotDesignSystem/Tokens.swift`
- `DesignSystem/Package.swift` (add `resources: [.process("Resources")]`)
- `ios/SeeTarot/Info.plist` (UIAppFonts entries, harmless even if SPM-runtime
  registration is the load path; documents intent)
- `ios/SeeTarot/SeeTarotApp.swift` (call `FontRegistrar.registerAll()` at init)
Create:
- `DesignSystem/Sources/SeeTarotDesignSystem/FontRegistrar.swift`
- Fonts ALREADY committed: `DesignSystem/Sources/SeeTarotDesignSystem/Resources/Fonts/Cinzel.ttf`,
  `Lora.ttf` (variable TTF, weight axis: Cinzel Regular/Bold/Black, Lora
  Regular/Medium/SemiBold/Bold+Italic) + `OFL-Cinzel.txt`, `OFL-Lora.txt`.

## Implementation Steps
1. ✅ Cinzel + Lora `.ttf` (SIL OFL) + license already placed in
   `Resources/Fonts/` — variable fonts, select weights via font traits.
2. Add `resources: [.process("Resources")]` to the DesignSystem target.
3. Add `FontRegistrar.swift`: enumerate font URLs in `Bundle.module`,
   `CTFontManagerRegisterFontsForURL`, guard against double-registration.
4. Rewrite `Palette`: keep 5 existing field names remapped to new hex; add 7
   new named fields. `Color(red:green:blue:)` from hex helper.
5. Rewrite `Typography`: each token = `Font.custom(name, size:, relativeTo:)`;
   add `quotaFigures` (monospaced/tabular) token.
6. Add `Info.plist` `UIAppFonts` array (filenames) — belt-and-suspenders.
7. Call `FontRegistrar.registerAll()` in `SeeTarotApp` init before first view.
8. Build DesignSystem + Features + app target.

## Todo List
- [x] Fonts + OFL committed under Resources/Fonts
- [x] Package.swift resources declared
- [x] FontRegistrar implemented + idempotent
- [x] Palette: 5 remapped + 7 new fields, exact hex
- [x] Typography Cinzel/Lora + UIFontMetrics scaling + tabular token
- [x] Info.plist UIAppFonts + app-launch registration
- [x] DesignSystem & Features & app build green

## Success Criteria
- [x] App renders text in Cinzel/Lora (visually verify a heading + body).
- [x] Dynamic Type at XXL scales type with no truncation on Home.
- [x] `DesignTokens` still resolved via `\.designTokens`; zero singleton.
- [x] All packages + app build; existing DesignSystem tests pass.

## Risk Assessment
| Risk | L×I | Mitigation |
|---|---|---|
| SPM-bundled fonts not seen by UIAppMain | M×H | Runtime `CTFontManagerRegisterFontsForURL` from `Bundle.module` (primary path); Info.plist secondary |
| Renaming palette fields breaks callers | M×H | Keep existing names; remap values, only ADD new fields |
| Font glyph/weight missing | L×M | System `.serif` fallback via `Font.custom(_:size:).fallback` pattern |
| Dynamic Type truncation | M×M | `relativeTo:` + UIFontMetrics; covered in Phase 09 audit |

## Security Considerations
None (no data, no network). Verify font license files committed (legal).

## Next Steps
Unblocks 02, 03, 04. Hand off palette field names + Typography token names to
all downstream phases.
