import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Authenticated home: quota chip, today's energy card, entry to Oracle.
public struct HomeView: View {
    @Environment(\.designTokens) private var tokens
    private let client: APIClientProtocol
    private let user: SessionUser
    private let onSignOut: () -> Void
    @State private var daily: DailyReadingStore
    @State private var quota: Quota?
    @State private var path: [HomeRoute] = []

    public init(client: APIClientProtocol, user: SessionUser,
                onSignOut: @escaping () -> Void) {
        self.client = client
        self.user = user
        self.onSignOut = onSignOut
        self._daily = State(initialValue: DailyReadingStore(client: client))
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
}
