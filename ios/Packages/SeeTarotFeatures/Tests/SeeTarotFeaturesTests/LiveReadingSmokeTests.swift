import XCTest
import SeeTarotCore
import SeeTarotNetworking
@testable import SeeTarotFeatures

/// Live reading-flow smoke against the real BE (E02). SKIPS cleanly unless
/// `SEE_TAROT_TEST_EMAIL` / `SEE_TAROT_TEST_PASSWORD` (and optional
/// `SEE_TAROT_BASE_URL`) are set — never fakes green (dev rules / harness).
///
/// Covers the E02 contract end-to-end on the live stack: quota, daily
/// (idempotent — uses today's draw if already taken), and the Oracle SSE
/// pipeline (card → delta… → done).
final class LiveReadingSmokeTests: XCTestCase {
    private func makeAuthedClient() async throws -> LiveAPIClient? {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["SEE_TAROT_TEST_EMAIL"],
              let password = env["SEE_TAROT_TEST_PASSWORD"] else {
            throw XCTSkip("Live reading smoke skipped: set SEE_TAROT_TEST_EMAIL "
                          + "/ SEE_TAROT_TEST_PASSWORD to run.")
        }
        let base = URL(string: env["SEE_TAROT_BASE_URL"]
                       ?? "https://api.seetarot.com")!
        let client = LiveAPIClient(baseURL: base,
                                   tokenStore: InMemoryTokenStore())
        _ = try await client.signInEmail(email: email, password: password)
        return client
    }

    func testLiveQuotaAndDaily() async throws {
        guard let client = try await makeAuthedClient() else { return }

        let quota = try await client.quota()
        XCTAssertFalse(quota.tier.isEmpty, "quota.tier must be present")

        // Idempotent: reuse today's draw if it already exists (avoids 403
        // daily_already_drawn on a shared test account).
        let existing = try await client.dailyToday()
        let daily: Reading
        if let existing {
            daily = existing
        } else {
            daily = try await client.drawDaily(tz: "Asia/Saigon")
        }
        XCTAssertFalse(daily.id.isEmpty)
        XCTAssertFalse(daily.interpretation.isEmpty,
                       "daily reading must carry an interpretation")
        XCTAssertEqual(daily.kind, "daily")
    }

    func testLiveOracleSSEStream() async throws {
        guard let client = try await makeAuthedClient() else { return }

        let input = ReadingInput(
            kind: .oracle,
            spread: .single,
            intent: .general,
            question: "What energy should I focus on this week ahead?"
        )
        XCTAssertNil(input.clientValidationError, "input must pass client rules")

        var sawCard = false
        var deltaText = ""
        var doneReadingId: String?
        var failure: String?

        for try await event in client.generate(input) {
            switch event.name {
            case "card":
                sawCard = true
            case "delta":
                if let d = try? JSONDecoder().decode(
                    SSEPayload.Delta.self, from: event.data) {
                    deltaText += d.delta
                }
            case "done":
                if let done = try? JSONDecoder().decode(
                    SSEPayload.Done.self, from: event.data) {
                    doneReadingId = done.readingId
                }
            case "error":
                failure = String(data: event.data, encoding: .utf8) ?? "error"
            default:
                break
            }
            if doneReadingId != nil || failure != nil { break }
        }

        XCTAssertNil(failure, "SSE stream emitted error: \(failure ?? "")")
        XCTAssertTrue(sawCard, "expected at least one card event")
        XCTAssertFalse(deltaText.isEmpty, "expected streamed interpretation")
        XCTAssertNotNil(doneReadingId, "expected done event with readingId")
    }
}
