import Foundation

/// The authenticated user as returned by `GET /auth/get-session` (BE doc §2.2).
/// Custom Better Auth fields are optional to tolerate partial payloads.
public struct SessionUser: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String?
    public let email: String?
    public let tier: String?
    public let subscriptionStatus: String?
    public let subscriptionRenewsAt: String?
    public let kofiEmail: String?
    public let birthDate: String?       // YYYY-MM-DD
    public let timezone: String?
    public let preferredIntent: String?
    public let onboardedAt: String?     // nil ⇒ show onboarding

    public var needsOnboarding: Bool { onboardedAt == nil }

    public init(id: String, name: String? = nil, email: String? = nil,
                tier: String? = nil, subscriptionStatus: String? = nil,
                subscriptionRenewsAt: String? = nil, kofiEmail: String? = nil,
                birthDate: String? = nil, timezone: String? = nil,
                preferredIntent: String? = nil, onboardedAt: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.tier = tier
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionRenewsAt = subscriptionRenewsAt
        self.kofiEmail = kofiEmail
        self.birthDate = birthDate
        self.timezone = timezone
        self.preferredIntent = preferredIntent
        self.onboardedAt = onboardedAt
    }
}

/// `GET /auth/get-session` envelope: `{ user, session }` or `null`.
public struct SessionEnvelope: Codable, Equatable, Sendable {
    public let user: SessionUser?
}
