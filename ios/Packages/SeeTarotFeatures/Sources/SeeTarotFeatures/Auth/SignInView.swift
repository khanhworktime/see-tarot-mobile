import SwiftUI
import SeeTarotDesignSystem

/// Email/password sign-in + sign-up toggle.
/// Phase 08: Cosmic Mysticism re-skin — glass form panel, Cinzel headings,
/// palette accents. Auth logic untouched.
public struct SignInView: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    let message: String?

    public init(auth: AuthStore, message: String?) {
        self._auth = State(initialValue: auth)
        self.message = message
    }

    public var body: some View {
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: tokens.spacing.lg) {
                    header
                    formPanel
                    toggleButton
                    if auth.googleAvailable { googleSeam }
                }
                .padding(tokens.spacing.md)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: tokens.spacing.sm) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 44))
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("See Tarot")
                .font(tokens.typography.display)
                .foregroundStyle(tokens.palette.accentBright)
                .multilineTextAlignment(.center)
        }
        .padding(.top, tokens.spacing.xl)
    }

    // MARK: - Form panel

    private var formPanel: some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.md) {
                if let message {
                    HStack(spacing: tokens.spacing.sm) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(tokens.palette.accentSilver)
                        Text(message)
                            .font(tokens.typography.caption)
                            .foregroundStyle(tokens.palette.accentBright)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if isSignUp {
                    nameField
                }
                emailField
                passwordField
                PrimaryButton(isSignUp ? "Create Account" : "Sign In") {
                    Task {
                        if isSignUp {
                            await auth.signUp(name: name, email: email, password: password)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                    }
                }
                .disabled(email.isEmpty || password.count < 6)
            }
        }
        .glassPanel()
    }

    // MARK: - Toggle + Google seam

    private var toggleButton: some View {
        Button(isSignUp ? "Have an account? Sign in"
                        : "New here? Create an account") {
            withAnimation(reduceMotion ? .none : tokens.motion.quick) {
                isSignUp.toggle()
            }
        }
        .font(tokens.typography.caption)
        .foregroundStyle(tokens.palette.accentSilver)
        .frame(minHeight: 44)
    }

    private var googleSeam: some View {
        Button("Continue with Google") {}
            .disabled(true)
            .font(tokens.typography.caption)
            .foregroundStyle(tokens.palette.accentDim)
            .frame(minHeight: 44)
            .help("Google sign-in arrives after BE native flow is set.")
    }

    // MARK: - Field builders (platform-branched for content-type / keyboard)

    private var nameField: some View {
        styledTextField("Name", text: $name)
        #if os(iOS)
            .textContentType(.name)
        #endif
    }

    private var emailField: some View {
        styledTextField("Email", text: $email)
            .autocorrectionDisabled()
        #if os(iOS)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .textContentType(.emailAddress)
        #endif
    }

    private var passwordField: some View {
        styledSecureField("Password", text: $password)
        #if os(iOS)
            .textContentType(isSignUp ? .newPassword : .password)
        #endif
    }

    private func styledTextField(_ placeholder: String,
                                  text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .padding(tokens.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tokens.palette.bgLayer2.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.4))
            )
            .frame(minHeight: 44)
    }

    private func styledSecureField(_ placeholder: String,
                                    text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .padding(tokens.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tokens.palette.bgLayer2.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.4))
            )
            .frame(minHeight: 44)
    }
}
