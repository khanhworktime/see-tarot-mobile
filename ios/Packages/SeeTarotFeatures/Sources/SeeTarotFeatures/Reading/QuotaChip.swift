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

/// Phase 08: Cosmic Mysticism re-skin — glass capsule chips, tabular figures
/// token on numeric counts to prevent digit jitter. Logic untouched.
public struct QuotaChip: View {
    @Environment(\.designTokens) private var tokens
    let quota: Quota

    public init(quota: Quota) { self.quota = quota }

    public var body: some View {
        let display = QuotaDisplay(quota)
        HStack(spacing: tokens.spacing.sm) {
            chip(display.tierText, isNumeric: false)
            chip(display.dailyText, isNumeric: true)
            chip(display.oracleText, isNumeric: true)
        }
    }

    private func chip(_ text: String, isNumeric: Bool) -> some View {
        Text(text)
            .font(isNumeric ? tokens.typography.quotaFigures : tokens.typography.caption)
            .foregroundStyle(tokens.palette.accentBright)
            .padding(.horizontal, tokens.spacing.sm)
            .padding(.vertical, tokens.spacing.xs)
            .background(
                Capsule()
                    .fill(tokens.palette.bgLayer2.opacity(0.7))
            )
            .overlay(
                Capsule()
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.4))
            )
    }
}
