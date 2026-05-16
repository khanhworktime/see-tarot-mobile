import XCTest
import SeeTarotNetworking
@testable import SeeTarotFeatures

/// Live email sign-in smoke against the real BE. SKIPS cleanly unless
/// `SEE_TAROT_TEST_EMAIL` / `SEE_TAROT_TEST_PASSWORD` (and optional
/// `SEE_TAROT_BASE_URL`) are set — never fakes green (dev rules / harness).
///
/// Also the place to VERIFY the BE open item: confirm `set-auth-token` is
/// delivered as a response header on the live Better Auth 1.6.3 build.
final class LiveSignInSmokeTests: XCTestCase {
    func testLiveEmailSignInCapturesTokenAndHydratesSession() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["SEE_TAROT_TEST_EMAIL"],
              let password = env["SEE_TAROT_TEST_PASSWORD"] else {
            throw XCTSkip("Live smoke skipped: set SEE_TAROT_TEST_EMAIL / "
                          + "SEE_TAROT_TEST_PASSWORD to run (BE creds pending).")
        }
        let base = URL(string: env["SEE_TAROT_BASE_URL"]
                       ?? "https://api.seetarot.com")!
        let store = InMemoryTokenStore()
        let client = LiveAPIClient(baseURL: base, tokenStore: store)

        let user = try await client.signInEmail(email: email, password: password)
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertNotNil(store.token,
                        "BE did not deliver set-auth-token header — investigate")

        let session = try await client.getSession()
        XCTAssertEqual(session?.id, user.id)
    }
}
