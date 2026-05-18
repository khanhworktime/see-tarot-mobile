import Foundation
import SeeTarotCore

/// Live `URLSession` API client. `URLSession` is injectable so unit tests use
/// a `URLProtocol` mock (no network).
public final class LiveAPIClient: APIClientProtocol, @unchecked Sendable {
    let session: URLSession
    let builder: RequestBuilder
    let handler: ResponseHandler
    let retry: RetryPolicy
    let tokenStore: TokenStoring
    let decoder: JSONDecoder
    let encoder: JSONEncoder
    private let onUnauthorized: @Sendable () -> Void

    /// Bearer-only session: no cookie storage so the BE never sees a stale
    /// session cookie (which would trip Better Auth CSRF / Origin checks).
    public static func makeBearerSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.httpCookieStorage = nil
        cfg.httpShouldSetCookies = false
        cfg.httpCookieAcceptPolicy = .never
        return URLSession(configuration: cfg)
    }

    public init(baseURL: URL, tokenStore: TokenStoring,
                session: URLSession = LiveAPIClient.makeBearerSession(),
                retry: RetryPolicy = RetryPolicy(),
                decoder: JSONDecoder = .api, encoder: JSONEncoder = .api,
                onUnauthorized: @escaping @Sendable () -> Void = {}) {
        self.session = session
        self.builder = RequestBuilder(baseURL: baseURL)
        self.handler = ResponseHandler(decoder: decoder)
        self.retry = retry
        self.tokenStore = tokenStore
        self.decoder = decoder
        self.encoder = encoder
        self.onUnauthorized = onUnauthorized
    }

    /// Perform a request with retry; always captures `set-auth-token`; maps
    /// status to typed errors. Returns validated body data.
    @discardableResult
    func perform(_ endpoint: Endpoint) async throws -> Data {
        // Only GET is safe to replay on a transport error (a lost POST
        // response may already be applied server-side). 429 still retries.
        try await retry.run(idempotent: endpoint.method == .GET) { [self] in
            let request = builder.makeRequest(endpoint, token: tokenStore.token)
            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await session.data(for: request)
            } catch let urlError as URLError {
                throw urlError
            } catch {
                throw APIError.transport(error.localizedDescription)
            }
            handler.captureToken(from: response, into: tokenStore)
            return try handler.validate(data, response,
                                        onUnauthorized: onUnauthorized)
        }
    }

    public func send<T: Decodable & Sendable>(_ endpoint: Endpoint,
                                              as type: T.Type) async throws -> T {
        let data = try await perform(endpoint)
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decoding(String(describing: error)) }
    }

    // MARK: Auth surface

    public func authProviders() async throws -> AuthProviders {
        try await send(Endpoint(path: "auth-providers", method: .GET,
                                requiresAuth: false), as: AuthProviders.self)
    }

    public func signUpEmail(name: String, email: String,
                            password: String) async throws -> SessionUser {
        try await authenticate(path: "auth/sign-up/email",
                               body: ["name": name, "email": email,
                                      "password": password])
    }

    public func signInEmail(email: String,
                            password: String) async throws -> SessionUser {
        try await authenticate(path: "auth/sign-in/email",
                               body: ["email": email, "password": password])
    }

    /// POST credentials → token captured from `set-auth-token` → hydrate the
    /// user via `/auth/get-session` (BE doc §2.1 recommended pattern; avoids
    /// guessing the sign-in body schema).
    private func authenticate(path: String,
                              body: [String: String]) async throws -> SessionUser {
        let endpoint = Endpoint(path: path, method: .POST,
                                body: try encoder.encode(body),
                                requiresAuth: false)
        _ = try await perform(endpoint)
        // Token is captured by now. `get-session` can momentarily return null
        // right after issuance (read lag — esp. during the BE NestJS
        // migration); retry once briefly before failing the sign-in.
        if let user = try await getSession() { return user }
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard let user = try await getSession() else {
            throw APIError.badResponse
        }
        return user
    }

    public func getSession() async throws -> SessionUser? {
        let data = try await perform(Endpoint(path: "auth/get-session",
                                              method: .GET))
        if let env = try? decoder.decode(SessionEnvelope.self, from: data) {
            return env.user
        }
        return nil   // body was `null`
    }

    public func signOut() async throws {
        _ = try await perform(Endpoint(path: "auth/sign-out", method: .POST))
        tokenStore.setToken(nil)
    }
}
