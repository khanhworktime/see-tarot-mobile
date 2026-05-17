import Foundation

/// Input for generating a reading. Encoded to the BE `/readings/generate`
/// (SSE) or `/readings/daily` request. Mirrors BE doc §3.2 / §5.
public struct ReadingInput: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable { case daily, oracle }
    public enum Spread: String, Codable, Hashable, Sendable {
        case single, three, celtic
    }
    public enum Intent: String, Codable, Hashable, Sendable, CaseIterable {
        case general, love, career, finances, feeling, action, yesNo
    }

    public let kind: Kind
    public let spread: Spread
    public let intent: Intent
    /// Required unless `kind == .daily`. 10–500 chars (server-enforced).
    public let question: String?

    public init(kind: Kind, spread: Spread, intent: Intent, question: String? = nil) {
        self.kind = kind
        self.spread = spread
        self.intent = intent
        self.question = question
    }

    /// Client-side mirror of BE validation rules (UX only; server is truth).
    public var clientValidationError: String? {
        switch kind {
        case .daily:
            if spread != .single { return "Daily reading must use a single card." }
            if question?.isEmpty == false { return "Daily reading takes no question." }
        case .oracle:
            guard let q = question, (10...500).contains(q.count) else {
                return "Oracle reading needs a question of 10–500 characters."
            }
        }
        if intent == .yesNo, (question?.count ?? 0) < 10 {
            return "Yes / No reading needs a question."
        }
        if spread == .celtic { return "Celtic spread is not available yet." }
        return nil
    }
}
