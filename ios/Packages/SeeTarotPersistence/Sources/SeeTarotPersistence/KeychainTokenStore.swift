import Foundation
import SeeTarotNetworking

/// Keychain-backed `TokenStoring` — satisfies the Networking protocol so
/// `LiveAPIClient` persists the Better Auth session token securely.
public final class KeychainTokenStore: TokenStoring, @unchecked Sendable {
    public static let tokenKey = "see-tarot.session-token"

    private let keychain: KeychainAccessing
    private let key: String

    public init(keychain: KeychainAccessing = SystemKeychain(),
                key: String = KeychainTokenStore.tokenKey) {
        self.keychain = keychain
        self.key = key
    }

    public var token: String? { keychain.read(key) }

    public func setToken(_ token: String?) {
        if let token, !token.isEmpty {
            keychain.write(key, token)
        } else {
            keychain.delete(key)
        }
    }
}
