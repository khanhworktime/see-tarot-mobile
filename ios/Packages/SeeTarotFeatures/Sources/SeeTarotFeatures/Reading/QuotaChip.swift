import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Pure display model for the quota chip. `oracleRemaining == nil` ⇒ unlimited
/// (Infinity→null on the wire, billing.md) — show no number.
public struct QuotaDisplay: Equatable, Sendable {
    public let tierText: String
    public let dailyText: String
    public let oracleText: String

    public init(_ quota: Quota) {
        tierText = quota.tier.capitalized
        dailyText = "Daily \(quota.dailyRemaining)"
        oracleText = quota.isOracleUnlimited
            ? "Oracle ∞"
            : "Oracle \(quota.oracleRemaining ?? 0)"
    }
}

public struct QuotaChip: View {
    @Environment(\.designTokens) private var tokens
    let quota: Quota

    public init(quota: Quota) { self.quota = quota }

    public var body: some View {
        let display = QuotaDisplay(quota)
        HStack(spacing: tokens.spacing.sm) {
            ForEach([display.tierText, display.dailyText,
                     display.oracleText], id: \.self) { text in
                Text(text)
                    .font(tokens.typography.caption)
                    .padding(.horizontal, tokens.spacing.sm)
                    .padding(.vertical, tokens.spacing.xs)
                    .background(tokens.palette.surface, in: Capsule())
            }
        }
    }
}
