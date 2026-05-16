import Foundation
import SeeTarotCore

/// The auth/session state machine (decision 0005). `loading` is the launch
/// bootstrap; `needsOnboarding` gates the onboarding flow (`onboardedAt==nil`).
public enum AuthState: Equatable, Sendable {
    case loading
    case signedOut(message: String?)
    case authenticating
    case needsOnboarding(SessionUser)
    case authenticated(SessionUser)

    public var user: SessionUser? {
        switch self {
        case .needsOnboarding(let u), .authenticated(let u): return u
        default: return nil
        }
    }
}
