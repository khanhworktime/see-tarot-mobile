import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// Daily 1-card flow (BE doc §3.3). daily-today → if none, drawDaily(tz).
/// Maps entitlement / AI-failure codes to user-actionable states.
@MainActor
@Observable
public final class DailyReadingStore {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(Reading)
        case blocked(code: String)        // 403 daily_already_drawn
        case failed(retryable: Bool)      // 502 ai_failed|ai_empty
    }

    public private(set) var state: State = .idle
    private let client: APIClientProtocol
    private let timezone: String

    public init(client: APIClientProtocol,
                timezone: String = TimeZone.current.identifier) {
        self.client = client
        self.timezone = timezone
    }

    public func load() async {
        state = .loading
        do {
            if let existing = try await client.dailyToday() {
                state = .loaded(existing); return
            }
            state = .loaded(try await client.drawDaily(tz: timezone))
        } catch APIError.entitlement(let code) {
            state = .blocked(code: code)
        } catch APIError.http(let status, _) where status == 502 {
            state = .failed(retryable: true)
        } catch {
            state = .failed(retryable: true)
        }
    }
}
