import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

/// Live E03 smoke against the real BE. SKIPS cleanly unless
/// `SEE_TAROT_TEST_EMAIL`/`SEE_TAROT_TEST_PASSWORD` (+ optional
/// `SEE_TAROT_BASE_URL`) are set — never fakes green (dev rules / harness).
/// Asserts concrete round-trips (reflection echoes back, visibility flips) so
/// it cannot pass by merely not hitting the endpoint.
final class LiveHistorySmokeTests: XCTestCase {
    private func authedClient() async throws -> LiveAPIClient? {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["SEE_TAROT_TEST_EMAIL"],
              let password = env["SEE_TAROT_TEST_PASSWORD"] else {
            throw XCTSkip("Live E03 smoke skipped: set SEE_TAROT_TEST_EMAIL "
                          + "/ SEE_TAROT_TEST_PASSWORD to run.")
        }
        let base = URL(string: env["SEE_TAROT_BASE_URL"]
                       ?? "https://api.seetarot.com")!
        let client = LiveAPIClient(baseURL: base,
                                   tokenStore: InMemoryTokenStore())
        _ = try await client.signInEmail(email: email, password: password)
        return client
    }

    func testLiveHistoryReflectionVisibilityRoundTrip() async throws {
        guard let client = try await authedClient() else { return }

        let page = try await client.history(cursor: nil, limit: 20)
        guard let first = page.items.first else {
            throw XCTSkip("Account has no readings yet — draw one first.")
        }

        let reading = try await client.reading(id: first.id)
        XCTAssertEqual(reading.id, first.id)
        XCTAssertFalse(reading.interpretation.isEmpty)

        let marker = "smoke \(UUID().uuidString.prefix(8))"
        let newId = try await client.addReflection(
            id: first.id, body: marker, mood: "calm")
        XCTAssertFalse(newId.isEmpty)

        let list = try await client.reflections(id: first.id)
        XCTAssertTrue(list.contains { $0.body == marker },
                      "posted reflection must echo back in the list")

        let flipped = try await client.setVisibility(
            id: first.id, isPublic: !reading.isPublic)
        XCTAssertEqual(flipped, !reading.isPublic)
        // Restore original visibility (idempotent for a shared test account).
        _ = try await client.setVisibility(id: first.id,
                                           isPublic: reading.isPublic)
    }
}
