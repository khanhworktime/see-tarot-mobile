import Foundation

/// A hydrated reading. BE doc §5. Server-returned `intent`/`tier` are kept as
/// `String` (not enums) to tolerate future BE additions without breaking decode.
public struct Reading: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let userId: String
    public let kind: String
    public let spread: String
    public let intent: String?
    public let question: String?
    public let interpretation: String
    public let model: String
    public let tier: String
    public let isPublic: Bool
    /// ISO-8601 string as returned by BE (parsed at the edge, not here).
    public let createdAt: String
    public let cards: [ReadingCard]
    public let reflections: [Reflection]?
    public let isOwner: Bool
}

/// A single drawn card within a reading. BE doc §5 / SSE `card` payload.
public struct ReadingCard: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let arcana: String          // "major" | "minor"
    public let suit: String?           // cups|wands|swords|pentacles | null
    public let number: Int?
    public let imageUrl: String?
    public let position: Int
    public let reversed: Bool
    public let keywords: [String]
    public let uprightMeaning: String
    public let reversedMeaning: String
}
