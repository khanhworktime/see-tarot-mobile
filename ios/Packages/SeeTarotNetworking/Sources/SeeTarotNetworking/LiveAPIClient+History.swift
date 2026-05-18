import Foundation
import SeeTarotCore

/// History + reflections endpoints (E03). Contract: tarot-contract MCP
/// 2026-05-18. Reuses `send`/`perform` + `ResponseHandler` error mapping
/// (401 → sign-out seam, etc.) — no bespoke handling here.
public extension LiveAPIClient {
    func history(cursor: String?, limit: Int) async throws -> HistoryPage {
        var items: [URLQueryItem] = [.init(name: "limit", value: String(limit))]
        if let cursor, !cursor.isEmpty {
            items.append(.init(name: "cursor", value: cursor))
        }
        return try await send(
            Endpoint(path: "readings", method: .GET, queryItems: items),
            as: HistoryPage.self)
    }

    func reading(id: String) async throws -> Reading {
        // Public endpoint; bearer still sent if present (owner context).
        try await send(Endpoint(path: "readings/\(id)", method: .GET),
                       as: Reading.self)
    }

    func setVisibility(id: String, isPublic: Bool) async throws -> Bool {
        let endpoint = Endpoint(
            path: "readings/\(id)", method: .PATCH,
            body: try encoder.encode(["isPublic": isPublic]))
        return try await send(endpoint, as: VisibilityResponse.self).isPublic
    }

    func addReflection(id: String, body: String,
                       mood: String?) async throws -> String {
        let endpoint = Endpoint(
            path: "readings/\(id)/reflect", method: .POST,
            body: try encoder.encode(ReflectionCreateBody(body: body,
                                                          mood: mood)))
        return try await send(endpoint, as: CreatedIdResponse.self).id
    }

    func reflections(id: String) async throws -> [Reflection] {
        try await send(Endpoint(path: "readings/\(id)/reflections",
                                method: .GET),
                       as: ReflectionsListResponse.self).items
    }
}

// MARK: - Wire types (contract-exact; kept private to Networking)

private struct ReflectionCreateBody: Encodable {
    let body: String
    let mood: String?
}

private struct CreatedIdResponse: Decodable { let id: String }

private struct VisibilityResponse: Decodable {
    let id: String
    let isPublic: Bool
}

private struct ReflectionsListResponse: Decodable {
    let items: [Reflection]
}
