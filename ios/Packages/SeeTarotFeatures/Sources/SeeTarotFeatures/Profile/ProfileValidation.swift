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

    /// `^\d{4}-\d{2}-\d{2}$` without a force-unwrapped regex.
    private static func isISODay(_ s: String) -> Bool {
        let parts = s.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2
        else { return false }
        return parts.allSatisfy { $0.allSatisfy(\.isNumber) }
    }

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
        if let birthDate, !isISODay(birthDate) {
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
}
