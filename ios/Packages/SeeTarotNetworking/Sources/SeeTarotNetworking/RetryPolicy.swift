import Foundation
import SeeTarotCore

/// Capped exponential backoff for `429` and transient transport errors
/// (BE rate limits: 120/min global, 60/min `/auth/*`). Sleep is injectable so
/// unit tests run without real delay.
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Double
    private let sleep: @Sendable (Double) async -> Void

    public init(maxAttempts: Int = 3, baseDelay: Double = 0.5,
                sleep: @escaping @Sendable (Double) async -> Void = { secs in
                    try? await Task.sleep(nanoseconds: UInt64(secs * 1_000_000_000))
                }) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.sleep = sleep
    }

    /// `429` is always safe to retry (server rejected the request without
    /// processing it). Transport errors are only retried for idempotent
    /// requests — a lost response to a POST may have been applied server-side,
    /// so retrying could duplicate sign-up / daily-draw / reflection.
    private func isRetryable(_ error: Error, idempotent: Bool) -> Bool {
        if case APIError.rateLimited = error { return true }
        guard idempotent, let urlError = error as? URLError else { return false }
        return [.timedOut, .networkConnectionLost,
                .cannotConnectToHost].contains(urlError.code)
    }

    public func run<T>(idempotent: Bool = true,
                       _ operation: @Sendable () async throws -> T) async throws -> T {
        var attempt = 0
        while true {
            do {
                return try await operation()
            } catch {
                attempt += 1
                guard attempt < maxAttempts,
                      isRetryable(error, idempotent: idempotent)
                else { throw error }
                let delay = baseDelay * pow(2, Double(attempt - 1))
                let jitter = Double.random(in: 0...(baseDelay / 2))
                await sleep(delay + jitter)
            }
        }
    }
}
