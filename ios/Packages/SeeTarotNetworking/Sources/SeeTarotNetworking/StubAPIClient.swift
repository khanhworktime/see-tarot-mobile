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
    // History / reflections fixtures (E03). `historyPages` keyed by requested
    // cursor (`nil` ⇒ first page) so pagination is deterministic.
    public var historyPages: [String?: HistoryPage] = [:]
    public var historyError: Error?
    public var readingResult: Result<Reading, Error>?
    public var reflectionsResult: [Reflection] = []
    public var addReflectionResult: Result<String, Error> = .success("ref-1")
    public var visibilityResult: Bool?
    // Profile (E04). Default: echo dirty fields merged onto `sessionUser`.
    public var updateProfileResult: Result<SessionUser?, Error>?
    public private(set) var lastUpdateProfileArgs:
        (name: String?, birthDate: String?, timezone: String?,
         preferredIntent: String?)?

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

    public func history(cursor: String?,
                        limit: Int) async throws -> HistoryPage {
        if let historyError { throw historyError }
        return historyPages[cursor]
            ?? HistoryPage(items: [], nextCursor: nil)
    }

    public func reading(id: String) async throws -> Reading {
        switch readingResult {
        case .success(let r): return r
        case .failure(let e): throw e
        case nil: throw APIError.http(status: 404, envelope: nil)
        }
    }

    public func setVisibility(id: String,
                              isPublic: Bool) async throws -> Bool {
        visibilityResult ?? isPublic
    }

    public func addReflection(id: String, body: String,
                              mood: String?) async throws -> String {
        switch addReflectionResult {
        case .success(let rid): return rid
        case .failure(let e): throw e
        }
    }

    public func reflections(id: String) async throws -> [Reflection] {
        reflectionsResult
    }

    public func updateProfile(name: String?, birthDate: String?,
                              timezone: String?,
                              preferredIntent: String?) async throws -> SessionUser? {
        lastUpdateProfileArgs = (name, birthDate, timezone, preferredIntent)
        if let updateProfileResult {
            return try updateProfileResult.get()
        }
        guard let u = sessionUser else { return nil }
        // Default: merge dirty fields onto the current user.
        let merged = SessionUser(
            id: u.id, name: name ?? u.name, email: u.email, tier: u.tier,
            subscriptionStatus: u.subscriptionStatus,
            subscriptionRenewsAt: u.subscriptionRenewsAt,
            kofiEmail: u.kofiEmail, birthDate: birthDate ?? u.birthDate,
            timezone: timezone ?? u.timezone,
            preferredIntent: preferredIntent ?? u.preferredIntent,
            onboardedAt: u.onboardedAt)
        sessionUser = merged
        return merged
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
