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

    // Readings (E02 surface)
    /// `GET /readings/daily-today` — `nil` when `204` (not drawn today).
    func dailyToday() async throws -> Reading?
    /// `POST /readings/daily` — synchronous draw (once/day, never re-rolls).
    func drawDaily(tz: String) async throws -> Reading
    /// `GET /quota` — entitlement snapshot.
    func quota() async throws -> Quota
    /// `POST /readings/generate` — SSE stream (card → delta… → done|error).
    func generate(_ input: ReadingInput) -> AsyncThrowingStream<SSEEvent, Error>

    // History + reflections (E03 surface)
    /// `GET /readings?cursor&limit` — cursor-paginated history (newest-first).
    func history(cursor: String?, limit: Int) async throws -> HistoryPage
    /// `GET /readings/{id}` — full reading (public; bearer sent if present).
    func reading(id: String) async throws -> Reading
    /// `PATCH /readings/{id}` `{isPublic}` — owner-only; returns new isPublic.
    func setVisibility(id: String, isPublic: Bool) async throws -> Bool
    /// `POST /readings/{id}/reflect` — returns the created reflection id.
    func addReflection(id: String, body: String, mood: String?) async throws -> String
    /// `GET /readings/{id}/reflections` — newest-first reflection list.
    func reflections(id: String) async throws -> [Reflection]

    // Generic primitives (consumed by later epics)
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
    func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<SSEEvent, Error>
}
