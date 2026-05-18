import Foundation

/// A page of reading history (`GET /readings`, BE doc §3.5 / §5).
public struct HistoryPage: Codable, Equatable, Sendable {
    public struct Row: Codable, Identifiable, Equatable, Sendable {
        public let id: String
        public let kind: String
        public let spread: String
        public let intent: String?
        public let question: String?
        /// ≤140 chars preview.
        public let preview: String
        public let createdAt: String

        public init(id: String, kind: String, spread: String,
                    intent: String?, question: String?, preview: String,
                    createdAt: String) {
            self.id = id; self.kind = kind; self.spread = spread
            self.intent = intent; self.question = question
            self.preview = preview; self.createdAt = createdAt
        }
    }

    public let items: [Row]
    /// Pass back as `cursor`; `nil` ⇒ end of history.
    public let nextCursor: String?

    public init(items: [Row], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
