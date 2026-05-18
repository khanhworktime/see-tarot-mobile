import Foundation

/// A partial profile update (E04). Each field is `nil` when unchanged; only
/// non-nil fields are sent to `PATCH /profile` (≥1 required, enforced by the
/// store + BE). Avoids large positional tuples.
public struct ProfilePatch: Equatable, Sendable {
    public let name: String?
    public let birthDate: String?
    public let timezone: String?
    public let preferredIntent: String?

    public init(name: String? = nil, birthDate: String? = nil,
                timezone: String? = nil, preferredIntent: String? = nil) {
        self.name = name
        self.birthDate = birthDate
        self.timezone = timezone
        self.preferredIntent = preferredIntent
    }

    public var isEmpty: Bool {
        name == nil && birthDate == nil && timezone == nil
            && preferredIntent == nil
    }
}
