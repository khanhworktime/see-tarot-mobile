import Foundation

/// A typed request description. Keeps the client DRY (decision 0004).
public struct Endpoint: Sendable {
    public enum Method: String, Sendable { case GET, POST, PATCH, DELETE }

    public let path: String
    public let method: Method
    public let body: Data?
    public let requiresAuth: Bool
    /// Override/add headers (e.g. Accept for SSE).
    public let extraHeaders: [String: String]
    /// Query items appended via `URLComponents` (correctly percent-encoded —
    /// `appendingPathComponent` would mangle `?`/`&`). Empty ⇒ no query.
    public let queryItems: [URLQueryItem]

    public init(path: String, method: Method = .GET, body: Data? = nil,
                requiresAuth: Bool = true, extraHeaders: [String: String] = [:],
                queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.body = body
        self.requiresAuth = requiresAuth
        self.extraHeaders = extraHeaders
        self.queryItems = queryItems
    }

    public static func json<T: Encodable>(
        _ path: String, method: Method, _ payload: T,
        requiresAuth: Bool = true, encoder: JSONEncoder
    ) throws -> Endpoint {
        Endpoint(path: path, method: method,
                 body: try encoder.encode(payload), requiresAuth: requiresAuth)
    }
}
