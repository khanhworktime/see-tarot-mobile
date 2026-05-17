import Foundation
import SeeTarotCore

/// Reading endpoints (BE doc §3.2–3.3, §4). Reuses `perform`/`stream` from
/// the core client; daily-today maps an empty `204` body to `nil`.
public extension LiveAPIClient {
    func dailyToday() async throws -> Reading? {
        let data = try await perform(Endpoint(path: "readings/daily-today",
                                              method: .GET))
        if data.isEmpty { return nil }            // 204 No Content
        do { return try decoder.decode(Reading.self, from: data) }
        catch { throw APIError.decoding(String(describing: error)) }
    }

    func drawDaily(tz: String) async throws -> Reading {
        let endpoint = Endpoint(
            path: "readings/daily", method: .POST,
            body: try encoder.encode(["tz": tz]))
        return try await send(endpoint, as: Reading.self)
    }

    func quota() async throws -> Quota {
        try await send(Endpoint(path: "quota", method: .GET), as: Quota.self)
    }

    func generate(_ input: ReadingInput) -> AsyncThrowingStream<SSEEvent, Error> {
        let body = try? encoder.encode(input)
        return stream(Endpoint(path: "readings/generate", method: .POST,
                               body: body))
    }
}
