import XCTest
import SeeTarotCore
@testable import SeeTarotNetworking

/// L3 review fix: `getSession` returns nil ONLY for a literal null/empty body
/// (clean logged-out); a malformed body throws (BE contract shift surfaces,
/// not a silent phantom sign-out).
final class GetSessionDecodeTests: XCTestCase {
    private func client() -> LiveAPIClient {
        LiveAPIClient(baseURL: URL(string: "https://api.test")!,
                      tokenStore: InMemoryTokenStore(token: "t"),
                      session: .mocked,
                      retry: RetryPolicy(maxAttempts: 1, baseDelay: 0.001,
                                         sleep: { _ in }))
    }

    func testNullBodyIsLoggedOut() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data("null".utf8))])
        let user = try await client().getSession()
        XCTAssertNil(user)
    }

    func testEmptyBodyIsLoggedOut() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data())])
        let user = try await client().getSession()
        XCTAssertNil(user)
    }

    func testTypeMismatchThrowsNotSilentSignOut() async {
        // `user` present but wrong shape (string, not object) — a real
        // contract shift. Must throw, not be swallowed into a phantom
        // sign-out. (An object merely lacking `user` is a valid logged-out
        // state per the intentionally tolerant SessionUser model.)
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data(#"{"user":"not-an-object"}"#.utf8))])
        do {
            _ = try await client().getSession()
            XCTFail("expected decode throw, not silent nil")
        } catch APIError.decoding { /* correct */ }
        catch { XCTFail("wrong error: \(error)") }
    }

    func testValidEnvelopeDecodes() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:], body: Data(
            #"{"user":{"id":"u1","onboardedAt":"2026-01-01T00:00:00Z"}}"#.utf8))])
        let user = try await client().getSession()
        XCTAssertEqual(user?.id, "u1")
    }
}
