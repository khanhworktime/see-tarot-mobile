import XCTest
import SeeTarotCore
@testable import SeeTarotNetworking

/// H1 review fix: transport-error retry only for idempotent requests; `429`
/// retries for any method. Plus H3: sign-in retries `getSession` once when it
/// momentarily returns null.
final class RetryPolicyIdempotencyTests: XCTestCase {
    private let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.001,
                                     sleep: { _ in })

    private func countCalls(idempotent: Bool,
                            _ error: Error) async -> Int {
        var calls = 0
        do {
            let _: Int = try await policy.run(idempotent: idempotent) {
                calls += 1
                throw error
            }
            XCTFail("expected throw")
        } catch {}
        return calls
    }

    func testTransportErrorNotRetriedForNonIdempotent() async {
        let calls = await countCalls(idempotent: false,
                                     URLError(.timedOut))
        XCTAssertEqual(calls, 1, "POST must not replay on transport error")
    }

    func testTransportErrorRetriedForIdempotent() async {
        let calls = await countCalls(idempotent: true, URLError(.timedOut))
        XCTAssertEqual(calls, 3, "GET retries up to maxAttempts")
    }

    func testRateLimitedRetriedEvenForNonIdempotent() async {
        let calls = await countCalls(idempotent: false,
                                     APIError.rateLimited)
        XCTAssertEqual(calls, 3, "429 is safe to retry for any method")
    }

    func testSignInRetriesGetSessionOnceWhenNull() async throws {
        let userBody = """
        {"user":{"id":"u1","name":"Neo","onboardedAt":"2026-01-01T00:00:00Z"}}
        """
        MockURLProtocol.reset([
            .init(status: 200,
                  headers: ["set-auth-token": "tok"],
                  body: Data(#"{"token":"tok"}"#.utf8)),   // sign-in
            .init(status: 200, headers: [:], body: Data("null".utf8)),   // get-session null
            .init(status: 200, headers: [:], body: Data(userBody.utf8))  // retry → user
        ])
        let client = LiveAPIClient(
            baseURL: URL(string: "https://api.test")!,
            tokenStore: InMemoryTokenStore(), session: .mocked,
            retry: RetryPolicy(maxAttempts: 3, baseDelay: 0.001,
                               sleep: { _ in }))
        let user = try await client.signInEmail(email: "a@b.c",
                                                password: "x")
        XCTAssertEqual(user.id, "u1")
    }
}
