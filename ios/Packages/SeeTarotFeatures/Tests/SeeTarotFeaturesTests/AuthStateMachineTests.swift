import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

@MainActor
final class AuthStateMachineTests: XCTestCase {
    private func user(onboarded: Bool) -> SessionUser {
        SessionUser(id: "u1", name: "Nia", email: "n@x.co", tier: "plus",
                    subscriptionStatus: nil, subscriptionRenewsAt: nil,
                    kofiEmail: nil,
                    birthDate: onboarded ? "1990-01-01" : String?.none,
                    timezone: "Asia/Saigon", preferredIntent: nil,
                    onboardedAt: onboarded ? "2026-01-01T00:00:00Z" : String?.none)
    }

    private func makeStore(stub: StubAPIClient,
                           token: String? = nil) -> (AuthStore, InMemoryTokenStore) {
        let ts = InMemoryTokenStore(token: token)
        return (AuthStore(client: stub, tokenStore: ts), ts)
    }

    func testModuleLoads() {
        XCTAssertEqual(SeeTarotFeatures.moduleName, "SeeTarotFeatures")
    }

    func testBootstrapNoTokenSignedOut() async {
        let (store, _) = makeStore(stub: StubAPIClient())
        await store.bootstrap()
        XCTAssertEqual(store.state, .signedOut(message: nil))
    }

    func testBootstrapTokenOnboardedAuthenticated() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: true))
        let (store, _) = makeStore(stub: stub, token: "t")
        await store.bootstrap()
        if case .authenticated(let u) = store.state {
            XCTAssertEqual(u.id, "u1")
        } else { XCTFail("expected authenticated, got \(store.state)") }
    }

    func testBootstrapTokenNeedsOnboarding() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: false))
        let (store, _) = makeStore(stub: stub, token: "t")
        await store.bootstrap()
        if case .needsOnboarding = store.state {} else {
            XCTFail("expected needsOnboarding, got \(store.state)")
        }
    }

    func testBootstrapStaleTokenClearsAndSignsOut() async {
        let stub = StubAPIClient(sessionUser: nil)   // get-session → nil
        let (store, ts) = makeStore(stub: stub, token: "stale")
        await store.bootstrap()
        XCTAssertEqual(store.state, .signedOut(message: nil))
        XCTAssertNil(ts.token)
    }

    func testSignInSuccessRoutesByOnboarding() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: false))
        let (store, _) = makeStore(stub: stub)
        await store.signIn(email: "n@x.co", password: "secret")
        if case .needsOnboarding = store.state {} else {
            XCTFail("expected needsOnboarding, got \(store.state)")
        }
    }

    func testSignInInvalidCredentials() async {
        let stub = StubAPIClient()
        stub.authError = APIError.unauthorized
        let (store, _) = makeStore(stub: stub)
        await store.signIn(email: "n@x.co", password: "bad")
        XCTAssertEqual(store.state, .signedOut(message: "Invalid email or password."))
    }

    func testHandleUnauthorizedClearsSession() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: true))
        let (store, ts) = makeStore(stub: stub, token: "t")
        await store.bootstrap()
        store.handleUnauthorized()
        XCTAssertNil(ts.token)
        XCTAssertEqual(store.state,
                       .signedOut(message: "Your session expired. Please sign in."))
    }

    func testSignOutClearsState() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: true))
        let (store, ts) = makeStore(stub: stub, token: "t")
        await store.bootstrap()
        await store.signOut()
        XCTAssertNil(ts.token)
        XCTAssertEqual(store.state, .signedOut(message: nil))
        XCTAssertTrue(stub.signedOut)
    }

    func testCompleteOnboardingTransitionsToAuthenticated() async {
        let stub = StubAPIClient(sessionUser: user(onboarded: false))
        stub.sendResponder = { _ in Data(#"{"ok":true}"#.utf8) }
        let (store, _) = makeStore(stub: stub, token: "t")
        await store.bootstrap()
        // simulate BE now reporting onboarded after the POST
        stub.sessionUser = user(onboarded: true)
        await store.completeOnboarding(birthDate: "1990-01-01", name: "Nia")
        if case .authenticated = store.state {} else {
            XCTFail("expected authenticated, got \(store.state)")
        }
    }

    func testGoogleAvailabilityFromProviders() async {
        let stub = StubAPIClient()
        stub.providers = AuthProviders(google: true)
        let (store, _) = makeStore(stub: stub)
        await store.bootstrap()
        XCTAssertTrue(store.googleAvailable)
    }
}
