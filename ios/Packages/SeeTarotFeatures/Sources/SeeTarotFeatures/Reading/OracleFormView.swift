import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Oracle composer: topic + spread + question. Mirrors BE validation before
/// allowing submit (readings.md). Celtic hidden. Submit closure unchanged.
/// Phase 08: Cosmic Mysticism re-skin — glass sections, palette controls.
public struct OracleFormView: View {
    @Environment(\.designTokens) private var tokens
    @State private var intent: ReadingInput.Intent = .general
    @State private var spread: ReadingInput.Spread = .single
    @State private var question = ""
    let onSubmit: (ReadingInput) -> Void

    public init(onSubmit: @escaping (ReadingInput) -> Void) {
        self.onSubmit = onSubmit
    }

    private var input: ReadingInput {
        ReadingInput(kind: .oracle, spread: spread, intent: intent,
                     question: question)
    }

    public var body: some View {
        ZStack {
            tokens.palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: tokens.spacing.md) {
                    topicSection
                    spreadSection
                    questionSection
                    validationMessage
                    submitButton
                }
                .padding(tokens.spacing.md)
            }
        }
        .navigationTitle("Oracle")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
    }

    // MARK: - Sections

    private var topicSection: some View {
        cosmicSection(title: "Topic") {
            Picker("Topic", selection: $intent) {
                ForEach(IntentCopy.all, id: \.intent) { copy in
                    Text(copy.label).tag(copy.intent)
                }
            }
            .pickerStyle(.menu)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.palette.accentBright)
            .tint(tokens.palette.accentSilver)
            .frame(minHeight: 44, alignment: .leading)

            Text(IntentCopy.copy(for: intent).detail)
                .font(tokens.typography.caption)
                .foregroundStyle(tokens.palette.accentDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var spreadSection: some View {
        cosmicSection(title: "Spread") {
            Picker("Spread", selection: $spread) {
                Text("Single").tag(ReadingInput.Spread.single)
                Text("Three").tag(ReadingInput.Spread.three)
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
        }
    }

    private var questionSection: some View {
        cosmicSection(title: "Your Question") {
            TextEditor(text: $question)
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

            HStack {
                Spacer()
                Text("\(question.count)/500")
                    .font(tokens.typography.quotaFigures)
                    .foregroundStyle(question.count > 500
                                     ? tokens.palette.accentBright
                                     : tokens.palette.accentDim)
            }
        }
    }

    @ViewBuilder
    private var validationMessage: some View {
        if let error = input.clientValidationError {
            GlassSurface {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(tokens.typography.caption)
                    .foregroundStyle(tokens.palette.accentBright)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassCard()
        }
    }

    private var submitButton: some View {
        PrimaryButton("Reveal Reading") { onSubmit(input) }
            .disabled(input.clientValidationError != nil)
    }

    // MARK: - Section builder

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
}

