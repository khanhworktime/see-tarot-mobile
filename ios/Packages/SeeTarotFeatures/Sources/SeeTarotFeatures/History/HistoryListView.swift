import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Reading history: cursor-paginated list, infinite scroll, pull-to-refresh.
/// Phase 08: Cosmic Mysticism re-skin — glass rows, palette, cosmic empty/error states.
/// All paging logic lives in HistoryStore — the view only triggers.
struct HistoryListView: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: HistoryStore
    let onOpen: (String) -> Void

    init(store: HistoryStore, onOpen: @escaping (String) -> Void) {
        self._store = State(initialValue: store)
        self.onOpen = onOpen
    }

    var body: some View {
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            Group {
                switch store.state {
                case .idle, .loading:
                    LoadingView("Loading your readings…")
                case .empty:
                    emptyState
                case .error:
                    errorState
                case .loaded, .paging, .end:
                    list
                }
            }
        }
        .navigationTitle("History")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
        .task { if case .idle = store.state { await store.loadFirst() } }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(store.rows) { row in
                Button { onOpen(row.id) } label: {
                    HistoryRowView(row: row)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppear {
                    if row.id == store.rows.last?.id {
                        Task { await store.loadMore() }
                    }
                }
            }
            if case .paging = store.state {
                HStack { Spacer(); ProgressView().tint(tokens.palette.accentSilver); Spacer() }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await store.loadFirst() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: tokens.spacing.lg) {
            Image(systemName: "moon.stars")
                .font(.system(size: 52))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                .accessibilityHidden(true)
            GlassSurface {
                VStack(spacing: tokens.spacing.sm) {
                    ScrimText("No Readings Yet", style: .heading)
                    ScrimText("Your past readings will appear here.", style: .body)
                }
            }
            .glassCard()
            .padding(.horizontal, tokens.spacing.md)
        }
    }

    // MARK: - Error state

    private var errorState: some View {
        VStack(spacing: tokens.spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.7))
                .accessibilityHidden(true)
            GlassSurface {
                VStack(spacing: tokens.spacing.md) {
                    ScrimText("Could not load history.", style: .body)
                    PrimaryButton("Retry") {
                        Task { await store.loadFirst() }
                    }
                }
            }
            .glassCard()
            .padding(.horizontal, tokens.spacing.md)
        }
    }
}
