import SwiftUI
import SeeTarotDesignSystem

/// Production `CardSurface` — the flip card (decision 0004).
///
/// Layout: `VStack { FlipCardView [95×155] ; name label }`.
/// The name label lives OUTSIDE the flip frame so it never overlaps artwork
/// and is visible face-down. Reversed cards show "(Reversed)" appended and
/// the artwork is rotated 180° inside the flip view.
///
/// On non-UIKit hosts (unit-test target) it degrades to a simple colored
/// rectangle so the seam still compiles; flip logic is tested via
/// `FlipDecision`.
///
/// **Backward-compatible**: `loader` and `imageURL`-derived `backURL` are
/// defaulted to `nil` so existing callers (`CardImage.swift`) still compile
/// without modification. Phase 08 threads the real loader through.
public struct RealCardSurface: CardSurface {
    let name: String
    let reversed: Bool
    /// Cache-first loader closure. `nil` → placeholder only (no back fetch).
    let loader: CardImageLoaderClosure?

    /// - Parameters:
    ///   - name: Card display name shown below the flip frame.
    ///   - reversed: When `true` artwork is rotated 180° and label shows
    ///     "(Reversed)".
    ///   - loader: Optional cache-first loader matching
    ///     `CardImageLoader.image(cardId:url:)`. Pass `nil` to keep the
    ///     existing placeholder behaviour (CardImage.swift callsite unchanged).
    public init(
        name: String = "",
        reversed: Bool = false,
        loader: CardImageLoaderClosure? = nil
    ) {
        self.name = name
        self.reversed = reversed
        self.loader = loader
    }

    public func cardView(imageURL: URL?, faceUp: Bool,
                         position: Int) -> some View {
        #if canImport(UIKit)
        RealCardSurfaceUIView(
            imageURL: imageURL,
            faceUp: faceUp,
            position: position,
            name: name,
            reversed: reversed,
            loader: loader
        )
        #else
        // Non-UIKit degraded branch (test host / macOS CLI)
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 1/255, green: 7/255, blue: 38/255))
            .frame(width: 95, height: 155)
            .accessibilityLabel("Card slot \(position)")
        #endif
    }
}

// MARK: - UIKit branch helper view

#if canImport(UIKit)
/// Encapsulates the `VStack { flipCard + label }` so the glow-burst state
/// and flip-style tracking are isolated in one SwiftUI view.
private struct RealCardSurfaceUIView: View {
    @Environment(\.designTokens) private var tokens

    let imageURL: URL?
    let faceUp: Bool
    let position: Int
    let name: String
    let reversed: Bool
    let loader: CardImageLoaderClosure?

    /// Tracks the last computed flip style so the glow burst only fires on
    /// `.threeDFlip` transitions.
    @State private var currentFlipStyle: FlipStyle = .none
    /// Toggles on each flip — used as the glow-burst trigger.
    @State private var glowTrigger: Bool = false
    @State private var wasFaceUp: Bool = false

    private let cardWidth: CGFloat  = 95
    private let cardHeight: CGFloat = 155
    private let flipDuration: Double = 0.35

    var body: some View {
        let backURL = CardBackURL.derive(from: imageURL)

        VStack(spacing: tokens.spacing.xs) {
            FlipCardView(
                imageURL: imageURL,
                faceUp: faceUp,
                name: name,
                reversed: reversed,
                duration: flipDuration,
                backURL: backURL,
                loader: loader
            )
            .frame(width: cardWidth, height: cardHeight)
            .glowBurst(
                color: tokens.palette.accentBright,
                trigger: glowTrigger,
                flipStyle: currentFlipStyle,
                flipDuration: flipDuration
            )
            .accessibilityLabel(
                "Card slot \(position), "
                + (faceUp ? "revealed \(labelText)" : "face down")
            )

            // Name label — always below the flip frame, never inside artwork
            Text(labelText)
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentSilver)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: cardWidth)
        }
        .onChange(of: faceUp) { oldValue, newValue in
            let reduceMotion = UIAccessibility.isReduceMotionEnabled
            let style = FlipDecision.style(wasFaceUp: oldValue,
                                           isFaceUp: newValue,
                                           reduceMotion: reduceMotion)
            currentFlipStyle = style
            if style == .threeDFlip {
                glowTrigger.toggle()
            }
            wasFaceUp = newValue
        }
    }

    private var labelText: String {
        reversed ? "\(name) (Reversed)" : name
    }
}
#endif
