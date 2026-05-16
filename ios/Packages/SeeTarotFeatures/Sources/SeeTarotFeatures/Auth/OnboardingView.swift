import SwiftUI
import SeeTarotCore

/// Onboarding gate seam (real form is E04). Captures birth date →
/// `POST /profile/onboard`.
public struct OnboardingView: View {
    @State private var auth: AuthStore
    @State private var birthDate = Date()
    let user: SessionUser

    public init(auth: AuthStore, user: SessionUser) {
        self._auth = State(initialValue: auth)
        self.user = user
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Welcome\(user.name.map { ", \($0)" } ?? "")")
                .font(.title2.bold())
            Text("When were you born?").foregroundStyle(.secondary)
            DatePicker("Birth date", selection: $birthDate,
                       displayedComponents: .date)
                .labelsHidden()
            Button("Continue") {
                let iso = Self.formatter.string(from: birthDate)
                Task { await auth.completeOnboarding(birthDate: iso,
                                                     name: user.name) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()
}
