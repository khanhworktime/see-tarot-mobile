import Foundation
import SeeTarotCore

/// Centralizes: `set-auth-token` capture, error-envelope decoding, and status
/// mapping (BE doc §2.1 / §2.3). Used by every request before decoding.
public struct ResponseHandler: Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .api) { self.decoder = decoder }

    /// Capture the Better Auth bearer token if present (sign-in/up responses).
    /// NOTE (BE verify, auth phase): confirm header name `set-auth-token` on the
    /// live 1.6.3 build by logging response headers.
    public func captureToken(from response: URLResponse, into store: TokenStoring) {
        guard let http = response as? HTTPURLResponse else { return }
        if let token = http.value(forHTTPHeaderField: "set-auth-token"), !token.isEmpty {
            store.setToken(token)
        }
    }

    /// Validate status; throw a typed `APIError` for non-2xx. Returns body data
    /// for the caller to decode on success.
    public func validate(_ data: Data, _ response: URLResponse,
                         onUnauthorized: () -> Void) throws -> Data {
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        switch http.statusCode {
        case 200...299:
            return data
        case 401:
            onUnauthorized()
            throw APIError.unauthorized
        case 403:
            let env = try? decoder.decode(APIErrorEnvelope.self, from: data)
            if let code = env?.error { throw APIError.entitlement(code: code) }
            throw APIError.http(status: 403, envelope: env)
        case 429:
            throw APIError.rateLimited
        default:
            let env = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw APIError.http(status: http.statusCode, envelope: env)
        }
    }
}
