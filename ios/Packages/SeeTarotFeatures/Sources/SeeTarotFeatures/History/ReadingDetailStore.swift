import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// One past reading (`GET /readings/{id}`) + owner visibility toggle
/// (`PATCH /readings/{id}`). 404 ⇒ friendly not-found (not an error state).
@MainActor
@Observable
public final class ReadingDetailStore {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(Reading)
        case notFound
        case error(retryable: Bool)
    }

    public private(set) var state: State = .idle
    public private(set) var togglingVisibility = false
    private let client: APIClientProtocol

    public init(client: APIClientProtocol) {
        self.client = client
    }

    public func load(id: String) async {
        state = .loading
        do {
            state = .loaded(try await client.reading(id: id))
        } catch APIError.http(let status, _) where status == 404 {
            state = .notFound
        } catch {
            state = .error(retryable: true)
        }
    }

    /// Owner-only. No-ops unless a reading is loaded; updates local state from
    /// the server's authoritative `isPublic`.
    public func toggleVisibility() async {
        guard case .loaded(let reading) = state, !togglingVisibility else {
            return
        }
        togglingVisibility = true
        defer { togglingVisibility = false }
        do {
            let now = try await client.setVisibility(
                id: reading.id, isPublic: !reading.isPublic)
            state = .loaded(reading.with(isPublic: now))
        } catch {
            // Keep the existing reading; surface a transient flag-free failure
            // by leaving state unchanged (UI re-enables the toggle).
        }
    }
}

private extension Reading {
    func with(isPublic newValue: Bool) -> Reading {
        Reading(id: id, userId: userId, kind: kind, spread: spread,
                intent: intent, question: question,
                interpretation: interpretation, model: model, tier: tier,
                isPublic: newValue, createdAt: createdAt, cards: cards,
                reflections: reflections, isOwner: isOwner)
    }
}
