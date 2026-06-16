import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Onboarding gate — captures birth date → `POST /profile/onboard`.
/// Phase 08: Cosmic Mysticism re-skin — glass panel, Cinzel headings.
/// Auth logic + store calls untouched.
public struct OnboardingView: View {
    @Environment(\.designTokens) private var tokens
    @State private var auth: AuthStore
    @State private var birthDate = Date()
    let user: SessionUser

    public init(auth: AuthStore, user: SessionUser) {
        self._auth = State(initialValue: auth)
        self.user = user
    }

    public var body: some View {
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: tokens.spacing.lg) {
                    header
                    formPanel
                }
                .padding(tokens.spacing.md)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: tokens.spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("Welcome\(user.name.map { ", \($0)" } ?? "")")
                .font(tokens.typography.title)
                .foregroundStyle(tokens.palette.accentBright)
                .multilineTextAlignment(.center)
            Text("The stars need your birth date to\nalign your readings.")
                .font(tokens.typography.body)
                .foregroundStyle(tokens.palette.accentDim)
                .multilineTextAlignment(.center)
        }
        .padding(.top, tokens.spacing.xl)
    }

    // MARK: - Form panel

    private var formPanel: some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.md) {
                Text("When were you born?")
                    .font(tokens.typography.heading)
                    .foregroundStyle(tokens.palette.accentBright)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DatePicker("Birth date", selection: $birthDate,
                           displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)

                celestialDivider

                PrimaryButton("Begin Your Journey") {
                    let iso = Self.formatter.string(from: birthDate)
                    Task { await auth.completeOnboarding(birthDate: iso,
                                                         name: user.name) }
                }
            }
        }
        .glassPanel()
    }

    private var celestialDivider: some View {
        HStack(spacing: tokens.spacing.sm) {
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.3))
                .frame(height: 1)
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(tokens.palette.accentSilver.opacity(0.6))
                .accessibilityHidden(true)
            Rectangle()
                .fill(tokens.palette.accentSilver.opacity(0.3))
                .frame(height: 1)
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()
}
