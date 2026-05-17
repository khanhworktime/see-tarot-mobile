import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotDesignSystem

/// Oracle reading playback: cards flip-reveal as `card` events arrive, then
/// the interpretation streams in. Cancels the stream on dismiss (aborts gen).
public struct ReadingView: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: OracleReadingStore
    let input: ReadingInput

    public init(store: OracleReadingStore, input: ReadingInput) {
        self._store = State(initialValue: store)
        self.input = input
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: tokens.spacing.lg) {
                switch store.state {
                case .composing, .revealing:
                    cards(currentCards)
                    if !currentText.isEmpty {
                        Text(currentText).font(tokens.typography.body)
                    } else {
                        LoadingView("Consulting the cards…")
                    }
                case .done(_, let cards, let text):
                    self.cards(cards)
                    Text(text).font(tokens.typography.body)
                case .invalid(let msg):
                    Text(msg).foregroundStyle(.red)
                case .blocked(let code):
                    Text(blockedMessage(code)).foregroundStyle(.secondary)
                case .failed(let retryable):
                    VStack(spacing: tokens.spacing.sm) {
                        Text("The reading could not be completed.")
                        if retryable {
                            PrimaryButton("Try again") { store.submit(input) }
                        }
                    }
                }
            }
            .padding(tokens.spacing.md)
        }
        .navigationTitle("Your reading")
        .task { store.submit(input) }
        .onDisappear { store.stop() }
    }

    private var currentCards: [ReadingCard] {
        if case .revealing(let c, _) = store.state { return c }
        return []
    }
    private var currentText: String {
        if case .revealing(_, let t) = store.state { return t }
        return ""
    }

    private func cards(_ list: [ReadingCard]) -> some View {
        HStack(spacing: tokens.spacing.md) {
            ForEach(list) { card in
                RealCardSurface(name: card.name, reversed: card.reversed)
                    .cardView(imageURL: card.imageUrl.flatMap(URL.init),
                              faceUp: true, position: card.position)
            }
        }
    }

    private func blockedMessage(_ code: String) -> String {
        switch code {
        case "oracle_weekly_limit": return "You've reached this week's oracle limit."
        default: return "This reading isn't available right now."
        }
    }
}
