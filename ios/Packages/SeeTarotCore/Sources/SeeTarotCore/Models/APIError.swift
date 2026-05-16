import Foundation

/// Consistent BE error envelope: `{ error, message?, issues? }` (BE doc §2.3).
/// `issues` is a Zod array on 400 validation failures.
public struct APIErrorEnvelope: Codable, Equatable, Sendable {
    public struct Issue: Codable, Equatable, Sendable {
        public let path: [String]?
        public let message: String?
        public let code: String?
    }

    public let error: String
    public let message: String?
    public let issues: [Issue]?
}

/// Typed client-facing error surfaced by the networking layer.
public enum APIError: Error, Equatable, Sendable {
    case http(status: Int, envelope: APIErrorEnvelope?)
    case unauthorized                  // 401 ⇒ drop token + sign-in
    case rateLimited                   // 429
    case entitlement(code: String)     // 403 celtic_coming_soon | daily_already_drawn | oracle_weekly_limit
    case decoding(String)
    case transport(String)
    case badResponse
}
