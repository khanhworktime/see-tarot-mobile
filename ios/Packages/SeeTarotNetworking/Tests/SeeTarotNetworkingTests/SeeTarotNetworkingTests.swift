import XCTest
import SeeTarotCore
@testable import SeeTarotNetworking

final class SeeTarotNetworkingTests: XCTestCase {
    private let base = URL(string: "https://api.test")!

    private func makeClient(
        store: TokenStoring = InMemoryTokenStore(),
        onUnauthorized: @escaping @Sendable () -> Void = {}
    ) -> LiveAPIClient {
        LiveAPIClient(
            baseURL: base, tokenStore: store, session: .mocked,
            // no-delay sleep so retry tests are instant
            retry: RetryPolicy(maxAttempts: 3, baseDelay: 0.01,
                               sleep: { _ in }),
            onUnauthorized: onUnauthorized)
    }

    func testModuleLoads() {
        XCTAssertEqual(SeeTarotNetworking.moduleName, "SeeTarotNetworking")
    }

    func testAuthProvidersDecodes() async throws {
        MockURLProtocol.reset([.init(status: 200, headers: [:],
                                     body: Data(#"{"google":true}"#.utf8))])
        let providers = try await makeClient().authProviders()
        XCTAssertTrue(providers.google)
    }

    func testCapturesSetAuthTokenHeader() async throws {
        let store = InMemoryTokenStore()
        MockURLProtocol.reset([
            .init(status: 200, headers: ["set-auth-token": "tok-123"], body: Data("{}".utf8))
        ])
        let client = makeClient(store: store)
        _ = try? await client.send(Endpoint(path: "x", requiresAuth: false),
                                   as: [String: String].self)
        XCTAssertEqual(store.token, "tok-123")
    }

    func testUnauthorizedTriggersHookAndThrows() async {
        var hookCalled = false
        let client = makeClient(onUnauthorized: { hookCalled = true })
        MockURLProtocol.reset([.init(status: 401, headers: [:],
                                     body: Data(#"{"error":"unauthorized"}"#.utf8))])
        do {
            _ = try await client.getSession()
            XCTFail("expected throw")
        } catch {
            XCTAssertEqual(error as? APIError, .unauthorized)
        }
        XCTAssertTrue(hookCalled)
    }

    func testValidationErrorEnvelopeWithIssues() async {
        let client = makeClient()
        let body = #"{"error":"bad_request","message":"invalid","issues":[{"path":["question"],"message":"too short"}]}"#
        MockURLProtocol.reset([.init(status: 400, headers: [:], body: Data(body.utf8))])
        do {
            _ = try await client.send(Endpoint(path: "x"), as: String.self)
            XCTFail("expected throw")
        } catch APIError.http(let status, let env) {
            XCTAssertEqual(status, 400)
            XCTAssertEqual(env?.issues?.first?.path, ["question"])
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testEntitlement403() async {
        let client = makeClient()
        MockURLProtocol.reset([.init(status: 403, headers: [:],
                                     body: Data(#"{"error":"daily_already_drawn"}"#.utf8))])
        do {
            _ = try await client.send(Endpoint(path: "readings/daily", method: .POST),
                                      as: Reading.self)
            XCTFail("expected throw")
        } catch {
            XCTAssertEqual(error as? APIError, .entitlement(code: "daily_already_drawn"))
        }
    }

    func testRetriesOn429ThenSucceeds() async throws {
        let client = makeClient()
        MockURLProtocol.reset([
            .init(status: 429, headers: [:], body: Data()),
            .init(status: 200, headers: [:], body: Data(#"{"google":false}"#.utf8))
        ])
        let providers = try await client.authProviders()
        XCTAssertFalse(providers.google)
    }

    func testSignInCapturesTokenThenHydratesSession() async throws {
        let store = InMemoryTokenStore()
        let user = #"{"user":{"id":"u1","email":"a@b.co","onboardedAt":null}}"#
        MockURLProtocol.reset([
            // POST /auth/sign-in/email → token header
            .init(status: 200, headers: ["set-auth-token": "sess-9"],
                  body: Data("{}".utf8)),
            // GET /auth/get-session → user
            .init(status: 200, headers: [:], body: Data(user.utf8))
        ])
        let client = makeClient(store: store)
        let result = try await client.signInEmail(email: "a@b.co", password: "pw123456")
        XCTAssertEqual(result.id, "u1")
        XCTAssertTrue(result.needsOnboarding)
        XCTAssertEqual(store.token, "sess-9")
    }

    func testSignOutClearsToken() async throws {
        let store = InMemoryTokenStore(token: "t")
        MockURLProtocol.reset([.init(status: 200, headers: [:], body: Data("{}".utf8))])
        try await makeClient(store: store).signOut()
        XCTAssertNil(store.token)
    }

    // MARK: SSEParser (pure)

    func testSSEParserYieldsNamedEvent() {
        var state = "message"
        XCTAssertNil(SSEParser.event(from: "event: delta", state: &state))
        let event = SSEParser.event(from: #"data: {"delta":"hi"}"#, state: &state)
        XCTAssertEqual(event?.name, "delta")
        let payload = try? JSONDecoder.api.decode(
            SSEPayload.Delta.self, from: event!.data)
        XCTAssertEqual(payload?.delta, "hi")
        XCTAssertEqual(state, "message")  // reset after frame
    }
}
