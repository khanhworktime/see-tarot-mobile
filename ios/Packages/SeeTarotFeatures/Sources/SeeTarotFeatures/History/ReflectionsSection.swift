import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Reflections journal for a reading: newest-first list + add form.
/// Append-only (no edit/delete affordances).
struct ReflectionsSection: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: ReflectionsStore

    init(store: ReflectionsStore) {
        self._store = State(initialValue: store)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: tokens.spacing.md) {
            Text("Reflections").font(tokens.typography.heading)
            switch store.state {
            case .idle, .loading:
                LoadingView("Loading reflections…")
            case .error:
                Text("Could not load reflections.")
                    .foregroundStyle(.secondary)
            case .loaded(let items):
                if items.isEmpty {
                    Text("No reflections yet.")
                        .font(tokens.typography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { r in reflectionRow(r) }
                }
            }
            AddReflectionView(store: store)
        }
        .task { if case .idle = store.state { await store.load() } }
    }

    private func reflectionRow(_ r: Reflection) -> some View {
        VStack(alignment: .leading, spacing: tokens.spacing.xs) {
            Text(r.body).font(tokens.typography.body)
            HStack(spacing: tokens.spacing.sm) {
                if let mood = r.mood, !mood.isEmpty {
                    Text(mood).font(tokens.typography.caption)
                        .foregroundStyle(.secondary)
                }
                Text(HistoryRowView.relativeDate(r.createdAt))
                    .font(tokens.typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, tokens.spacing.xs)
    }
}
