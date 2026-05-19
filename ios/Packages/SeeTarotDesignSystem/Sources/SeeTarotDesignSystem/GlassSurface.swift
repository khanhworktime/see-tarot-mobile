// GlassSurface.swift — Phase 02, Cosmic Mysticism design system
// Z-stack (bottom→top): outer glow → .ultraThinMaterial → bgLayer1 tint →
// hairline border → inner scrim (bg@0.82) → content.
// Verified contrast at scrimAlpha=0.82: accentBright 16.79:1, accentDim 6.40:1.

import SwiftUI

// MARK: - Constants

private enum GlassMetrics {
    /// Scrim alpha — bg@0.82 over bgLayer1 yields ≥4.5:1 / ≥3.0:1 (ContrastRatioTests).
    static let scrimAlpha: Double = 0.82
    static let tintAlpha: Double = 0.55
    static let glowOpacity: Double = 0.15
    static let glowRadius: CGFloat = 18
    static let hairlineWidth: CGFloat = 1
    static let panelCornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 14
}

// MARK: - GlassSurface

/// Glassmorphic container with near-opaque inner scrim.
/// Use `ScrimText` or `.glassText()` for all text placed inside.
/// Apply `.glassPanel()` or `.glassCard()` to select geometry variant.
public struct GlassSurface<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.glassCornerRadius) private var cornerRadius

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let radius = cornerRadius ?? GlassMetrics.panelCornerRadius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(tokens.palette.bgLayer1.opacity(GlassMetrics.tintAlpha))

            VStack(spacing: 0) { content }
                .padding(.horizontal, tokens.spacing.md)
                .padding(.vertical, tokens.spacing.sm)
                .background(shape.fill(tokens.palette.bg.opacity(GlassMetrics.scrimAlpha)))

            shape.strokeBorder(
                tokens.palette.accentSilver.opacity(0.45),
                lineWidth: GlassMetrics.hairlineWidth
            )
        }
        .shadow(
            color: tokens.palette.accentSilver.opacity(GlassMetrics.glowOpacity),
            radius: GlassMetrics.glowRadius,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Corner-radius environment key

private struct GlassCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var glassCornerRadius: CGFloat? {
        get { self[GlassCornerRadiusKey.self] }
        set { self[GlassCornerRadiusKey.self] = newValue }
    }
}

// MARK: - glassPanel / glassCard modifiers

private struct GlassPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.glassCornerRadius, GlassMetrics.panelCornerRadius)
    }
}

private struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.glassCornerRadius, GlassMetrics.cardCornerRadius)
    }
}

public extension GlassSurface {
    /// Large-panel geometry (corner radius 20): reading panels, detail sheets.
    func glassPanel() -> some View { self.modifier(GlassPanelModifier()) }

    /// Compact-card geometry (corner radius 14): list items, inline tiles.
    func glassCard() -> some View { self.modifier(GlassCardModifier()) }
}

// MARK: - ScrimText

/// Branded text guaranteed to sit on the GlassSurface inner scrim.
/// Use instead of bare `Text` inside a `GlassSurface`.
public struct ScrimText: View {
    @Environment(\.designTokens) private var tokens

    public enum Style {
        case display, title, heading, body, caption
    }

    private let text: String
    private let style: Style

    public init(_ text: String, style: Style = .body) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        Text(text)
            .font(resolvedFont)
            .foregroundStyle(foregroundColor)
            .multilineTextAlignment(.center)
    }

    private var resolvedFont: Font {
        switch style {
        case .display: return tokens.typography.display
        case .title:   return tokens.typography.title
        case .heading: return tokens.typography.heading
        case .body:    return tokens.typography.body
        case .caption: return tokens.typography.caption
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .display, .title, .heading, .body:
            return tokens.palette.accentBright   // ≥4.5:1 on scrim
        case .caption:
            return tokens.palette.accentDim      // ≥3.0:1 on scrim
        }
    }
}

// MARK: - glassText modifier

private struct GlassTextModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let secondary: Bool

    func body(content: Content) -> some View {
        content.foregroundStyle(secondary ? tokens.palette.accentDim : tokens.palette.accentBright)
    }
}

public extension View {
    /// Colours text for WCAG-safe rendering on a `GlassSurface` inner scrim.
    /// Pass `secondary: true` for `accentDim` (≥3.0:1); default uses `accentBright` (≥4.5:1).
    func glassText(secondary: Bool = false) -> some View {
        modifier(GlassTextModifier(secondary: secondary))
    }
}
