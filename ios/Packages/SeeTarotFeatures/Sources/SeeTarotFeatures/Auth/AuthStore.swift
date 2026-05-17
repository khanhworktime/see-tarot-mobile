import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

private struct OnboardResponse: Decodable, Sendable { let ok: Bool }

/// Observable auth coordinator. Drives `AuthState` via the API client; the
/// Keychain token is managed by `LiveAPIClient`'s `TokenStoring`. Hard gate:
/// Auth (decision 0005). Email/password is the E01 end-to-end path; Google is
/// a seam only.
@MainActor
@Observable
public final class AuthStore {
    public private(set) var state: AuthState = .loading
    public private(set) var googleAvailable = false

    private let client: APIClientProtocol
    private let tokenStore: TokenStoring
    private let encoder: JSONEncoder

    /// Read-only access for authenticated feature stores (Daily/Oracle/quota).
    public var apiClient: APIClientProtocol { client }

    public init(client: APIClientProtocol, tokenStore: TokenStoring,
                encoder: JSONEncoder = .api) {
        self.client = client
        self.tokenStore = tokenStore
        self.encoder = encoder
    }

    /// Launch bootstrap: token present → hydrate session → route by
    /// `onboardedAt`; otherwise signed out.
    public func bootstrap() async {
        await loadProviders()
        guard let token = tokenStore.token, !token.isEmpty else {
            state = .signedOut(message: nil); return
        }
        do {
            if let user = try await client.getSession() {
                state = route(user)
            } else {
                tokenStore.setToken(nil)
                state = .signedOut(message: nil)
            }
        } catch {
            state = .signedOut(message: nil)
        }
    }

    public func signIn(email: String, password: String) async {
        await authenticate { try await self.client.signInEmail(email: email,
                                                               password: password) }
    }

    public func signUp(name: String, email: String, password: String) async {
        await authenticate { try await self.client.signUpEmail(name: name,
                                                               email: email,
                                                               password: password) }
    }

    private func authenticate(_ op: @Sendable () async throws -> SessionUser) async {
        state = .authenticating
        do {
            state = route(try await op())
        } catch APIError.unauthorized {
            state = .signedOut(message: "Invalid email or password.")
        } catch {
            state = .signedOut(message: "Sign-in failed. Please try again.")
        }
    }

    /// Onboarding seam (real form is E04): `POST /profile/onboard`.
    public func completeOnboarding(birthDate: String, name: String?) async {
        var body: [String: String] = ["birthDate": birthDate]
        if let name { body["name"] = name }
        do {
            let endpoint = Endpoint(path: "profile/onboard", method: .POST,
                                    body: try encoder.encode(body))
            _ = try await client.send(endpoint, as: OnboardResponse.self)
            if let user = try await client.getSession() { state = route(user) }
        } catch {
            // stay on onboarding; surface a retry in the view layer later
        }
    }

    public func signOut() async {
        try? await client.signOut()
        tokenStore.setToken(nil)
        state = .signedOut(message: nil)
    }

    /// Called by the networking 401 hook (wired in app DI).
    public func handleUnauthorized() {
        tokenStore.setToken(nil)
        state = .signedOut(message: "Your session expired. Please sign in.")
    }

    private func loadProviders() async {
        googleAvailable = (try? await client.authProviders())?.google ?? false
    }

    private func route(_ user: SessionUser) -> AuthState {
        user.needsOnboarding ? .needsOnboarding(user) : .authenticated(user)
    }
}
