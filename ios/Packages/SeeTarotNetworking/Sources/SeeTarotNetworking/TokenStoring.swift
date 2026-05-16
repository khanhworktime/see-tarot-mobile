import Foundation

/// Abstraction over session-token storage. Networking depends on this, not on
/// Keychain — the Keychain impl lives in SeeTarotPersistence (Phase 04),
/// keeping module layering clean (decision 0004).
public protocol TokenStoring: AnyObject, Sendable {
    var token: String? { get }
    func setToken(_ token: String?)
}

/// In-memory store for tests and previews.
public final class InMemoryTokenStore: TokenStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    public init(token: String? = nil) { self.value = token }

    public var token: String? {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    public func setToken(_ token: String?) {
        lock.lock(); defer { lock.unlock() }
        value = token
    }
}
