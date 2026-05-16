import Foundation
import SeeTarotNetworking
import SeeTarotPersistence

/// Composition root: wires Keychain token store + Live API client + AuthStore,
/// resolving the client↔store 401 cycle via a small handler box.
public enum AppComposition {
    private final class UnauthorizedBox: @unchecked Sendable {
        var handler: @Sendable () -> Void = {}
        func fire() { handler() }
    }

    @MainActor
    public static func makeAuthStore(baseURL: URL) -> AuthStore {
        let tokenStore = KeychainTokenStore()
        let box = UnauthorizedBox()
        let client = LiveAPIClient(
            baseURL: baseURL, tokenStore: tokenStore,
            onUnauthorized: { box.fire() })
        let store = AuthStore(client: client, tokenStore: tokenStore)
        box.handler = { Task { @MainActor in store.handleUnauthorized() } }
        return store
    }
}
