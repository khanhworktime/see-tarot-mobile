import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotDesignSystem

/// Daily 1-card energy section on Home. Loads on appear.
public struct DailySection: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: DailyReadingStore

    public init(store: DailyReadingStore) {
        self._store = State(initialValue: store)
    }

    public var body: some View {
        VStack(spacing: tokens.spacing.md) {
            Text("Today's energy").font(tokens.typography.heading)
            switch store.state {
            case .idle, .loading:
                LoadingView("Drawing your card…")
            case .loaded(let reading):
                if let card = reading.cards.first {
                    RealCardSurface(name: card.name, reversed: card.reversed)
                        .cardView(imageURL: card.imageUrl.flatMap(URL.init),
                                  faceUp: true, position: 0)
                }
                Text(reading.interpretation)
                    .font(tokens.typography.body)
                    .multilineTextAlignment(.center)
            case .blocked:
                Text("You've already drawn today. Come back tomorrow.")
                    .foregroundStyle(tokens.palette.textSecondary)
            case .failed(let retryable):
                VStack(spacing: tokens.spacing.sm) {
                    Text("Couldn't draw today's card.")
                    if retryable {
                        PrimaryButton("Retry") { Task { await store.load() } }
                    }
                }
            }
        }
        .task { if case .idle = store.state { await store.load() } }
    }
}
