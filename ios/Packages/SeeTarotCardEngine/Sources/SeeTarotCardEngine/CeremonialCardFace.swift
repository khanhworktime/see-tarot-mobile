// CeremonialCardFace.swift — CardEngine / Phase 10 (Real Card Art)
//
// Renders a tarot card face at the forced 95/155 ratio using bundled card art.
//   .back        → brand-logo.png centered on cosmic gradient + aurora glow
//   .face(card)  → real SVG art stretched to fill, arcana label below
//
// The 95×155 frame is a hard product constraint; aspect ratio is ~0.613 which
// closely matches the SVG portraits — mild distortion is accepted by design.
//
// Token access: via `\.designTokens` environment injection (no singletons).

import SwiftUI
import SeeTarotDesignSystem

// MARK: - Kind

/// Which ceremonial face variant to render.
public enum CeremonialFaceKind: Sendable, Hashable {
    /// Brand back-of-card: cosmic gradient + brand-logo PNG centered.
    case back
    /// A bundled SVG card face overlaid on the aurora gradient background.
    case face(BundledCard)
}

// MARK: - CeremonialCardFace

/// A tarot card face at the forced 95 × 155 pt ratio.
/// Suitable for the Login screen before any auth / image assets are available.
public struct CeremonialCardFace: View {
    @Environment(\.designTokens) private var tokens

    public let kind: CeremonialFaceKind

    public init(kind: CeremonialFaceKind) {
        self.kind = kind
    }

    private let cardW: CGFloat = 95
    private let cardH: CGFloat = 155

    public var body: some View {
        ZStack {
            cardBackground
            artworkLayer
            if case .face(let card) = kind {
                arcanaLabel(card: card)
            }
            hairlineBorder
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Background

    /// Radial gradient: aurora-tinted inner → bgLayer2 → bg outer.
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

    private var innerGlowColor: Color {
        switch kind {
        case .back:              return tokens.palette.auroraViolet
        case .face(let card):   return auroraColor(for: card)
        }
    }

    private func auroraColor(for card: BundledCard) -> Color {
        switch card {
        case .theStar:     return tokens.palette.auroraCyan
        case .theMoon:     return tokens.palette.auroraViolet
        case .theSun:      return tokens.palette.auroraPink
        case .theFool:     return tokens.palette.auroraCyan
        case .theMagician: return tokens.palette.auroraViolet
        }
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkLayer: some View {
        switch kind {
        case .back:
            // Brand logo: PNG centered at ~70% card width with aurora glow.
            CardArt.brandLogoBack
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: cardW * 0.70, height: cardH * 0.70)
                .shadow(color: tokens.palette.auroraViolet.opacity(0.65), radius: 10, x: 0, y: 0)

        case .face(let card):
            // Real SVG art stretched to fill the forced 95/155 frame.
            CardArt.image(for: card)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardW, height: cardH)
        }
    }

    // MARK: - Arcana label

    /// Cinzel small-caps label at bottom — accentBright.
    private func arcanaLabel(card: BundledCard) -> some View {
        VStack {
            Spacer()
            Text("\(card.arcanaNumeral) · \(card.displayName.uppercased())")
                .font(.custom("Cinzel-Regular", size: 8, relativeTo: .caption2))
                .foregroundStyle(tokens.palette.accentBright)
                .tracking(1.4)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Hairline border

    /// 1 pt aurora-tinted hairline border.
    private var hairlineBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        innerGlowColor.opacity(0.55),
                        tokens.palette.accentSilver.opacity(0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
