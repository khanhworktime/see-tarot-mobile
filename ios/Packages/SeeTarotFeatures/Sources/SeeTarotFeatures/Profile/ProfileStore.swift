import Foundation
import Observation
import SeeTarotCore
import SeeTarotNetworking

/// Profile edit (E04). Seeds editable fields from the session user, tracks
/// dirty fields, mirrors BE validation, PATCHes only changed fields, then asks
/// `AuthStore` to re-hydrate the session. Personalization itself is BE-side.
@MainActor
@Observable
public final class ProfileStore {
    public enum Phase: Equatable { case idle, saving, saved,
                                        failed(String) }

    // Editable bindings (empty string ⇒ "unset" for optional fields).
    public var name: String
    public var birthDate: String
    public var timezone: String
    public var preferredIntent: String

    public private(set) var phase: Phase = .idle
    public private(set) var fieldErrors: [ProfileField: String] = [:]

    private let original: SessionUser
    private let auth: AuthStore

    public init(auth: AuthStore, user: SessionUser) {
        self.auth = auth
        self.original = user
        self.name = user.name ?? ""
        self.birthDate = user.birthDate ?? ""
        self.timezone = user.timezone ?? ""
        self.preferredIntent = user.preferredIntent ?? ""
    }

    // A field is dirty when its trimmed value differs from the original.
    private func dirty(_ value: String, _ origin: String?) -> String? {
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return t == (origin ?? "") ? nil : t
    }

    /// Only the changed fields (nil = unchanged ⇒ not sent).
    public var payload: (name: String?, birthDate: String?,
                         timezone: String?, preferredIntent: String?) {
        (dirty(name, original.name),
         dirty(birthDate, original.birthDate),
         dirty(timezone, original.timezone),
         dirty(preferredIntent, original.preferredIntent))
    }

    public var isDirty: Bool {
        let p = payload
        return p.name != nil || p.birthDate != nil || p.timezone != nil
            || p.preferredIntent != nil
    }

    public var validationErrors: [ProfileField: String] {
        let p = payload
        return ProfileValidation.errors(name: p.name, birthDate: p.birthDate,
                                        timezone: p.timezone,
                                        preferredIntent: p.preferredIntent)
    }

    public var canSave: Bool {
        if case .saving = phase { return false }
        return isDirty && validationErrors.isEmpty
    }

    public func save() async {
        guard canSave else { return }
        phase = .saving
        fieldErrors = [:]
        let p = payload
        do {
            _ = try await auth.apiClient.updateProfile(
                name: p.name, birthDate: p.birthDate, timezone: p.timezone,
                preferredIntent: p.preferredIntent)
            await auth.refreshSession()
            phase = .saved
        } catch APIError.http(let status, let envelope) where status == 400 {
            fieldErrors = Self.mapIssues(envelope)
            phase = .failed("Please fix the highlighted fields.")
        } catch APIError.unauthorized {
            // 401 routes through the sign-out seam; no inline message.
            phase = .idle
        } catch {
            phase = .failed("Could not save. Please try again.")
        }
    }

    /// Map BE Zod `issues[]` to fields by first path segment.
    private static func mapIssues(_ env: APIErrorEnvelope?)
        -> [ProfileField: String] {
        var out: [ProfileField: String] = [:]
        for issue in env?.issues ?? [] {
            guard let key = issue.path?.first,
                  let field = ProfileField(rawValue: key) else { continue }
            out[field] = issue.message ?? "Invalid value."
        }
        return out
    }
}
