// PhosphorIcon.swift — DesignSystem / Phase 09-Pass2 (Phosphor icon wrapper)
//
// Approach: Option B — curated Phosphor SVG imagesets bundled directly in
// SeeTarotDesignSystem/Resources/PhosphorIcons.xcassets (MIT-licensed; see
// Resources/PHOSPHOR_LICENSE.txt). The upstream phosphor-icons/swift Package.swift
// omits `resources:` in its target so Bundle.module synthesis fails on macOS SPM
// host builds. Bundling a curated subset in DesignSystem avoids the fork and keeps
// the dependency surface minimal (KISS).
//
// Usage: phosphorIcon("moon-stars-duotone")
//        phosphorIcon("star-duotone").foregroundStyle(...)
//
// Available icons (14 curated for Login + near-future tabs):
//   moon-stars-duotone, moon-stars-fill, moon-duotone, sun-duotone,
//   star-duotone, star-four-duotone, sparkle-duotone, sparkle-fill,
//   planet-duotone, hexagon-duotone, google-logo-fill,
//   cards-three-duotone, magic-wand-duotone, eye-duotone
//
// SVGs use template rendering — apply .foregroundStyle / .foregroundColor freely.

import SwiftUI

// MARK: - phosphorIcon

/// Returns a SwiftUI `Image` from the bundled Phosphor SVG asset catalog.
/// Template rendering is set on each imageset — use `.foregroundStyle(_:)` to tint.
///
/// - Parameter name: Asset name exactly as in PhosphorIcons.xcassets/SVG/ (without extension).
///   Example: `"moon-stars-duotone"`, `"google-logo-fill"`.
public func phosphorIcon(_ name: String) -> Image {
    Image(name, bundle: .module)
}
