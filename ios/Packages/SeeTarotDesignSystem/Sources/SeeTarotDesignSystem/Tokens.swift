import SwiftUI

/// Design tokens: Cosmic Mysticism palette + Cinzel/Lora typography.
/// Values, not singletons — injected via the SwiftUI environment
/// (decision 0004 / product overview).
public struct DesignTokens: Sendable {

    // MARK: - Palette

    public struct Palette: Sendable {
        // ── Legacy fields (kept for callers across Features) ──────────────────
        // Values remapped to Cosmic Mysticism; names unchanged.
        /// Silver accent — primary accent, icons, hairlines. #C9D2E3
        public let accent: Color
        /// Deep-space screen background. #010726
        public let background: Color
        /// First depth layer / glass tint. #050B2E
        public let surface: Color
        /// Primary text / active glow core. #E8EDF7
        public let textPrimary: Color
        /// Secondary text / inactive. #8A93A8
        public let textSecondary: Color

        // ── New semantic fields ───────────────────────────────────────────────
        /// Screen + card surface background. #010726
        public let bg: Color
        /// First glass/depth layer. #050B2E
        public let bgLayer1: Color
        /// Second glass/depth layer. #0A1140
        public let bgLayer2: Color
        /// Primary accent (silver). #C9D2E3
        public let accentSilver: Color
        /// Active / selected / glow core. #E8EDF7
        public let accentBright: Color
        /// Secondary text / inactive. #8A93A8
        public let accentDim: Color
        /// Particles, sparkle, constellation. #FFFFFF — apply alpha at use site.
        public let starlight: Color

        /// Cosmic Mysticism palette.
        public static let cosmic = Palette(
            // Legacy names, remapped values
            accent: hex(0xC9D2E3),
            background: hex(0x010726),
            surface: hex(0x050B2E),
            textPrimary: hex(0xE8EDF7),
            textSecondary: hex(0x8A93A8),
            // New semantic fields
            bg: hex(0x010726),
            bgLayer1: hex(0x050B2E),
            bgLayer2: hex(0x0A1140),
            accentSilver: hex(0xC9D2E3),
            accentBright: hex(0xE8EDF7),
            accentDim: hex(0x8A93A8),
            starlight: .white
        )

        // MARK: Hex helper

        private static func hex(_ value: UInt32) -> Color {
            let r = Double((value >> 16) & 0xFF) / 255
            let g = Double((value >> 8) & 0xFF) / 255
            let b = Double(value & 0xFF) / 255
            return Color(red: r, green: g, blue: b)
        }
    }

    // MARK: - Typography

    /// Font tokens backed by Cinzel (display/heading) and Lora (body/caption).
    /// Each token scales with Dynamic Type via `Font.custom(_:size:relativeTo:)`,
    /// which uses the same UIFontMetrics scaling as system text styles.
    ///
    /// H1-A: Resolution behaviour for each family (verified on iOS simulator):
    ///   Cinzel — ships static named instances with EXACT PostScript-name records:
    ///            "Cinzel-Regular", "CinzelRoman-Bold", "CinzelRoman-Black".
    ///            `Font.custom` resolves these exactly on iOS — safe to name weights.
    ///   Lora   — single-axis (wght 400–700) variable font whose ONLY PostScript
    ///            name is "Lora-Regular" (no "Lora-Medium"/"Lora-Bold" records).
    ///            iOS `UIFont(name:)`/`Font.custom` does NOT fuzzy-match by weight
    ///            (only macOS CoreText does) — so `.custom("Lora-Medium")` on iOS
    ///            silently falls back to the SYSTEM font, not Lora. Therefore every
    ///            Lora token uses the one safe name "Lora-Regular"; caption is
    ///            differentiated by size (13 vs body 17), not weight. A non-Regular
    ///            Lora weight would require a `kCTFontVariationAttribute` wght
    ///            descriptor (not used — caption Regular is the design decision).
    ///
    /// System .serif (New York) is the fallback only if a family is entirely absent.
    /// FontWeightResolutionTests runs on the iOS sim and fails CI if any token
    /// resolves to a non-brand (system) family.
    public struct Typography: Sendable {
        /// Display — Cinzel Black, large ceremonial use.
        public let display: Font
        /// Title — Cinzel Bold, primary screen headers.
        public let title: Font
        /// Heading — Cinzel Regular, section headers.
        public let heading: Font
        /// Body — Lora Regular, primary reading text.
        public let body: Font
        /// Caption — Lora Regular at 13pt, supporting / meta text. (Lora has no
        /// iOS-resolvable Medium PS name; size differentiates it from body.)
        public let caption: Font
        /// Tabular figures for quota counts and timers (Lora-Regular + monospacedDigit).
        public let quotaFigures: Font

        static let `default` = Typography(
            display: .custom("CinzelRoman-Black", size: 34, relativeTo: .largeTitle),
            title: .custom("CinzelRoman-Bold", size: 28, relativeTo: .title),
            heading: .custom("Cinzel-Regular", size: 20, relativeTo: .title2),
            body: .custom("Lora-Regular", size: 17, relativeTo: .body),
            caption: .custom("Lora-Regular", size: 13, relativeTo: .footnote),
            quotaFigures: .custom("Lora-Regular", size: 17, relativeTo: .body).monospacedDigit()
        )
    }

    // MARK: - Spacing

    public struct Spacing: Sendable {
        public let xs: CGFloat = 4
        public let sm: CGFloat = 8
        public let md: CGFloat = 16
        public let lg: CGFloat = 24
        public let xl: CGFloat = 40
    }

    // MARK: - Motion

    public struct Motion: Sendable {
        public let quick = Animation.easeOut(duration: 0.2)
        public let standard = Animation.easeInOut(duration: 0.35)
        public let ambient = Animation.easeInOut(duration: 6).repeatForever(autoreverses: true)
    }

    // MARK: - Token root

    public let palette: Palette
    public let typography: Typography
    public let spacing: Spacing
    public let motion: Motion

    public static let `default` = DesignTokens(
        palette: .cosmic,
        typography: .default,
        spacing: Spacing(),
        motion: Motion()
    )
}

// MARK: - Environment injection

private struct DesignTokensKey: EnvironmentKey {
    static let defaultValue = DesignTokens.default
}

public extension EnvironmentValues {
    var designTokens: DesignTokens {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}
