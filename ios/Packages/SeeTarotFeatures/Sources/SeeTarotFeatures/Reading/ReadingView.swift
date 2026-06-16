import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotDesignSystem

/// Oracle reading playback: cards flip-reveal as `card` events arrive, then
/// the interpretation streams in as sequential glass-panel blocks.
///
/// Phase-05 wiring: `SpreadRitualView` is mounted for `.composing`/`.revealing`
/// states and replaced by the steady dealt-cards row once `.done`.
/// Phase-06: interpretation rendered as ordered magic-reveal blocks parsed from
/// `###` headings; pinned cards row supports tap → `CardDetailSheet`.
public struct ReadingView: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: OracleReadingStore
    @State private var selectedCard: ReadingCard?
    /// Set of block ids that have already animated in (stable identity guard).
    @State private var revealedBlockIDs: Set<String> = []

    let input: ReadingInput
    /// Cache-first image loader bridged from the app-level `CardImageLoader`.
    /// Threaded through to `SpreadRitualView` and the done-row `RealCardSurface`.
    let loader: CardImageLoaderClosure?

    public init(store: OracleReadingStore, input: ReadingInput,
                loader: CardImageLoaderClosure? = nil) {
        self._store = State(initialValue: store)
        self.input = input
        self.loader = loader
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: tokens.spacing.lg) {
                switch store.state {
                case .composing, .revealing:
                    // ── Phase-05 ritual host ─────────────────────────────────
                    ritualView(cards: currentCards)

                    // ── Phase 06: streaming block render ─────────────────────
                    if currentText.isEmpty {
                        LoadingView("Consulting the cards…")
                    } else {
                        interpretationBlockList(text: currentText)
                    }

                case .done(_, let cards, let text):
                    // ── Steady dealt-cards row with tap → detail ─────────────
                    ritualDoneCardsRow(cards)

                    // ── Phase 06: finalized block render ─────────────────────
                    interpretationBlockList(text: text)

                case .invalid(let msg):
                    invalidStateView(message: msg)

                case .blocked(let code):
                    blockedStateView(code: code)

                case .failed(let retryable):
                    failedStateView(retryable: retryable)
                }
            }
            .padding(tokens.spacing.md)
        }
        .navigationTitle("Your reading")
        .task { store.submit(input) }
        .onDisappear { store.stop() }   // store lifecycle untouched — Phase-05 constraint
        .sheet(item: $selectedCard) { card in
            CardDetailSheet(card: card)
        }
    }

    // MARK: - Phase-05: Ritual host

    /// Mounts `SpreadRitualView` for the active composing/revealing states.
    /// Converts `[ReadingCard]` → `[RitualCard]` at the boundary.
    ///
    /// Phase 06 entry point: card-detail gesture added at call site via overlay;
    /// this function body is NOT modified per Phase-05 constraint.
    private func ritualView(cards: [ReadingCard]) -> some View {
        SpreadRitualView(
            cards: ritualCards(from: cards),
            spread: spreadKind(for: cards.count),
            reduceMotion: reduceMotion,
            loader: loader
        )
        .frame(height: ritualContainerHeight)
        .accessibilityLabel(ritualAccessibilityLabel(cards: cards))
    }

    /// Steady HStack of dealt cards shown after ritual reaches `.done`.
    /// Each card is tappable → opens `CardDetailSheet`.
    private func ritualDoneCardsRow(_ cards: [ReadingCard]) -> some View {
        // Explicit @Sendable type annotation suppresses the Sendable conversion warning.
        let cardLoader: CardImageLoaderClosure? = loader
        return HStack(spacing: tokens.spacing.md) {
            ForEach(cards) { card in
                RealCardSurface(name: card.name, reversed: card.reversed,
                                loader: cardLoader)
                    .cardView(
                        imageURL: card.imageUrl.flatMap(URL.init),
                        faceUp: true,
                        position: card.position
                    )
                    .onTapGesture { selectedCard = card }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double-tap to view card details")
            }
        }
    }

    // MARK: - Phase 06: Interpretation block list

    /// Parses `text` into `InterpretationBlock` values and renders each in a
    /// `GlassSurface` panel with a fade+rise magic-reveal on first appearance.
    /// Reduced-motion: blocks appear instantly without the rise translation.
    @ViewBuilder
    private func interpretationBlockList(text: String) -> some View {
        let blocks = InterpretationBlocks.parse(text)
        VStack(spacing: tokens.spacing.md) {
            ForEach(blocks) { block in
                InterpretationBlockView(
                    block: block,
                    reduceMotion: reduceMotion,
                    isRevealed: revealedBlockIDs.contains(block.id)
                )
                .onAppear {
                    guard !revealedBlockIDs.contains(block.id) else { return }
                    let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.45)
                    _ = withAnimation(animation) {
                        revealedBlockIDs.insert(block.id)
                    }
                }
            }
        }
    }

    // MARK: - Re-skinned error states

    /// `.invalid` — validation error surfaced before any network call.
    private func invalidStateView(message: String) -> some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.sm) {
                ScrimText("Reading Unavailable", style: .heading)
                ScrimText(message, style: .body)
            }
        }
        .glassCard()
    }

    /// `.blocked` — entitlement / quota limit.
    private func blockedStateView(code: String) -> some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.sm) {
                ScrimText("Limit Reached", style: .heading)
                ScrimText(blockedMessage(code), style: .body)
            }
        }
        .glassCard()
    }

    /// `.failed` — network/server error with optional retry.
    private func failedStateView(retryable: Bool) -> some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.md) {
                ScrimText("The reading could not be completed.", style: .body)
                if retryable {
                    PrimaryButton("Try again") { store.submit(input) }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private var currentCards: [ReadingCard] {
        if case .revealing(let cards, _) = store.state { return cards }
        return []
    }

    private var currentText: String {
        if case .revealing(_, let text) = store.state { return text }
        return ""
    }

    private func ritualCards(from cards: [ReadingCard]) -> [RitualCard] {
        cards.map { card in
            RitualCard(
                id: card.position,
                name: card.name,
                imageURL: card.imageUrl.flatMap(URL.init),
                reversed: card.reversed
            )
        }
    }

    private func spreadKind(for count: Int) -> SpreadKind {
        switch count {
        case 3:  return .threeCard
        case 10: return .celtic
        default: return .oneCard
        }
    }

    private var ritualContainerHeight: CGFloat {
        SpreadLayout.cardHeight + 60
    }

    private func ritualAccessibilityLabel(cards: [ReadingCard]) -> String {
        if cards.isEmpty {
            return "Tarot deck. Press and hold to begin your reading."
        }
        let names = cards.map(\.name).joined(separator: ", ")
        return "Cards drawn: \(names). Press and hold the deck to deal."
    }

    private func blockedMessage(_ code: String) -> String {
        switch code {
        case "oracle_weekly_limit": return "You've reached this week's oracle limit."
        default: return "This reading isn't available right now."
        }
    }
}

// MARK: - InterpretationBlockView

/// Single glass-panel section with magic-reveal animation.
/// When `isRevealed` transitions `false → true`, the view fades in and rises
/// 20 pt (disabled when `reduceMotion` is true).
private struct InterpretationBlockView: View {
    @Environment(\.designTokens) private var tokens

    let block: InterpretationBlock
    let reduceMotion: Bool
    let isRevealed: Bool

    private let riseDistance: CGFloat = 20

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.sm) {
                if !block.title.isEmpty {
                    ScrimText(block.title, style: .heading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !block.body.isEmpty {
                    ScrimText(block.body, style: .body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .glassPanel()
        .opacity(isRevealed ? 1 : 0)
        .offset(y: (isRevealed || reduceMotion) ? 0 : riseDistance)
    }
}
