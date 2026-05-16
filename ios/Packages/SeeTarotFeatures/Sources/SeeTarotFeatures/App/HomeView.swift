import SwiftUI
import SeeTarotCore

/// Placeholder authenticated home. Real spreads/daily flow is E02.
public struct HomeView: View {
    let user: SessionUser
    let onSignOut: () -> Void

    public init(user: SessionUser, onSignOut: @escaping () -> Void) {
        self.user = user
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("See Tarot").font(.largeTitle.bold())
            Text("Signed in as \(user.email ?? user.id)")
                .foregroundStyle(.secondary)
            Text("Foundation ready — readings arrive in E02.")
                .font(.footnote).foregroundStyle(.secondary)
            Button("Sign out", role: .destructive, action: onSignOut)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
