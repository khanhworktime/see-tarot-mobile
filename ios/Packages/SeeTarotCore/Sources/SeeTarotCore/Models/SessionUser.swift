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
}

/// `GET /auth/get-session` envelope: `{ user, session }` or `null`.
public struct SessionEnvelope: Codable, Equatable, Sendable {
    public let user: SessionUser?
}
