import Foundation

/// Builds `URLRequest`s: base URL + JSON content type + Bearer auth. Single
/// source for the `authed()` pattern (BE doc §2.3).
public struct RequestBuilder: Sendable {
    private let baseURL: URL

    public init(baseURL: URL) { self.baseURL = baseURL }

    public func makeRequest(_ endpoint: Endpoint, token: String?) -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if endpoint.requiresAuth, let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        for (key, value) in endpoint.extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = endpoint.body
        return request
    }
}
