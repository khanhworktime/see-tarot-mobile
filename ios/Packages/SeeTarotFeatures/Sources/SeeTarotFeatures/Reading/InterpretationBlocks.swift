// InterpretationBlocks.swift — Phase 06
// Pure markdown-### block parser for streamed interpretation text.
// No SwiftUI dependency → fully unit-testable.

import Foundation

// MARK: - Block model

/// One parsed section of the oracle interpretation.
/// `id` is derived from the heading slug and is stable across re-parses of the
/// same text, enabling SwiftUI `ForEach` identity without re-animation.
public struct InterpretationBlock: Identifiable, Equatable, Sendable {
    /// Stable heading slug (lowercased, spaces→hyphens). Empty string for the
    /// pre-heading intro block (position "-intro").
    public let id: String
    /// Raw heading text (empty for the intro block).
    public let title: String
    /// Body text that follows the heading (or all text when there is no heading).
    public let body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

// MARK: - Parser

/// Pure, stateless block parser.
/// Call `parse(_:)` on every SSE delta accumulation; it is O(n) in text length
/// and produces a stable ordered array of blocks.
public enum InterpretationBlocks {

    // Regex that matches a `### ` heading at the start of a line.
    // Uses `^` with `.anchorsMatchLineEndings` so it fires per-line.
    private static let headingPrefix = "### "

    /// Parse `text` into ordered `InterpretationBlock` values.
    ///
    /// Rules:
    /// - Text before the first `###` heading → single intro block (id="-intro").
    /// - Each `### Heading` starts a new block; body = lines until next heading.
    /// - A trailing partial heading (line starts with `#` but body is empty or
    ///   the heading has no following body bytes) is withheld — not emitted —
    ///   until at least one body character follows. This prevents flicker on the
    ///   streaming boundary where `###` has just arrived.
    /// - Duplicate heading slugs are disambiguated by appending `-2`, `-3`, …
    ///   in document order so `ForEach` identity is always unique per parse.
    ///   Same input always yields the same suffixed ids (stable across re-parses).
    /// - If there are no headings at all → single block (id="-intro", no title).
    ///
    /// - Parameter text: The accumulated SSE interpretation string (may be partial).
    /// - Returns: Ordered array of blocks ready for display.
    public static func parse(_ text: String) -> [InterpretationBlock] {
        guard !text.isEmpty else { return [] }

        let lines = text.components(separatedBy: "\n")
        var blocks: [InterpretationBlock] = []
        /// Tracks how many times each base slug has been used, for de-duplication.
        var slugOccurrences: [String: Int] = [:]

        // Current accumulator
        var currentTitle: String = ""
        var currentIsIntro: Bool = true
        var bodyLines: [String] = []
        /// Set to true the first time a heading line is encountered.
        var headingEncountered: Bool = false

        func flush(isLast: Bool) {
            let bodyText = bodyLines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Withhold a trailing heading that has no body yet (partial-stream guard).
            if isLast && bodyText.isEmpty && !currentIsIntro { return }

            let blockID: String
            if currentIsIntro {
                blockID = "-intro"
            } else {
                // De-duplicate: first occurrence keeps the plain slug;
                // subsequent occurrences append -2, -3, … in document order.
                let base = slug(from: currentTitle)
                let count = (slugOccurrences[base] ?? 0) + 1
                slugOccurrences[base] = count
                blockID = count == 1 ? base : "\(base)-\(count)"
            }

            // Only emit if there is a non-empty body.
            if !bodyText.isEmpty {
                blocks.append(InterpretationBlock(id: blockID,
                                                  title: currentTitle,
                                                  body: bodyText))
            }
        }

        for (lineIndex, line) in lines.enumerated() {
            let isLastLine = lineIndex == lines.count - 1

            if line.hasPrefix(headingPrefix) {
                flush(isLast: false)
                currentTitle = String(line.dropFirst(headingPrefix.count))
                    .trimmingCharacters(in: .whitespaces)
                currentIsIntro = false
                headingEncountered = true
                bodyLines = []
            } else if line.hasPrefix("##") && line.contains(" ") {
                // Tolerate ## or #### variants that aren't exactly ###.
                let stripped = line.drop(while: { $0 == "#" })
                    .trimmingCharacters(in: .whitespaces)
                if !stripped.isEmpty {
                    flush(isLast: false)
                    currentTitle = stripped
                    currentIsIntro = false
                    headingEncountered = true
                    bodyLines = []
                } else {
                    bodyLines.append(line)
                }
            } else {
                bodyLines.append(line)
            }

            if isLastLine { flush(isLast: true) }
        }

        // Edge: pure body text with no headings at all → single intro block.
        if blocks.isEmpty && !headingEncountered
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let bodyText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            blocks.append(InterpretationBlock(id: "-intro", title: "", body: bodyText))
        }

        return blocks
    }

    // MARK: - Helpers

    /// Convert heading text to a URL-slug-style stable id.
    private static func slug(from heading: String) -> String {
        heading
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}
