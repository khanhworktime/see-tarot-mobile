import Foundation

/// A journal entry on a reading. Append-only (BE doc §3.6 / §5).
public struct Reflection: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let readingId: String
    public let userId: String
    public let body: String
    public let mood: String?
    public let createdAt: String
}
