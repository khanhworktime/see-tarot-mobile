import SeeTarotCore

/// iOS-owned user-facing copy for reading intents (BE stores no labels —
/// readings.md). One entry per `ReadingInput.Intent`.
public struct IntentCopy: Equatable, Sendable {
    public let intent: ReadingInput.Intent
    public let label: String
    public let detail: String

    public static let all: [IntentCopy] = [
        .init(intent: .general, label: "General",
              detail: "Open guidance, no specific area."),
        .init(intent: .love, label: "Love",
              detail: "Relationships, romance, connection."),
        .init(intent: .career, label: "Career",
              detail: "Work, vocation, direction."),
        .init(intent: .finances, label: "Finances",
              detail: "Money, resources, material concerns."),
        .init(intent: .feeling, label: "Feelings",
              detail: "Emotional insight and inner state."),
        .init(intent: .action, label: "Action",
              detail: "What to do — the next step or decision."),
        .init(intent: .yesNo, label: "Yes / No",
              detail: "A clear verdict on a specific question.")
    ]

    public static func copy(for intent: ReadingInput.Intent) -> IntentCopy {
        all.first { $0.intent == intent } ?? all[0]
    }
}
