import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence
import SeeTarotDesignSystem
import SeeTarotCardEngine

// MARK: - Tab model

private enum AppTab: Int, CaseIterable {
    case today, oracle, history, profile

    var label: String {
        switch self {
        case .today:   return "Today"
        case .oracle:  return "Oracle"
        case .history: return "History"
        case .profile: return "Profile"
        }
    }

    // SF Symbols — single family, consistent stroke weight, vector
    var symbol: String {
        switch self {
        case .today:   return "moon.stars.fill"
        case .oracle:  return "sparkles"
        case .history: return "books.vertical.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - MainTabView

/// Authenticated shell: 4-tab glass bottom bar over the continuous ambient bg.
/// Each tab owns its own `NavigationStack` so scroll/path state persists
/// across tab switches. Sign-out lives in the Profile tab.
///
/// Public surface: `init(client:user:auth:onSignOut:)` — matches the shape
/// previously expected of `HomeView`, so `RootView` can drop-in replace.
public struct MainTabView: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let client: APIClientProtocol
    private let user: SessionUser
    private let auth: AuthStore
    private let onSignOut: () -> Void

    // Per-tab navigation paths — preserved across tab switches
    @State private var todayPath: [HomeRoute] = []
    @State private var oraclePath: [HomeRoute] = []
    @State private var historyPath: [HomeRoute] = []
    @State private var profilePath: [HomeRoute] = []

    @State private var selectedTab: AppTab = .today

    // Shared stores — allocated once, kept alive for the session
    @State private var daily: DailyReadingStore
    @State private var quota: Quota?
    private let imageLoader: CardImageLoader

    public init(client: APIClientProtocol, user: SessionUser,
                auth: AuthStore, onSignOut: @escaping () -> Void) {
        self.client = client
        self.user = user
        self.auth = auth
        self.onSignOut = onSignOut
        self._daily = State(initialValue: DailyReadingStore(client: client))
        self.imageLoader = PersistenceContainer.makeArtworkLoader()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlassTabBar(
                tabs: AppTab.allCases,
                selected: $selectedTab,
                reduceMotion: reduceMotion
            )
        }
        // Reserve space below content so the last row clears the custom bar
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: GlassTabBar.barHeight)
        }
        .task { quota = try? await client.quota() }
    }

    // MARK: Tab content router

    @ViewBuilder
    private var tabContent: some View {
        // All stacks remain in the view tree (opacity switch) so per-tab
        // scroll position and navigation path are never discarded.
        Group {
            todayStack
                .opacity(selectedTab == .today ? 1 : 0)
                .allowsHitTesting(selectedTab == .today)
            oracleStack
                .opacity(selectedTab == .oracle ? 1 : 0)
                .allowsHitTesting(selectedTab == .oracle)
            historyStack
                .opacity(selectedTab == .history ? 1 : 0)
                .allowsHitTesting(selectedTab == .history)
            profileStack
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)
        }
        .animation(reduceMotion ? nil : tokens.motion.quick, value: selectedTab)
    }

    // MARK: Today tab

    private var todayStack: some View {
        let dailyLoader: CardImageLoaderClosure = { id, url in
            await imageLoader.image(cardId: id, url: url)
        }
        return NavigationStack(path: $todayPath) {
            TodayTabContent(
                daily: daily,
                quota: quota,
                loader: dailyLoader,
                onAskOracle: { selectedTab = .oracle }
            )
            .navigationTitle("Today")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
            .navigationDestination(for: HomeRoute.self, destination: destinationFor)
        }
    }

    // MARK: Oracle tab

    private var oracleStack: some View {
        NavigationStack(path: $oraclePath) {
            OracleFormView { input in oraclePath.append(.reading(input)) }
#if os(iOS)
                .toolbarBackground(.hidden, for: .navigationBar)
#endif
                .navigationDestination(for: HomeRoute.self, destination: destinationFor)
        }
    }

    // MARK: History tab

    private var historyStack: some View {
        NavigationStack(path: $historyPath) {
            HistoryListView(store: HistoryStore(client: client)) { id in
                historyPath.append(.readingDetail(id))
            }
#if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
            .navigationDestination(for: HomeRoute.self, destination: destinationFor)
        }
    }

    // MARK: Profile tab

    private var profileStack: some View {
        NavigationStack(path: $profilePath) {
            ProfileTabContent(
                store: ProfileStore(auth: auth, user: user),
                onSignOut: onSignOut
            )
            .navigationTitle("Profile")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
            .navigationDestination(for: HomeRoute.self, destination: destinationFor)
        }
    }

    // MARK: Shared destination switch (HomeRoute graph unchanged)

    @ViewBuilder
    private func destinationFor(_ route: HomeRoute) -> some View {
        switch route {
        case .oracleForm:
            OracleFormView { input in oraclePath.append(.reading(input)) }
        case .reading(let input):
            let loaderClosure: CardImageLoaderClosure = { id, url in
                await imageLoader.image(cardId: id, url: url)
            }
            ReadingView(store: OracleReadingStore(client: client), input: input,
                        loader: loaderClosure)
        case .history:
            HistoryListView(store: HistoryStore(client: client)) { id in
                historyPath.append(.readingDetail(id))
            }
        case .readingDetail(let id):
            ReadingDetailView(
                id: id,
                store: ReadingDetailStore(client: client),
                reflections: ReflectionsStore(client: client, readingId: id),
                loader: imageLoader
            )
        case .profile:
            ProfileTabContent(
                store: ProfileStore(auth: auth, user: user),
                onSignOut: onSignOut
            )
        }
    }
}

