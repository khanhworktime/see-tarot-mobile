import Foundation

/// Quota/entitlement snapshot from `GET /quota` (BE doc §3.7).
///
/// `oracleRemaining` is `Infinity` server-side for unlimited tiers, which
/// `JSON.stringify` emits as `null` on the wire (confirmed by BE 2026-05-17).
/// So model it optional: `nil` ⇒ unlimited.
public struct Quota: Codable, Equatable, Sendable {
    public let tier: String
    public let dailyRemaining: Int
    public let oracleRemaining: Int?

    public var isOracleUnlimited: Bool { oracleRemaining == nil }

    public init(tier: String, dailyRemaining: Int, oracleRemaining: Int?) {
        self.tier = tier
        self.dailyRemaining = dailyRemaining
        self.oracleRemaining = oracleRemaining
    }
}
