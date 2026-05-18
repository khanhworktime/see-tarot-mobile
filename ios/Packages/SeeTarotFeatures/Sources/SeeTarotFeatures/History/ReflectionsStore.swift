import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// Append-only reflections journal on a reading. Client validation mirrors the
/// BE contract (`body` 3–2000 trimmed, `mood` ≤24) before POSTing.
@MainActor
@Observable
public final class ReflectionsStore {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([Reflection])          // newest-first
        case error(retryable: Bool)
    }

    public private(set) var state: State = .idle
    public private(set) var submitting = false
    /// Last client/server validation issues for the add form (empty ⇒ valid).
    public private(set) var issues: [String] = []

    private let client: APIClientProtocol
    private let readingId: String

    public init(client: APIClientProtocol, readingId: String) {
        self.client = client
        self.readingId = readingId
    }

    public func load() async {
        state = .loading
        do {
            state = .loaded(try await client.reflections(id: readingId))
        } catch {
            state = .error(retryable: true)
        }
    }

    /// Mirrors BE Zod rules. Returns issues (also stored for the UI).
    @discardableResult
    public func validate(body: String, mood: String?) -> [String] {
        var found: [String] = []
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 || trimmed.count > 2000 {
            found.append("Reflection must be 3–2000 characters.")
        }
        if let mood, mood.count > 24 {
            found.append("Mood must be 24 characters or fewer.")
        }
        issues = found
        return found
    }

    /// Validate → POST → refetch canonical list (avoids fabricating id/date).
    /// Returns true on success.
    @discardableResult
    public func add(body: String, mood: String?) async -> Bool {
        guard validate(body: body, mood: mood).isEmpty, !submitting else {
            return false
        }
        submitting = true
        defer { submitting = false }
        let cleanMood = mood?.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await client.addReflection(
                id: readingId,
                body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: (cleanMood?.isEmpty == false) ? cleanMood : nil)
            await load()
            return true
        } catch APIError.http(_, let envelope) {
            issues = envelope?.issues?.compactMap { $0.message }
                ?? ["Could not save reflection."]
            return false
        } catch {
            issues = ["Could not save reflection."]
            return false
        }
    }
}
