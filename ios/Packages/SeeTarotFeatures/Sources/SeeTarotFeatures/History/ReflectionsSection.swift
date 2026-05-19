import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Reflections journal for a reading: newest-first list + add form.
/// Phase 08: Cosmic Mysticism re-skin — glass rows, palette. Logic untouched.
struct ReflectionsSection: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: ReflectionsStore

    init(store: ReflectionsStore) {
        self._store = State(initialValue: store)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: tokens.spacing.md) {
            sectionHeader

            switch store.state {
            case .idle, .loading:
                LoadingView("Loading reflections…")
                    .frame(maxWidth: .infinity)
            case .error:
                GlassSurface {
                    ScrimText("Could not load reflections.", style: .body)
                }
                .glassCard()
            case .loaded(let items):
                if items.isEmpty {
                    GlassSurface {
                        VStack(spacing: tokens.spacing.xs) {
                            Image(systemName: "pencil.and.sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(tokens.palette.accentSilver.opacity(0.6))
                                .accessibilityHidden(true)
                            ScrimText("No reflections yet.", style: .caption)
                        }
                    }
                    .glassCard()
                } else {
                    ForEach(items) { reflection in
                        reflectionRow(reflection)
                    }
                }
            }

            AddReflectionView(store: store)
        }
        .task { if case .idle = store.state { await store.load() } }
    }

    // MARK: - Components

    private var sectionHeader: some View {
        HStack(spacing: tokens.spacing.sm) {
            Image(systemName: "book.closed")
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("Reflections")
                .font(tokens.typography.heading)
                .foregroundStyle(tokens.palette.accentBright)
        }
    }

    private func reflectionRow(_ reflection: Reflection) -> some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.xs) {
                Text(reflection.body)
                    .font(tokens.typography.body)
                    .foregroundStyle(tokens.palette.accentBright)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: tokens.spacing.sm) {
                    if let mood = reflection.mood, !mood.isEmpty {
                        Label(mood, systemImage: "face.smiling")
                            .font(tokens.typography.caption)
                            .foregroundStyle(tokens.palette.accentSilver)
                            .labelStyle(.titleAndIcon)
                    }
                    Text(HistoryRowView.relativeDate(reflection.createdAt))
                        .font(tokens.typography.caption)
                        .foregroundStyle(tokens.palette.accentDim)
                }
            }
        }
        .glassCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
