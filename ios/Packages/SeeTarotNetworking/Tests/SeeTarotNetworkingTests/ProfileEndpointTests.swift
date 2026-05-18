import XCTest
import SeeTarotCore
@testable import SeeTarotNetworking

/// E04 `PATCH /profile`: only-dirty body, getSession re-hydrate, 400/401 map.
final class ProfileEndpointTests: XCTestCase {
    private let base = URL(string: "https://api.test")!

    private func makeClient(
        onUnauthorized: @escaping @Sendable () -> Void = {}
    ) -> LiveAPIClient {
        LiveAPIClient(baseURL: base, tokenStore: InMemoryTokenStore(),
                      session: .mocked,
                      retry: RetryPolicy(maxAttempts: 3, baseDelay: 0.01,
                                         sleep: { _ in }),
                      onUnauthorized: onUnauthorized)
    }

    private func bodyString(_ req: URLRequest) -> String {
        if let b = req.httpBody { return String(decoding: b, as: UTF8.self) }
        guard let s = req.httpBodyStream else { return "" }
        s.open(); defer { s.close() }
        var data = Data(); var buf = [UInt8](repeating: 0, count: 4096)
        while s.hasBytesAvailable {
            let n = s.read(&buf, maxLength: buf.count)
            if n <= 0 { break }
            data.append(buf, count: n)
        }
        return String(decoding: data, as: UTF8.self)
    }

    func testUpdateSendsOnlyProvidedFieldsThenRehydrates() async throws {
        let session = """
        {"user":{"id":"u1","name":"Neo","timezone":"Asia/Saigon",
         "preferredIntent":"career","onboardedAt":"2026-01-01T00:00:00Z"}}
        """
        MockURLProtocol.reset([
            .init(status: 200, headers: [:],
                  body: Data(#"{"id":"u1","timezone":"Asia/Saigon"}"#.utf8)),
            .init(status: 200, headers: [:], body: Data(session.utf8))
        ])
        let user = try await makeClient().updateProfile(
            name: nil, birthDate: nil, timezone: "Asia/Saigon",
            preferredIntent: nil)
        XCTAssertEqual(user?.timezone, "Asia/Saigon")
        let body = bodyString(MockURLProtocol.requests.first!)
        XCTAssertTrue(body.contains("timezone"), body)
        XCTAssertFalse(body.contains("\"name\""), body)
        XCTAssertFalse(body.contains("birthDate"), body)
        XCTAssertEqual(MockURLProtocol.requests.first?.httpMethod, "PATCH")
    }

    func testEmptyPayloadThrowsBeforeRequest() async {
        MockURLProtocol.reset([])
        do {
            _ = try await makeClient().updateProfile(
                name: nil, birthDate: nil, timezone: nil,
                preferredIntent: nil)
            XCTFail("expected throw")
        } catch APIError.transport { /* ok */ }
        catch { XCTFail("wrong error: \(error)") }
        XCTAssertTrue(MockURLProtocol.requests.isEmpty)
    }

    func testValidation400Maps() async {
        MockURLProtocol.reset([.init(status: 400, headers: [:], body: Data(
            #"{"error":"invalid body","issues":[{"path":["name"],"message":"too long"}]}"#.utf8))])
        do {
            _ = try await makeClient().updateProfile(
                name: "x", birthDate: nil, timezone: nil,
                preferredIntent: nil)
            XCTFail("expected throw")
        } catch APIError.http(let status, let env) {
            XCTAssertEqual(status, 400)
            XCTAssertEqual(env?.issues?.first?.message, "too long")
        } catch { XCTFail("wrong error: \(error)") }
    }

    func testUnauthorizedFiresHook() async {
        var hook = false
        let client = makeClient(onUnauthorized: { hook = true })
        MockURLProtocol.reset([.init(status: 401, headers: [:],
                                     body: Data(#"{"error":"unauthorized"}"#.utf8))])
        do {
            _ = try await client.updateProfile(
                name: "Neo", birthDate: nil, timezone: nil,
                preferredIntent: nil)
            XCTFail("expected throw")
        } catch APIError.unauthorized { XCTAssertTrue(hook) }
        catch { XCTFail("wrong error: \(error)") }
    }
}
