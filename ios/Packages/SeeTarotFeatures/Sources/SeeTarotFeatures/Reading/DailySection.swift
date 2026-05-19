import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotDesignSystem

/// Daily 1-card energy section on Home. Loads on appear.
/// Phase 08: Cosmic Mysticism re-skin — glass panel, palette states, error/blocked/empty.
/// Store logic and card display untouched.
public struct DailySection: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: DailyReadingStore
    /// Cache-first loader from the app-level `CardImageLoader`. Nil → placeholder.
    private let loader: CardImageLoaderClosure?

    public init(store: DailyReadingStore, loader: CardImageLoaderClosure? = nil) {
        self._store = State(initialValue: store)
        self.loader = loader
    }

    public var body: some View {
        VStack(spacing: tokens.spacing.md) {
            sectionHeader
            switch store.state {
            case .idle, .loading:
                LoadingView("Drawing your card…")
                    .frame(maxWidth: .infinity)
                    .padding(tokens.spacing.md)
            case .loaded(let reading):
                loadedContent(reading)
            case .blocked:
                blockedState
            case .failed(let retryable):
                failedState(retryable: retryable)
            }
        }
        .task { if case .idle = store.state { await store.load() } }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: tokens.spacing.sm) {
            Image(systemName: "sun.horizon")
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("Today's Energy")
                .font(tokens.typography.heading)
                .foregroundStyle(tokens.palette.accentBright)
            Spacer()
        }
    }

    // MARK: - Loaded

    @ViewBuilder
    private func loadedContent(_ reading: Reading) -> some View {
        // Bind to the @Sendable typealias before capture to suppress the
        // "converting non-Sendable function value" diagnostic.
        let sendableLoader: CardImageLoaderClosure? = loader
        if let card = reading.cards.first {
            RealCardSurface(name: card.name, reversed: card.reversed,
                            loader: sendableLoader)
                .cardView(imageURL: card.imageUrl.flatMap(URL.init),
                          faceUp: true, position: 0)
                .frame(maxWidth: .infinity)
        }
        GlassSurface {
            Text(reading.interpretation)
                .font(tokens.typography.body)
                .foregroundStyle(tokens.palette.accentBright)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .glassPanel()
    }

    // MARK: - Blocked (403 daily_already_drawn)

    private var blockedState: some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.sm) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 32))
                    .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                    .accessibilityHidden(true)
                ScrimText("Your card has been drawn today.", style: .body)
                ScrimText("Come back tomorrow for a new reading.", style: .caption)
            }
        }
        .glassCard()
    }

    // MARK: - Failed (502 ai_failed / network)

    private func failedState(retryable: Bool) -> some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.md) {
                Image(systemName: "cloud.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                    .accessibilityHidden(true)
                ScrimText("Couldn't draw today's card.", style: .body)
                if retryable {
                    PrimaryButton("Retry") {
                        Task { await store.load() }
                    }
                }
            }
        }
        .glassCard()
    }
}
