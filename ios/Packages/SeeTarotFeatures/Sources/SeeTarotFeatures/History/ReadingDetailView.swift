import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence
import SeeTarotDesignSystem

/// One past reading: interpretation + card art (offline-capable via
/// `CardImage`), owner visibility toggle, reflections journal. 404 ⇒ friendly.
struct ReadingDetailView: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: ReadingDetailStore
    private let readingId: String
    private let reflections: ReflectionsStore
    private let loader: CardImageLoader

    init(id: String, store: ReadingDetailStore,
         reflections: ReflectionsStore, loader: CardImageLoader) {
        self.readingId = id
        self._store = State(initialValue: store)
        self.reflections = reflections
        self.loader = loader
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: tokens.spacing.lg) {
                switch store.state {
                case .idle, .loading:
                    LoadingView("Loading reading…")
                case .notFound:
                    ContentUnavailableView("Reading not found",
                                           systemImage: "questionmark.circle",
                                           description: Text(
                                            "It may have been removed."))
                case .error:
                    Text("Could not load this reading.")
                        .foregroundStyle(.secondary)
                case .loaded(let reading):
                    loaded(reading)
                }
            }
            .padding(tokens.spacing.md)
        }
        .navigationTitle("Reading")
        .task { if case .idle = store.state {
            await store.load(id: readingId) } }
    }

    @ViewBuilder
    private func loaded(_ reading: Reading) -> some View {
        if !reading.cards.isEmpty {
            HStack(spacing: tokens.spacing.md) {
                ForEach(reading.cards) { card in
                    CardImage(card: card, loader: loader)
                        .frame(maxWidth: 140)
                }
            }
        }
        Text(reading.interpretation).font(tokens.typography.body)
        if reading.isOwner {
            VisibilityToggle(isPublic: reading.isPublic,
                             busy: store.togglingVisibility) {
                Task { await store.toggleVisibility() }
            }
            if let err = store.visibilityError {
                Text(err).font(tokens.typography.caption)
                    .foregroundStyle(.red)
            }
        }
        Divider()
        ReflectionsSection(store: reflections)
    }
}
