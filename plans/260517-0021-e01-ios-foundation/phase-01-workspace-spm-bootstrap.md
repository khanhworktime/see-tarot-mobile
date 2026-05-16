# Phase 01 — Workspace & SPM Bootstrap

Context: `plan.md`, `docs/decisions/0004-*`, story `design.md`.

## Overview

Priority: P0 (blocks all). Status: done (2026-05-17).

Evidence: `xcodebuild ... build` → BUILD SUCCEEDED (all 6 packages compiled);
app installed + launched on iOS simulator (process running); SwiftLint exit 0.
Note: project generated via `xcodegen` (project.yml) — `.xcodeproj` gitignored.
Metal shader deferred to Phase 06 (missing Metal toolchain component;
`xcodebuild -downloadComponent MetalToolchain` required there).
Create the `ios/` Xcode project + local Swift Package graph. Empty app builds
and runs on an iOS 17 simulator. No features yet.

## Key Insights

- Harness v0: this phase is the first authorized `ios/` source (E01 story).
- Modular SPM = independent compilation + reuse for future Android contract
  parity (decision 0004).
- `API_BASE_URL` via build config (xcconfig/Info.plist), never hardcoded.

## Requirements

- iOS deployment target 17.0. SwiftUI lifecycle (`App`).
- Local SPM packages (one `Package.swift` per package, in `ios/Packages/`):
  `SeeTarotCore`, `SeeTarotNetworking`, `SeeTarotPersistence`,
  `SeeTarotDesignSystem`, `SeeTarotCardEngine`, `SeeTarotFeatures`.
- App target depends on packages; packages layered (Features → others; Core has
  no internal deps; Networking/Persistence depend on Core).
- SwiftLint config (lenient per dev rules — no syntax/compile errors, not strict
  style). File <200 lines convention documented in package README.

## Architecture

```
ios/
  SeeTarot.xcodeproj (or .xcworkspace)
  SeeTarot/            app target: App entry, Info.plist, xcconfig
  Packages/
    SeeTarotCore/
    SeeTarotNetworking/      depends: Core
    SeeTarotPersistence/     depends: Core
    SeeTarotDesignSystem/
    SeeTarotCardEngine/      depends: DesignSystem
    SeeTarotFeatures/        depends: all above
  .swiftlint.yml
```

## Related Code Files

Create:
- `ios/SeeTarot.xcodeproj` (project; app target `SeeTarot`)
- `ios/SeeTarot/SeeTarotApp.swift` (App entry, root placeholder view)
- `ios/SeeTarot/Config/Debug.xcconfig`, `Release.xcconfig` (`API_BASE_URL`)
- `ios/SeeTarot/Info.plist` (reads `API_BASE_URL`)
- `ios/Packages/<Pkg>/Package.swift` + `Sources/<Pkg>/<Pkg>.swift` (×6, stub)
- `ios/.swiftlint.yml`
- `ios/README.md` (update: build steps, package layering, file-size rule)

## Implementation Steps

1. Create Xcode project `SeeTarot`, iOS 17, SwiftUI App lifecycle.
2. Add xcconfig files; wire `API_BASE_URL` into Info.plist; expose via a typed
   `AppConfig` in app target.
3. Create 6 local SPM packages with correct dependency edges; add to project as
   local package refs; link to app target.
4. Add minimal exported symbol per package so it compiles.
5. Add `.swiftlint.yml` (warnings not errors; exclude `.build`).
6. Root placeholder `ContentView` ("See Tarot — foundation").
7. Build + run simulator (iOS 17).

## Todo List

- [ ] Xcode project created (iOS 17, SwiftUI)
- [ ] xcconfig + Info.plist `API_BASE_URL` wired, `AppConfig` typed accessor
- [ ] 6 SPM packages created with layered deps
- [ ] SwiftLint config added
- [ ] App builds + runs on iOS 17 simulator

## Success Criteria

`xcodebuild -scheme SeeTarot -destination 'iOS Simulator' build` succeeds; app
launches showing placeholder; each package builds via `swift build` in its dir.

## Risk Assessment

- Local SPM ↔ Xcode integration friction → use project local package refs, not
  a workspace-only setup; verify each package builds standalone.

## Security Considerations

- No secrets in xcconfig committed; only non-secret base URL. `.gitignore`
  already excludes `*.env`.

## Next Steps

Phase 02 fills `SeeTarotCore` with domain models.
