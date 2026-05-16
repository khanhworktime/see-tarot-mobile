import Foundation

/// A raw Server-Sent Event frame from `POST /readings/generate` (BE doc §4).
public struct SSEEvent: Equatable, Sendable {
    public let name: String   // card | delta | done | error | message
    public let data: Data

    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
}

/// Typed payloads for the SSE event sequence: `card` → many `delta` →
/// `done` | `error` (BE doc §4).
public enum SSEPayload {
    public struct Delta: Codable, Equatable, Sendable { public let delta: String }
    public struct Done: Codable, Equatable, Sendable {
        public let readingId: String
        public let model: String?
    }
    public struct Failure: Codable, Equatable, Sendable {
        public let message: String
        public let retryable: Bool
    }
    // `card` payload decodes into the existing `ReadingCard` model.
}