// MARK: - TodayTabContent

/// Today tab: Daily card as hero anchor + quota chip + Oracle CTA.
private struct TodayTabContent: View {
    @Environment(\.designTokens) private var tokens

    let daily: DailyReadingStore
    let quota: Quota?
    let loader: CardImageLoaderClosure?
    let onAskOracle: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: tokens.spacing.lg) {
                if let quota {
                    QuotaChip(quota: quota)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // Hero daily section — the large center anchor
                DailySection(store: daily, loader: loader)
                    .padding(.horizontal, tokens.spacing.md)

                // Direct Oracle CTA — prominent per Phase 07 resolved decision
                PrimaryButton("Ask the Oracle", action: onAskOracle)
                    .padding(.horizontal, tokens.spacing.md)
            }
            .padding(.top, tokens.spacing.md)
            .padding(.bottom, tokens.spacing.xl)
        }
    }
}

// MARK: - ProfileTabContent

/// Profile tab: profile editor + sign-out relocated from HomeView.
private struct ProfileTabContent: View {
    @Environment(\.designTokens) private var tokens

    let store: ProfileStore
    let onSignOut: () -> Void

    var body: some View {
        ProfileView(store: store)
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    signOutButton
                }
#else
                ToolbarItem(placement: .automatic) {
                    signOutButton
                }
#endif
            }
    }

    private var signOutButton: some View {
        Button("Sign out", role: .destructive, action: onSignOut)
            .font(tokens.typography.caption)
    }
}

// MARK: - GlassTabBar

private struct GlassTabBar: View {
    @Environment(\.designTokens) private var tokens

    let tabs: [AppTab]
    @Binding var selected: AppTab
    let reduceMotion: Bool

    static let barHeight: CGFloat = 56

    var body: some View {
        GlassSurface {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.rawValue) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selected == tab,
                        reduceMotion: reduceMotion
                    ) {
                        selected = tab
                    }
                }
            }
        }
        .glassCard()
        .frame(height: Self.barHeight)
        .padding(.horizontal, tokens.spacing.md)
        .padding(.bottom, tokens.spacing.sm)
    }
}

// MARK: - TabBarButton

private struct TabBarButton: View {
    @Environment(\.designTokens) private var tokens

    let tab: AppTab
    let isSelected: Bool
    let reduceMotion: Bool
    let action: () -> Void

    // ≥44pt tap target per HIG
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.label)
                    .font(tokens.typography.caption)
            }
            .foregroundStyle(
                isSelected ? tokens.palette.accentBright : tokens.palette.accentDim
            )
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .animation(
                reduceMotion ? nil : tokens.motion.quick,
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
