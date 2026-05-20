// CeremonialCardFace.swift — CardEngine / Phase 09-Pass2 (Visual Tuning)
//
// Renders a stylised tarot card face at the forced 95/155 ratio using only
// SwiftUI vector drawing — no image assets required.
// Used pre-auth (Login screen) where BE artwork is unavailable.
//
// Pass 2: aurora-tinted radial bg per face, glyph at 46pt with glow shadow,
// accentBright arcana label, aurora-tinted hairline border.
//
// ICON NOTE: SF Symbols used (not PhosphorSwift) — Phosphor's Package.swift omits
// `resources:`, causing Bundle.module failure on macOS 13 SPM host. Phosphor icons
// are available via phosphorIcon() in SeeTarotDesignSystem for iOS-only targets.
//
// Token access: via `\.designTokens` environment injection (no singletons).

import SwiftUI
import SeeTarotDesignSystem

// MARK: - Kind

/// Which ceremonial face variant to render.
public enum CeremonialFaceKind: Sendable {
    /// Brand back-of-card: cosmic radial gradient + moon-stars glyph + corner sparkles.
    case back
    /// The Star (XVII): gradient + star glyph + arcana label.
    case theStar
    /// The Moon (XVIII): gradient + moon-stars glyph + arcana label.
    case theMoon
}

// MARK: - CeremonialCardFace

/// A purely vector tarot card face at the forced 95 × 155 pt ratio (#010726 fill rule).
/// Suitable for the Login screen before any auth / image assets are available.
public struct CeremonialCardFace: View {
    @Environment(\.designTokens) private var tokens

    public let kind: CeremonialFaceKind

    public init(kind: CeremonialFaceKind) {
        self.kind = kind
    }

    // Forced card dimensions per product hard constraint (95/155).
    private let cardW: CGFloat = 95
    private let cardH: CGFloat = 155

    public var body: some View {
        ZStack {
            cardBackground
            glyphLayer
            if kind != .back { arcanaLabel }
            if kind == .back { cornerSparkles }
            hairlineBorder
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Background

    /// Radial gradient: aurora-tinted bright inner → bgLayer2 mid → bg outer.
    /// Each face kind uses a distinct aurora hue for its inner glow.
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        innerGlowColor.opacity(0.35),
                        tokens.palette.bgLayer2,
                        tokens.palette.bg
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: cardH * 0.70
                )
            )
    }

    /// Aurora inner-glow color per card kind.
    private var innerGlowColor: Color {
        switch kind {
        case .back:    return tokens.palette.auroraViolet
        case .theStar: return tokens.palette.auroraCyan
        case .theMoon: return tokens.palette.auroraViolet
        }
    }

    // MARK: - Glyph

    /// Central glyph at ~50% card width (≈46 pt font), aurora-tinted with outer glow.
    private var glyphLayer: some View {
        Image(systemName: glyphSystemName)
            .font(.system(size: 46))
            .foregroundStyle(glyphGradient)
            .shadow(color: glyphGlowColor.opacity(0.70), radius: 12, x: 0, y: 0)
            .opacity(0.95)
    }

    private var glyphSystemName: String {
        switch kind {
        case .back:    return "moon.stars.fill"
        case .theStar: return "star.fill"
        case .theMoon: return "moon.fill"
        }
    }

    /// Silver → aurora gradient per face kind.
    private var glyphGradient: LinearGradient {
        switch kind {
        case .back:
            return LinearGradient(
                colors: [tokens.palette.accentSilver, tokens.palette.auroraViolet],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .theStar:
            return LinearGradient(
                colors: [tokens.palette.accentBright, tokens.palette.auroraCyan],
                startPoint: .top, endPoint: .bottom
            )
        case .theMoon:
            return LinearGradient(
                colors: [tokens.palette.accentSilver, tokens.palette.auroraViolet],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var glyphGlowColor: Color {
        switch kind {
        case .back:    return tokens.palette.auroraViolet
        case .theStar: return tokens.palette.auroraCyan
        case .theMoon: return tokens.palette.auroraViolet
        }
    }

    // MARK: - Arcana label

    /// Cinzel small-caps label at bottom — accentBright, slightly larger (8pt).
    private var arcanaLabel: some View {
        VStack {
            Spacer()
            Text(arcanaLabelText)
                .font(.custom("Cinzel-Regular", size: 8, relativeTo: .caption2))
                .foregroundStyle(tokens.palette.accentBright)
                .tracking(1.4)
                .padding(.bottom, 8)
        }
    }

    private var arcanaLabelText: String {
        switch kind {
        case .theStar: return "XVII · THE STAR"
        case .theMoon: return "XVIII · THE MOON"
        case .back:    return ""
        }
    }

    // MARK: - Corner sparkles (back card)

    /// Four corner sparkles — accentSilver with slight aurora glow.
    private var cornerSparkles: some View {
        GeometryReader { geo in
            let inset: CGFloat = 8
            Group {
                sparkle.position(x: inset, y: inset)
                sparkle.position(x: geo.size.width - inset, y: inset)
                sparkle.position(x: inset, y: geo.size.height - inset)
                sparkle.position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
        }
    }

    private var sparkle: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 9))
            .foregroundStyle(tokens.palette.accentSilver.opacity(0.70))
            .shadow(color: tokens.palette.auroraViolet.opacity(0.50), radius: 4, x: 0, y: 0)
    }

    // MARK: - Hairline border

    /// 1 pt aurora-tinted hairline (not just plain silver).
    private var hairlineBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        glyphGlowColor.opacity(0.55),
                        tokens.palette.accentSilver.opacity(0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
