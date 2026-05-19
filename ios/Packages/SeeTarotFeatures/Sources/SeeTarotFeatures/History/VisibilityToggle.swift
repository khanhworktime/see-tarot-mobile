import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Owner-only public/private switch. Caller MUST gate on `reading.isOwner`
/// (BE PATCH is owner-only). Reflects the server's authoritative state.
/// Phase 08: Cosmic Mysticism re-skin — glass card, palette. Logic untouched.
struct VisibilityToggle: View {
    @Environment(\.designTokens) private var tokens
    let isPublic: Bool
    let busy: Bool
    let onToggle: () -> Void

    var body: some View {
        GlassSurface {
            HStack {
                Label(isPublic ? "Public" : "Private",
                      systemImage: isPublic ? "globe" : "lock")
                    .font(tokens.typography.caption)
                    .foregroundStyle(tokens.palette.accentSilver)
                Spacer()
                if busy {
                    ProgressView()
                        .tint(tokens.palette.accentSilver)
                } else {
                    Button(action: onToggle) {
                        Text(isPublic ? "Make Private" : "Make Public")
                            .font(tokens.typography.caption)
                            .foregroundStyle(tokens.palette.accentBright)
                            .padding(.horizontal, tokens.spacing.sm)
                            .padding(.vertical, tokens.spacing.xs)
                            .background(
                                Capsule()
                                    .fill(tokens.palette.bgLayer2.opacity(0.6))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(tokens.palette.accentSilver.opacity(0.4))
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .glassCard()
    }
}
