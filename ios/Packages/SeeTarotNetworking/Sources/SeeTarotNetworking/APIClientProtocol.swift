import Foundation
import SeeTarotCore

/// `GET /auth-providers` response (BE doc §3.1) — hide Google if false.
public struct AuthProviders: Codable, Equatable, Sendable {
    public let google: Bool
    public init(google: Bool) { self.google = google }
}

/// The single seam every feature depends on. Real (`LiveAPIClient`) and
/// deterministic (`StubAPIClient`) implementations exist; features never touch
/// a concrete client (decision 0004 / api-conventions).
public protocol APIClientProtocol: Sendable {
    // Auth (E01 surface)
    func authProviders() async throws -> AuthProviders
    func signUpEmail(name: String, email: String, password: String) async throws -> SessionUser
    func signInEmail(email: String, password: String) async throws -> SessionUser
    func getSession() async throws -> SessionUser?
    func signOut() async throws

    // Generic primitives (consumed by later epics)
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
    func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<SSEEvent, Error>
}
