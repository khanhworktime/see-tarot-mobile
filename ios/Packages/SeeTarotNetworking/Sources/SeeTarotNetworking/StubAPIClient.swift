import Foundation
import SeeTarotCore

/// Deterministic in-memory client for unit tests and SwiftUI previews.
/// Behaviour is fully configurable via the closures.
public final class StubAPIClient: APIClientProtocol, @unchecked Sendable {
    public var providers = AuthProviders(google: false)
    public var sessionUser: SessionUser?
    public var authError: Error?
    public var sseScript: [SSEEvent] = []
    public private(set) var signedOut = false
    // Reading fixtures (E02)
    public var dailyTodayResult: Reading?
    public var drawDailyResult: Result<Reading, Error>?
    public var quotaResult: Quota = Quota(tier: "plus", dailyRemaining: 1,
                                          oracleRemaining: nil)
    /// Optional responder for generic `send` (e.g. onboarding). Returns the
    /// JSON body to decode for a given endpoint.
    public var sendResponder: (@Sendable (Endpoint) throws -> Data)?

    public init(sessionUser: SessionUser? = nil) {
        self.sessionUser = sessionUser
    }

    public func authProviders() async throws -> AuthProviders { providers }

    public func signUpEmail(name: String, email: String,
                            password: String) async throws -> SessionUser {
        try await authed()
    }

    public func signInEmail(email: String,
                            password: String) async throws -> SessionUser {
        try await authed()
    }

    private func authed() async throws -> SessionUser {
        if let authError { throw authError }
        guard let user = sessionUser else { throw APIError.badResponse }
        return user
    }

    public func getSession() async throws -> SessionUser? { sessionUser }

    public func signOut() async throws {
        signedOut = true
        sessionUser = nil
    }

    public func dailyToday() async throws -> Reading? { dailyTodayResult }

    public func drawDaily(tz: String) async throws -> Reading {
        switch drawDailyResult {
        case .success(let r): return r
        case .failure(let e): throw e
        case nil: throw APIError.badResponse
        }
    }

    public func quota() async throws -> Quota { quotaResult }

    public func generate(_ input: ReadingInput)
        -> AsyncThrowingStream<SSEEvent, Error> {
        stream(Endpoint(path: "readings/generate", method: .POST))
    }

    public func send<T: Decodable & Sendable>(_ endpoint: Endpoint,
                                              as type: T.Type) async throws -> T {
        guard let responder = sendResponder else {
            throw APIError.transport("StubAPIClient.send unconfigured for \(endpoint.path)")
        }
        return try JSONDecoder.api.decode(T.self, from: try responder(endpoint))
    }

    public func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<SSEEvent, Error> {
        let script = sseScript
        return AsyncThrowingStream { continuation in
            for event in script {
                continuation.yield(event)
                if event.name == "done" || event.name == "error" { break }
            }
            continuation.finish()
        }
    }
}
