import SwiftUI
import SeeTarotCore
import SeeTarotDesignSystem

/// Oracle composer: topic + spread + question. Mirrors BE validation before
/// allowing submit (readings.md). `celtic` hidden.
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
        Form {
            Section("Topic") {
                Picker("Topic", selection: $intent) {
                    ForEach(IntentCopy.all, id: \.intent) { copy in
                        Text(copy.label).tag(copy.intent)
                    }
                }
                Text(IntentCopy.copy(for: intent).detail)
                    .font(tokens.typography.caption)
                    .foregroundStyle(tokens.palette.textSecondary)
            }
            Section("Spread") {
                Picker("Spread", selection: $spread) {
                    Text("Single").tag(ReadingInput.Spread.single)
                    Text("Three").tag(ReadingInput.Spread.three)
                }
                .pickerStyle(.segmented)
            }
            Section("Your question") {
                TextEditor(text: $question).frame(minHeight: 90)
                Text("\(question.count)/500")
                    .font(tokens.typography.caption)
                    .foregroundStyle(question.count > 500
                                     ? .red : tokens.palette.textSecondary)
            }
            if let error = input.clientValidationError {
                Text(error).font(tokens.typography.caption).foregroundStyle(.red)
            }
            PrimaryButton("Reveal reading") { onSubmit(input) }
                .disabled(input.clientValidationError != nil)
        }
        .navigationTitle("Oracle")
    }
}
