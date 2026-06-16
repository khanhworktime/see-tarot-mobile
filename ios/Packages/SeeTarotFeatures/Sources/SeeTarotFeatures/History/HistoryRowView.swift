import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// One history row: kind/spread badge, preview, relative date.
/// Phase 08: Cosmic Mysticism re-skin — glass card, palette typography.
/// No PII beyond the server-provided `preview`.
struct HistoryRowView: View {
    @Environment(\.designTokens) private var tokens
    let row: HistoryPage.Row

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.xs) {
                HStack {
                    Label("\(row.kind.capitalized) · \(row.spread.capitalized)",
                          systemImage: "sparkles")
                        .font(tokens.typography.caption)
                        .foregroundStyle(tokens.palette.accentSilver)
                        .labelStyle(.titleAndIcon)
                    Spacer()
                    Text(Self.relativeDate(row.createdAt))
                        .font(tokens.typography.caption)
                        .foregroundStyle(tokens.palette.accentDim)
                }
                Text(row.preview)
                    .font(tokens.typography.body)
                    .foregroundStyle(tokens.palette.accentBright)
                    .lineLimit(2)
            }
        }
        .glassCard()
        .padding(.vertical, tokens.spacing.xs)
        .frame(minHeight: 44)
    }

    static func relativeDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
