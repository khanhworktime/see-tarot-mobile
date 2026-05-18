import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// One history row: kind/spread badge, preview, relative date. No PII beyond
/// the server-provided `preview`.
struct HistoryRowView: View {
    @Environment(\.designTokens) private var tokens
    let row: HistoryPage.Row

    var body: some View {
        VStack(alignment: .leading, spacing: tokens.spacing.xs) {
            HStack {
                Text("\(row.kind.capitalized) · \(row.spread.capitalized)")
                    .font(tokens.typography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Self.relativeDate(row.createdAt))
                    .font(tokens.typography.caption)
                    .foregroundStyle(.secondary)
            }
            Text(row.preview)
                .font(tokens.typography.body)
                .lineLimit(2)
        }
        .padding(.vertical, tokens.spacing.xs)
    }

    static func relativeDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
