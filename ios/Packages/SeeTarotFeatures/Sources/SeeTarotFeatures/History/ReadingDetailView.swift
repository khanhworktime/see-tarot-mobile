import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence
import SeeTarotDesignSystem

/// One past reading: interpretation + card art (offline-capable via CardImage),
/// owner visibility toggle, reflections journal. 404 → friendly glass state.
/// Phase 08: Cosmic Mysticism re-skin — glass panels, ornament at header only.
/// Store/navigation logic untouched.
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
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: tokens.spacing.lg) {
                    switch store.state {
                    case .idle, .loading:
                        LoadingView("Loading reading…")
                            .frame(maxWidth: .infinity)
                            .padding(.top, tokens.spacing.xl)
                    case .notFound:
                        notFoundState
                    case .error:
                        errorState
                    case .loaded(let reading):
                        loaded(reading)
                    }
                }
                .padding(tokens.spacing.md)
            }
        }
        .navigationTitle("Reading")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
        .task { if case .idle = store.state { await store.load(id: readingId) } }
    }

    // MARK: - Loaded content

    @ViewBuilder
    private func loaded(_ reading: Reading) -> some View {
        // Ceremonial header ornament — only at reading detail level
        if !reading.cards.isEmpty {
            cardHeader(reading.cards)
        }

        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.md) {
                interpretationHeader
                Text(reading.interpretation)
                    .font(tokens.typography.body)
                    .foregroundStyle(tokens.palette.accentBright)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .glassPanel()

        if reading.isOwner {
            VisibilityToggle(isPublic: reading.isPublic,
                             busy: store.togglingVisibility) {
                Task { await store.toggleVisibility() }
            }
            if let err = store.visibilityError {
                Text(err)
                    .font(tokens.typography.caption)
                    .foregroundStyle(tokens.palette.accentBright)
                    .padding(.horizontal, tokens.spacing.md)
            }
        }

        cosmicDivider

        ReflectionsSection(store: reflections)
    }

    // MARK: - Card header (ceremonial ornament)

    private func cardHeader(_ cards: [ReadingCard]) -> some View {
        VStack(spacing: tokens.spacing.md) {
            celestialOrnament
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: tokens.spacing.md) {
                    ForEach(cards) { card in
                        CardImage(card: card, loader: loader)
                            .frame(maxWidth: 140)
                    }
                }
                .padding(.horizontal, tokens.spacing.md)
            }
        }
    }

    private var celestialOrnament: some View {
        HStack(spacing: tokens.spacing.sm) {
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.3))
                .frame(height: 1)
            Image(systemName: "moon.stars")
                .font(.system(size: 16))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                .accessibilityHidden(true)
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, tokens.spacing.md)
    }

    private var interpretationHeader: some View {
        HStack(spacing: tokens.spacing.sm) {
            Image(systemName: "text.quote")
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("Interpretation")
                .font(tokens.typography.heading)
                .foregroundStyle(tokens.palette.accentBright)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cosmicDivider: some View {
        HStack(spacing: tokens.spacing.sm) {
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.2))
                .frame(height: 1)
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.5))
                .accessibilityHidden(true)
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.2))
                .frame(height: 1)
        }
    }

    // MARK: - Error / not-found states

    private var notFoundState: some View {
        VStack(spacing: tokens.spacing.lg) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                .accessibilityHidden(true)
            GlassSurface {
                VStack(spacing: tokens.spacing.sm) {
                    ScrimText("Reading Not Found", style: .heading)
                    ScrimText("It may have been removed.", style: .body)
                }
            }
            .glassCard()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, tokens.spacing.xl)
    }

    private var errorState: some View {
        VStack(spacing: tokens.spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                .accessibilityHidden(true)
            GlassSurface {
                VStack(spacing: tokens.spacing.md) {
                    ScrimText("Could not load this reading.", style: .body)
                    PrimaryButton("Retry") {
                        Task { await store.load(id: readingId) }
                    }
                }
            }
            .glassCard()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, tokens.spacing.xl)
    }
}
