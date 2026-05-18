import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// Reading history (`GET /readings`) — cursor-paginated, newest-first.
/// 401 flows through `ResponseHandler`'s sign-out seam (not caught here).
@MainActor
@Observable
public final class HistoryStore {
    public enum State: Equatable {
        case idle
        case loading                       // first page in flight
        case empty                         // loaded, zero rows
        case loaded([HistoryPage.Row])     // has rows; more may exist
        case paging([HistoryPage.Row])     // appending next page
        case end([HistoryPage.Row])        // loaded, no more pages
        case error(retryable: Bool)
    }

    public private(set) var state: State = .idle
    private var nextCursor: String?
    private let client: APIClientProtocol
    private let limit: Int

    public init(client: APIClientProtocol, limit: Int = 20) {
        self.client = client
        self.limit = limit
    }

    /// Current rows regardless of phase (UI convenience).
    public var rows: [HistoryPage.Row] {
        switch state {
        case .loaded(let r), .paging(let r), .end(let r): return r
        default: return []
        }
    }

    public func loadFirst() async {
        state = .loading
        nextCursor = nil
        do {
            let page = try await client.history(cursor: nil, limit: limit)
            apply(page, existing: [])
        } catch {
            state = .error(retryable: true)
        }
    }

    public func loadMore() async {
        guard case .loaded(let rows) = state, let cursor = nextCursor else {
            return   // only page from a settled .loaded with a cursor
        }
        state = .paging(rows)
        do {
            let page = try await client.history(cursor: cursor, limit: limit)
            apply(page, existing: rows)
        } catch {
            state = .error(retryable: true)
        }
    }

    private func apply(_ page: HistoryPage, existing: [HistoryPage.Row]) {
        let merged = existing + page.items
        nextCursor = page.nextCursor
        if merged.isEmpty {
            state = .empty
        } else if page.nextCursor == nil {
            state = .end(merged)
        } else {
            state = .loaded(merged)
        }
    }
}
