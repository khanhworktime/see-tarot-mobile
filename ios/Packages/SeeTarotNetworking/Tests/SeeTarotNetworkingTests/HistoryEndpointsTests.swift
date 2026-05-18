import XCTest
import SeeTarotCore
@testable import SeeTarotNetworking

/// E03 Live history/reflection endpoints: decode + query construction +
/// error mapping, via the sequential `MockURLProtocol`.
final class HistoryEndpointsTests: XCTestCase {
    private let base = URL(string: "https://api.test")!

    private func makeClient() -> LiveAPIClient {
        LiveAPIClient(baseURL: base, tokenStore: InMemoryTokenStore(),
                      session: .mocked,
                      retry: RetryPolicy(maxAttempts: 3, baseDelay: 0.01,
                                         sleep: { _ in }))
    }

    func testHistoryDecodesAndSendsCursorLimitQuery() async throws {
        let body = """
        {"items":[{"id":"a","kind":"daily","spread":"single",
         "preview":"p","createdAt":"2026-05-18T05:00:00Z"}],
         "nextCursor":"2026-05-18T04:00:00Z"}
        """
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data(body.utf8))])
        let page = try await makeClient().history(
            cursor: "2026-05-18T06:00:00Z", limit: 20)
        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.nextCursor, "2026-05-18T04:00:00Z")
        let url = MockURLProtocol.requests.first?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("limit=20"), url)
        XCTAssertTrue(url.contains("cursor="), url)
    }

    func testHistoryUnauthorizedFiresHook() async {
        var hook = false
        let client = LiveAPIClient(baseURL: base,
                                   tokenStore: InMemoryTokenStore(),
                                   session: .mocked,
                                   onUnauthorized: { hook = true })
        MockURLProtocol.reset([.init(status: 401, headers: [:],
                                     body: Data("{\"error\":\"unauthorized\"}".utf8))])
        do { _ = try await client.history(cursor: nil, limit: 20)
             XCTFail("expected throw")
        } catch { XCTAssertTrue(hook) }
    }

    func testAddReflectionReturnsCreatedId() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data("{\"id\":\"ref-9\"}".utf8))])
        let id = try await makeClient().addReflection(
            id: "rd1", body: "a thoughtful note", mood: "calm")
        XCTAssertEqual(id, "ref-9")
    }

    func testSetVisibilityReturnsServerBool() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data("{\"id\":\"rd1\",\"isPublic\":true}".utf8))])
        let isPublic = try await makeClient().setVisibility(
            id: "rd1", isPublic: true)
        XCTAssertTrue(isPublic)
    }

    func testReflectionsListDecodes() async throws {
        let body = """
        {"items":[{"id":"r1","body":"hi there",
         "createdAt":"2026-05-18T05:00:00Z"}]}
        """
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data(body.utf8))])
        let list = try await makeClient().reflections(id: "rd1")
        XCTAssertEqual(list.first?.id, "r1")
    }

    func testReadingNotFoundMaps404() async {
        MockURLProtocol.reset([.init(status: 404, headers: [:],
                                     body: Data("{\"error\":\"not found\"}".utf8))])
        do { _ = try await makeClient().reading(id: "missing")
             XCTFail("expected throw")
        } catch APIError.http(let status, _) {
            XCTAssertEqual(status, 404)
        } catch { XCTFail("wrong error: \(error)") }
    }
}
