import Foundation
import SeeTarotCore

/// Parses Server-Sent Event lines into `SSEEvent`s (BE doc §4). Frames:
/// `event: <name>` / `data: <json>` / blank line = boundary.
public struct SSEParser: Sendable {
    private final class State { var event = "message" }

    /// Feed lines; returns an event when a `data:` line completes a frame.
    public static func event(from line: String, state: inout String) -> SSEEvent? {
        if line.hasPrefix("event:") {
            state = String(line.dropFirst(6))
                .trimmingCharacters(in: .whitespaces)
            return nil
        }
        if line.hasPrefix("data:") {
            let json = String(line.dropFirst(5))
                .trimmingCharacters(in: .whitespaces)
            let name = state
            state = "message"   // reset after the frame
            return SSEEvent(name: name, data: Data(json.utf8))
        }
        return nil
    }
}

public extension LiveAPIClient {
    /// Consume a POST SSE stream. `EventSource` libs are GET-only, so we use
    /// `URLSession.bytes(for:)`. Cancelling the task aborts server generation
    /// (stops burning quota) — caller cancels on view dismiss.
    func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var ep = endpoint
                    ep = Endpoint(path: ep.path, method: ep.method, body: ep.body,
                                  requiresAuth: ep.requiresAuth,
                                  extraHeaders: ep.extraHeaders.merging(
                                    ["Accept": "text/event-stream"]) { _, new in new })
                    let request = builder.makeRequest(ep, token: tokenStore.token)
                    let (bytes, response) = try await session.bytes(for: request)
                    handler.captureToken(from: response, into: tokenStore)
                    guard let http = response as? HTTPURLResponse else {
                        throw APIError.badResponse
                    }
                    guard (200...299).contains(http.statusCode) else {
                        if http.statusCode == 401 { throw APIError.unauthorized }
                        throw APIError.http(status: http.statusCode, envelope: nil)
                    }
                    var state = "message"
                    for try await line in bytes.lines {
                        if let event = SSEParser.event(from: line, state: &state) {
                            continuation.yield(event)
                            if event.name == "done" || event.name == "error" {
                                continuation.finish(); return
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
