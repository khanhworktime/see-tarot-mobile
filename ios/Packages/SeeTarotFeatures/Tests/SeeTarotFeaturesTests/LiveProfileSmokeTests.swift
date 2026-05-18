import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

/// Live E04 smoke vs real BE. SKIPS cleanly unless
/// `SEE_TAROT_TEST_EMAIL`/`SEE_TAROT_TEST_PASSWORD` (+ optional
/// `SEE_TAROT_BASE_URL`) set — never fakes green. Asserts the patched value
/// echoes back via session re-hydrate; restores the original (idempotent for
/// a shared account).
final class LiveProfileSmokeTests: XCTestCase {
    func testLiveUpdateProfileRoundTrip() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["SEE_TAROT_TEST_EMAIL"],
              let password = env["SEE_TAROT_TEST_PASSWORD"] else {
            throw XCTSkip("Live E04 smoke skipped: set SEE_TAROT_TEST_EMAIL "
                          + "/ SEE_TAROT_TEST_PASSWORD to run.")
        }
        let base = URL(string: env["SEE_TAROT_BASE_URL"]
                       ?? "https://api.seetarot.com")!
        let client = LiveAPIClient(baseURL: base,
                                   tokenStore: InMemoryTokenStore())
        let before = try await client.signInEmail(email: email,
                                                  password: password)
        let original = before.name ?? "Admin"

        let marker = "smoke-\(UUID().uuidString.prefix(6))"
        let updated = try await client.updateProfile(
            name: marker, birthDate: nil, timezone: nil,
            preferredIntent: nil)
        XCTAssertEqual(updated?.name, marker,
                       "patched name must echo back via getSession")

        // Restore.
        let restored = try await client.updateProfile(
            name: original, birthDate: nil, timezone: nil,
            preferredIntent: nil)
        XCTAssertEqual(restored?.name, original)
    }
}
