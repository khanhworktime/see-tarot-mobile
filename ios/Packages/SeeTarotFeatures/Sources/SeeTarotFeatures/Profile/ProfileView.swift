import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Profile editor (E04). Phase 08: Cosmic Mysticism re-skin — glass sections,
/// palette typography, styled save/sign-out. Store/validation/navigation untouched.
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
    /// non-canonical session timezone still has a selectable tag.
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
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: tokens.spacing.md) {
                    displayNameSection
                    birthDateSection
                    timezoneSection
                    readingFocusSection
                    saveSection
                }
                .padding(tokens.spacing.md)
            }
        }
        .navigationTitle("Profile")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
    }

    // MARK: - Sections

    private var displayNameSection: some View {
        cosmicSection(title: "Display Name") {
            cosmicTextField("Name", text: $store.name)
            #if os(iOS)
                .textContentType(.name)
            #endif
            fieldError(.name)
        }
    }

    private var birthDateSection: some View {
        cosmicSection(title: "Birth Date") {
            if store.birthDate.isEmpty {
                Button("Set Birth Date") {
                    store.birthDate = Self.isoDay.string(from: Date())
                }
                .font(tokens.typography.body)
                .foregroundStyle(tokens.palette.accentSilver)
                .frame(minHeight: 44, alignment: .leading)
            } else {
                DatePicker("Birth date", selection: birthDate,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .frame(minHeight: 44)
            }
            fieldError(.birthDate)
        }
    }

    private var timezoneSection: some View {
        cosmicSection(title: "Timezone") {
            Picker("Timezone", selection: $store.timezone) {
                ForEach(timezoneOptions, id: \.self) {
                    Text($0).tag($0)
                        .foregroundStyle(tokens.palette.accentBright)
                }
            }
#if os(iOS)
            .pickerStyle(.navigationLink)
#endif
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .frame(minHeight: 44)
            fieldError(.timezone)
        }
    }

    private var readingFocusSection: some View {
        cosmicSection(title: "Reading Focus") {
            Picker("Preferred", selection: $store.preferredIntent) {
                ForEach(IntentCopy.all, id: \.intent) { copy in
                    Text(copy.label).tag(copy.intent.rawValue)
                        .foregroundStyle(tokens.palette.accentBright)
                }
            }
#if os(iOS)
            .pickerStyle(.navigationLink)
#endif
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .frame(minHeight: 44)
            fieldError(.preferredIntent)
        }
    }

    private var saveSection: some View {
        GlassSurface {
            VStack(spacing: tokens.spacing.sm) {
                phaseMessage
                Button {
                    Task { await store.save() }
                } label: {
                    Group {
                        if case .saving = store.phase {
                            ProgressView()
                                .tint(tokens.palette.accentBright)
                        } else {
                            Text("Save Changes")
                                .font(tokens.typography.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, tokens.spacing.xs)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tokens.palette.accentSilver.opacity(store.canSave ? 0.2 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(tokens.palette.accentSilver.opacity(0.45))
                )
                .foregroundStyle(tokens.palette.accentBright)
                .disabled(!store.canSave)
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    @ViewBuilder
    private var phaseMessage: some View {
        if case .failed(let msg) = store.phase {
            Label(msg, systemImage: "exclamationmark.circle")
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentBright)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if case .saved = store.phase {
            Label("Changes saved.", systemImage: "checkmark.circle")
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentSilver)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func fieldError(_ field: ProfileField) -> some View {
        if let msg = store.validationErrors[field] ?? store.fieldErrors[field] {
            Text(msg)
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentBright)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func cosmicSection(title: String,
                                @ViewBuilder content: () -> some View) -> some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.sm) {
                Text(title)
                    .font(tokens.typography.caption)
                    .foregroundStyle(tokens.palette.accentDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                content()
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func cosmicTextField(_ placeholder: String,
                                 text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .padding(tokens.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tokens.palette.bgLayer2.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.35))
            )
            .frame(minHeight: 44)
    }
}
