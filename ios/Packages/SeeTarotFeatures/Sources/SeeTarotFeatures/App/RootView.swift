import SwiftUI
import SeeTarotDesignSystem
import SeeTarotCardEngine

/// Routes by `AuthState`. Bootstraps the session on appear.
public struct RootView: View {
    @State private var auth: AuthStore

    public init(auth: AuthStore) { self._auth = State(initialValue: auth) }

    public var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView("Loading…")
            case .signedOut(let message):
                SignInView(auth: auth, message: message)
            case .authenticating:
                ProgressView("Signing in…")
            case .needsOnboarding(let user):
                OnboardingView(auth: auth, user: user)
            case .authenticated(let user):
                HomeView(client: auth.apiClient, user: user) {
                    Task { await auth.signOut() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AmbientBackgroundView())
        .environment(\.designTokens, .default)
        .task { if case .loading = auth.state { await auth.bootstrap() } }
    }
}
