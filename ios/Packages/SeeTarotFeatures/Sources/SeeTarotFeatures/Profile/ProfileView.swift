import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Profile editor (E04). Personalization is BE-side — this only manages the
/// profile fields the BE consumes. Save sends only changed fields; the
/// session refreshes via `ProfileStore` → `AuthStore.refreshSession()`.
struct ProfileView: View {
    @Environment(\.designTokens) private var tokens
    @State private var store: ProfileStore

    init(store: ProfileStore) { self._store = State(initialValue: store) }

    private static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Always include the current value so a nil / abbreviated /
    /// non-canonical session timezone still has a selectable tag (else the
    /// Picker has no match → unintended dirty / un-saveable form).
    private var timezoneOptions: [String] {
        let known = TimeZone.knownTimeZoneIdentifiers
        let current = store.timezone
        guard !current.isEmpty, !known.contains(current) else { return known }
        return [current] + known
    }

    private var birthDate: Binding<Date> {
        Binding(
            get: { Self.isoDay.date(from: store.birthDate) ?? Date() },
            set: { store.birthDate = Self.isoDay.string(from: $0) })
    }

    var body: some View {
        Form {
            Section("Display name") {
                TextField("Name", text: $store.name)
                error(.name)
            }
            Section("Birth date") {
                if store.birthDate.isEmpty {
                    // No birthDate yet — don't silently show "today" in a
                    // picker (a stray tap would write today). Require an
                    // explicit action that seeds a neutral default.
                    Button("Set birth date") {
                        store.birthDate = Self.isoDay.string(from: Date())
                    }
                } else {
                    DatePicker("Birth date", selection: birthDate,
                               displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                error(.birthDate)
            }
            Section("Timezone") {
                Picker("Timezone", selection: $store.timezone) {
                    ForEach(timezoneOptions, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                error(.timezone)
            }
            Section("Reading focus") {
                Picker("Preferred", selection: $store.preferredIntent) {
                    ForEach(IntentCopy.all, id: \.intent) { c in
                        Text(c.label).tag(c.intent.rawValue)
                    }
                }
                error(.preferredIntent)
            }
            Section {
                if case .failed(let msg) = store.phase {
                    Text(msg).foregroundStyle(.red)
                        .font(tokens.typography.caption)
                }
                if case .saved = store.phase {
                    Text("Saved.").foregroundStyle(.green)
                        .font(tokens.typography.caption)
                }
                Button {
                    Task { await store.save() }
                } label: {
                    if case .saving = store.phase {
                        ProgressView()
                    } else {
                        Text("Save changes")
                    }
                }
                .disabled(!store.canSave)
            }
        }
        .navigationTitle("Profile")
    }

    @ViewBuilder
    private func error(_ field: ProfileField) -> some View {
        if let msg = store.validationErrors[field]
            ?? store.fieldErrors[field] {
            Text(msg).foregroundStyle(.red)
                .font(tokens.typography.caption)
        }
    }
}
