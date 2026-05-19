import SwiftUI
import SeeTarotCore
import SeeTarotNetworking
import SeeTarotDesignSystem

/// Add-reflection form. Client validation mirrors BE (body 3–2000 trimmed,
/// mood ≤24) via ReflectionsStore.validate; submit disabled until valid.
/// Phase 08: Cosmic Mysticism re-skin — glass panel, palette controls. Logic untouched.
struct AddReflectionView: View {
    @Environment(\.designTokens) private var tokens
    let store: ReflectionsStore
    @State private var text = ""
    @State private var mood = ""

    private var trimmed: Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    private var valid: Bool { trimmed >= 3 && trimmed <= 2000 && mood.count <= 24 }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: tokens.spacing.sm) {
                formHeader
                textEditor
                metaRow
                validationErrors
                submitButton
            }
        }
        .glassPanel()
    }

    // MARK: - Sub-views

    private var formHeader: some View {
        HStack(spacing: tokens.spacing.sm) {
            Image(systemName: "pencil")
                .foregroundStyle(tokens.palette.accentSilver)
                .accessibilityHidden(true)
            Text("Add a Reflection")
                .font(tokens.typography.heading)
                .foregroundStyle(tokens.palette.accentBright)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textEditor: some View {
        TextEditor(text: $text)
            .frame(minHeight: 90)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tokens.palette.bgLayer2.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tokens.palette.accentSilver.opacity(0.35))
            )
    }

    private var metaRow: some View {
        HStack {
            TextField("Mood (optional)", text: $mood)
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentBright)
                .padding(tokens.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tokens.palette.bgLayer2.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(tokens.palette.accentSilver.opacity(0.3))
                )
                .frame(minHeight: 44)
            Spacer()
            Text("\(trimmed)/2000")
                .font(tokens.typography.quotaFigures)
                .foregroundStyle(trimmed > 2000
                                 ? tokens.palette.accentBright
                                 : tokens.palette.accentDim)
        }
    }

    @ViewBuilder
    private var validationErrors: some View {
        ForEach(store.issues, id: \.self) { issue in
            Label(issue, systemImage: "exclamationmark.circle")
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentBright)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var submitButton: some View {
        PrimaryButton(store.submitting ? "Saving…" : "Save Reflection") {
            Task {
                if await store.add(body: text, mood: mood.isEmpty ? nil : mood) {
                    text = ""
                    mood = ""
                }
            }
        }
        .disabled(!valid || store.submitting)
    }
}
