import SwiftUI

/// Brand primary button. Reused across features so styling stays DRY.
public struct PrimaryButton: View {
    @Environment(\.designTokens) private var tokens
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(tokens.typography.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, tokens.spacing.sm)
        }
        .tint(tokens.palette.accent)
        .buttonStyle(.borderedProminent)
    }
}

/// Centered branded loading indicator.
public struct LoadingView: View {
    @Environment(\.designTokens) private var tokens
    let label: String

    public init(_ label: String = "Loading…") { self.label = label }

    public var body: some View {
        VStack(spacing: tokens.spacing.sm) {
            ProgressView().tint(tokens.palette.accent)
            Text(label)
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.textSecondary)
        }
    }
}
