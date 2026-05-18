import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotPersistence
import SeeTarotDesignSystem

/// Authenticated home: quota chip, today's energy card, entry to Oracle.
public struct HomeView: View {
    @Environment(\.designTokens) private var tokens
    private let client: APIClientProtocol
    private let user: SessionUser
    private let auth: AuthStore
    private let onSignOut: () -> Void
    @State private var daily: DailyReadingStore
    @State private var quota: Quota?
    @State private var path: [HomeRoute] = []
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
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: tokens.spacing.lg) {
                    if let quota { QuotaChip(quota: quota) }
                    DailySection(store: daily)
                    PrimaryButton("Ask the Oracle") {
                        path.append(.oracleForm)
                    }
                    Button("Reading history") { path.append(.history) }
                        .font(tokens.typography.body)
                    Button("Profile") { path.append(.profile) }
                        .font(tokens.typography.body)
                    Button("Sign out", role: .destructive, action: onSignOut)
                        .font(tokens.typography.caption)
                }
                .padding(tokens.spacing.md)
            }
            .navigationTitle("See Tarot")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .oracleForm:
                    OracleFormView { input in path.append(.reading(input)) }
                case .reading(let input):
                    ReadingView(store: OracleReadingStore(client: client),
                                input: input)
                case .history:
                    HistoryListView(store: HistoryStore(client: client)) { id in
                        path.append(.readingDetail(id))
                    }
                case .readingDetail(let id):
                    ReadingDetailView(
                        id: id,
                        store: ReadingDetailStore(client: client),
                        reflections: ReflectionsStore(client: client,
                                                      readingId: id),
                        loader: imageLoader)
                case .profile:
                    ProfileView(store: ProfileStore(auth: auth, user: user))
                }
            }
            .task { quota = try? await client.quota() }
        }
    }
}

/// Navigation routes for the authenticated area.
enum HomeRoute: Hashable {
    case oracleForm
    case reading(ReadingInput)
    case history
    case readingDetail(String)
    case profile
}
