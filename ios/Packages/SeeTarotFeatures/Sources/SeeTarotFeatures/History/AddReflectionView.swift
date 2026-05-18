import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Add-reflection form. Client validation mirrors BE (body 3–2000 trimmed,
/// mood ≤24) via `ReflectionsStore.validate`; submit disabled until valid.
/// Append-only — no edit/delete.
struct AddReflectionView: View {
    @Environment(\.designTokens) private var tokens
    let store: ReflectionsStore
    @State private var text = ""
    @State private var mood = ""

    private var trimmed: Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    private var valid: Bool { trimmed >= 3 && trimmed <= 2000
        && mood.count <= 24 }

    var body: some View {
        VStack(alignment: .leading, spacing: tokens.spacing.sm) {
            Text("Add a reflection").font(tokens.typography.heading)
            TextEditor(text: $text)
                .frame(minHeight: 90)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3)))
            HStack {
                TextField("Mood (optional)", text: $mood)
                Spacer()
                Text("\(trimmed)/2000")
                    .font(tokens.typography.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(store.issues, id: \.self) { issue in
                Text(issue).font(tokens.typography.caption)
                    .foregroundStyle(.red)
            }
            PrimaryButton(store.submitting ? "Saving…" : "Save reflection") {
                Task {
                    if await store.add(
                        body: text,
                        mood: mood.isEmpty ? nil : mood) {
                        text = ""; mood = ""
                    }
                }
            }
            .disabled(!valid || store.submitting)
        }
        .padding(tokens.spacing.sm)
    }
}
