import Foundation

/// A journal entry on a reading. Append-only. Shape reconciled to the live
/// contract (tarot-contract MCP 2026-05-18): `{id, body, mood?, createdAt}`.
/// `readingId`/`userId` are NOT returned by `GET /readings/{id}/reflections`
/// (the reading id is the path param) — removed so decode does not fail.
public struct Reflection: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let body: String
    public let mood: String?
    /// ISO-8601 string as returned by BE (parsed at the edge, not here).
    public let createdAt: String

    public init(id: String, body: String, mood: String?, createdAt: String) {
        self.id = id
        self.body = body
        self.mood = mood
        self.createdAt = createdAt
    }
}
