import Foundation

/// Pure client-side mirror of the BE `ProfileUpdateSchema`
/// (tarot-contract MCP 2026-05-18). No UIKit/SwiftUI — cheaply unit-tested.
/// Rules MUST match BE exactly (neither stricter nor looser).
public enum ProfileField: String, CaseIterable, Sendable {
    case name, birthDate, timezone, preferredIntent
}

public enum ProfileValidation {
    public static let intents = ["general", "love", "career", "finances",
                                 "feeling", "action", "yesNo"]

    private static let birthDateRegex =
        try! NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$")

    /// Validate the dirty payload. Empty input ⇒ the cross-field "≥1 field
    /// required" error keyed by `name` (form-level banner upstream).
    public static func errors(name: String?, birthDate: String?,
                              timezone: String?,
                              preferredIntent: String?)
        -> [ProfileField: String] {
        var out: [ProfileField: String] = [:]

        if let name {
            let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.count < 1 || t.count > 60 {
                out[.name] = "Name must be 1–60 characters."
            }
        }
        if let timezone, timezone.count < 1 || timezone.count > 64 {
            out[.timezone] = "Timezone must be 1–64 characters."
        }
        if let birthDate, !matches(birthDateRegex, birthDate) {
            out[.birthDate] = "Birth date must be YYYY-MM-DD."
        }
        if let preferredIntent, !intents.contains(preferredIntent) {
            out[.preferredIntent] = "Choose a valid reading focus."
        }
        if name == nil && birthDate == nil && timezone == nil
            && preferredIntent == nil {
            out[.name] = "Change at least one field."
        }
        return out
    }

    private static func matches(_ re: NSRegularExpression,
                                _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
}
