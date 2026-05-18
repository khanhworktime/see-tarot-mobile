import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Owner-only public/private switch. Caller MUST gate on `reading.isOwner`
/// (BE PATCH is owner-only). Reflects the server's authoritative state.
struct VisibilityToggle: View {
    @Environment(\.designTokens) private var tokens
    let isPublic: Bool
    let busy: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Label(isPublic ? "Public" : "Private",
                  systemImage: isPublic ? "globe" : "lock")
                .font(tokens.typography.caption)
            Spacer()
            if busy {
                ProgressView()
            } else {
                Button(isPublic ? "Make private" : "Make public",
                       action: onToggle)
                    .font(tokens.typography.caption)
            }
        }
        .padding(tokens.spacing.sm)
    }
}
