import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Reading history: cursor-paginated list, infinite scroll, pull-to-refresh.
/// All paging logic lives in `HistoryStore` (P01) — the view only triggers.
struct HistoryListView: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: HistoryStore
    let onOpen: (String) -> Void

    init(store: HistoryStore, onOpen: @escaping (String) -> Void) {
        self._store = State(initialValue: store)
        self.onOpen = onOpen
    }

    var body: some View {
        Group {
            switch store.state {
            case .idle, .loading:
                LoadingView("Loading your readings…")
            case .empty:
                ContentUnavailableView("No readings yet",
                                       systemImage: "moon.stars",
                                       description: Text(
                                        "Your past readings will appear here."))
            case .error:
                VStack(spacing: tokens.spacing.sm) {
                    Text("Could not load history.")
                    PrimaryButton("Retry") { Task { await store.loadFirst() } }
                }
            case .loaded, .paging, .end:
                list
            }
        }
        .navigationTitle("History")
        .task { if case .idle = store.state { await store.loadFirst() } }
    }

    private var list: some View {
        List {
            ForEach(store.rows) { row in
                Button { onOpen(row.id) } label: { HistoryRowView(row: row) }
                    .buttonStyle(.plain)
                    .onAppear {
                        if row.id == store.rows.last?.id {
                            Task { await store.loadMore() }
                        }
                    }
            }
            if case .paging = store.state {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
        .listStyle(.plain)
        .refreshable { await store.loadFirst() }
    }
}
