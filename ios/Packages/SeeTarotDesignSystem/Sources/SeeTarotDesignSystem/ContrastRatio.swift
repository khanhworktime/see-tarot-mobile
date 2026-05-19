// ContrastRatio.swift — Phase 02, Cosmic Mysticism design system
// Pure WCAG 2.1 §1.4.3 contrast-ratio utilities.
// No SwiftUI/UIKit dependency: Color→RGBA extraction via UIColor on iOS.
//
// Verified scrim α: bg (#010726) @ 0.82 over bgLayer1 (#050B2E)
//   → accentBright (#E8EDF7) 16.79:1  (requirement ≥4.5:1 ✓)
//   → accentDim    (#8A93A8)  6.40:1  (requirement ≥3.0:1 ✓)
//
// Used by: Phase 02 unit tests, Phase 09 accessibility audit.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - RGB triple

/// sRGB colour triple — components in [0, 1].
/// Named `SRGBColor` (not `RGBColor`) to avoid the legacy `RGBColor` struct
/// in QD.framework / Quickdraw.h that is pulled in on macOS build targets.
public struct SRGBColor: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

// MARK: - Relative luminance (WCAG 2.1 §1.4.3)

/// Returns the linearised sRGB component value per WCAG 2.1.
@inlinable
func wcagLinearize(_ channel: Double) -> Double {
    channel <= 0.04045
        ? channel / 12.92
        : pow((channel + 0.055) / 1.055, 2.4)
}

/// WCAG relative luminance for an sRGB triple (components in [0, 1]).
public func wcagLuminance(r: Double, g: Double, b: Double) -> Double {
    0.2126 * wcagLinearize(r)
        + 0.7152 * wcagLinearize(g)
        + 0.0722 * wcagLinearize(b)
}

// MARK: - ContrastRatio

/// Namespace for WCAG 2.1 contrast-ratio computations.
public enum ContrastRatio {

    /// WCAG contrast ratio between two luminance values (0…1). Always ≥1.0.
    public static func ratio(l1: Double, l2: Double) -> Double {
        let lighter = max(l1, l2)
        let darker  = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// WCAG contrast ratio between two sRGB colours. Returns a value ≥1.0.
    public static func wcag(fg: SRGBColor, over bg: SRGBColor) -> Double {
        let fgL = wcagLuminance(r: fg.red, g: fg.green, b: fg.blue)
        let bgL = wcagLuminance(r: bg.red, g: bg.green, b: bg.blue)
        return ratio(l1: fgL, l2: bgL)
    }
}

// MARK: - RGBA extraction

/// RGBA colour in [0, 1] extracted from a SwiftUI `Color`.
public struct RGBA: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public var rgb: SRGBColor { SRGBColor(red: red, green: green, blue: blue) }
}

public extension Color {
    /// Extracts RGBA components in the sRGB colour space.
    /// Returns `nil` only when no platform colour-space bridge is available.
    func rgbaComponents() -> RGBA? {
#if canImport(UIKit)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return RGBA(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
#elseif canImport(AppKit)
        // macOS fallback — needed so package tests compile on macOS CI.
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return RGBA(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            alpha: Double(nsColor.alphaComponent)
        )
#else
        return nil
#endif
    }
}

// MARK: - Composite helper

/// Alpha-composite `fg` @ `alpha` over `bg` @ 1.0. Returns an opaque sRGB colour.
public func alphaComposite(fg: SRGBColor, alpha: Double, over bg: SRGBColor) -> SRGBColor {
    SRGBColor(
        red: fg.red * alpha + bg.red * (1 - alpha),
        green: fg.green * alpha + bg.green * (1 - alpha),
        blue: fg.blue * alpha + bg.blue * (1 - alpha)
    )
}
