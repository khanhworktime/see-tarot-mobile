import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// Oracle flow (BE doc §3.2, §4). Client-validates input, consumes the SSE
/// stream: `card` events accumulate revealed cards, `delta` events append to
/// the interpretation, `done` finalizes, `error` → retryable failure.
/// `stop()` cancels the task → stream termination aborts server generation.
@MainActor
@Observable
public final class OracleReadingStore {
    public enum State: Equatable {
        case composing
        case invalid(String)
        case revealing(cards: [ReadingCard], text: String)
        case done(readingId: String, cards: [ReadingCard], text: String)
        case failed(retryable: Bool)
        case blocked(code: String)
    }

    public private(set) var state: State = .composing
    private let client: APIClientProtocol
    private var task: Task<Void, Never>?
    private let decoder = JSONDecoder.api

    public init(client: APIClientProtocol) { self.client = client }

    /// Accumulators for the in-flight stream.
    private var cards: [ReadingCard] = []
    private var text = ""

    public func submit(_ input: ReadingInput) {
        if let error = input.clientValidationError {
            state = .invalid(error); return
        }
        cards = []
        text = ""
        state = .revealing(cards: cards, text: text)
        task = Task { [weak self] in
            guard let self else { return }
            do {
                for try await event in client.generate(input) {
                    if Task.isCancelled { return }
                    if handle(event) { return }   // true ⇒ terminal event
                }
            } catch APIError.entitlement(let code) {
                state = .blocked(code: code)
            } catch APIError.unauthorized {
                state = .failed(retryable: false)
            } catch {
                if !Task.isCancelled { state = .failed(retryable: true) }
            }
        }
    }

    /// Apply one SSE event. Returns `true` for terminal events
    /// (`done`/`error`) so the consumer loop stops.
    private func handle(_ event: SSEEvent) -> Bool {
        switch event.name {
        case "card":
            if let card = try? decoder.decode(ReadingCard.self, from: event.data) {
                cards.append(card)
                state = .revealing(cards: cards, text: text)
            }
        case "delta":
            if let d = try? decoder.decode(SSEPayload.Delta.self, from: event.data) {
                text += d.delta
                state = .revealing(cards: cards, text: text)
            }
        case "done":
            let id = (try? decoder.decode(SSEPayload.Done.self,
                                          from: event.data))?.readingId ?? ""
            state = .done(readingId: id, cards: cards, text: text)
            return true
        case "error":
            let f = try? decoder.decode(SSEPayload.Failure.self, from: event.data)
            state = .failed(retryable: f?.retryable ?? true)
            return true
        default:
            break
        }
        return false
    }

    /// Call on view dismiss — cancels the stream task, which terminates the
    /// AsyncThrowingStream and aborts server-side generation (saves quota).
    public func stop() {
        task?.cancel()
        task = nil
    }
}
