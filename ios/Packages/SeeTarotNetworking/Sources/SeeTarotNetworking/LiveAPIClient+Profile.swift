import Foundation
import SeeTarotCore

/// Profile endpoint (E04). `PATCH /profile` then re-hydrate via
/// `getSession` (single source of truth — `ProfileResponse` lacks
/// email/tier/onboardedAt). Reuses `send`/`ResponseHandler` (401 → sign-out).
public extension LiveAPIClient {
    func updateProfile(name: String?, birthDate: String?, timezone: String?,
                       preferredIntent: String?) async throws -> SessionUser? {
        var body: [String: String] = [:]
        if let name { body["name"] = name }
        if let birthDate { body["birthDate"] = birthDate }
        if let timezone { body["timezone"] = timezone }
        if let preferredIntent { body["preferredIntent"] = preferredIntent }
        guard !body.isEmpty else {
            throw APIError.transport("updateProfile: no fields to update")
        }
        let endpoint = Endpoint(path: "profile", method: .PATCH,
                                body: try encoder.encode(body))
        _ = try await send(endpoint, as: ProfileResponse.self)
        return try await getSession()
    }
}

/// Contract-exact wire type (tarot-contract MCP 2026-05-18), private to
/// Networking. Decoded only as a success sanity check; `getSession` is
/// authoritative for the in-app `SessionUser`.
private struct ProfileResponse: Decodable {
    let id: String
    let name: String?
    let timezone: String?
    let preferredIntent: String?
    let birthDate: String?
}
