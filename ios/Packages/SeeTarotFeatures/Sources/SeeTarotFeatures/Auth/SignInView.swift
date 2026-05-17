import SwiftUI
import SeeTarotDesignSystem

/// Minimal email/password sign-in + sign-up toggle. Plain styling; Phase 06
/// restyles with DesignSystem. Google button shown only when available (seam —
/// no flow in E01).
public struct SignInView: View {
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
        VStack(spacing: 16) {
            Text("See Tarot").font(.largeTitle.bold())
            if let message { Text(message).foregroundStyle(.red).font(.callout) }
            if isSignUp {
                TextField("Name", text: $name).textContentType(.name)
            }
            emailField
            SecureField("Password", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
            PrimaryButton(isSignUp ? "Create account" : "Sign in") {
                Task {
                    if isSignUp {
                        await auth.signUp(name: name, email: email, password: password)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                }
            }
            .disabled(email.isEmpty || password.count < 6)

            Button(isSignUp ? "Have an account? Sign in"
                            : "New here? Create an account") {
                isSignUp.toggle()
            }
            .font(.footnote)

            if auth.googleAvailable {
                Button("Continue with Google") {}
                    .disabled(true)
                    .help("Google sign-in arrives after BE native flow is set.")
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
    }

    private var emailField: some View {
        let field = TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
        #if os(iOS)
        return field
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
        #else
        return field
        #endif
    }
}
