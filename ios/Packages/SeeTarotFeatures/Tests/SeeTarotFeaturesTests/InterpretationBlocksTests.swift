// InterpretationBlocksTests.swift — Phase 06
// Unit tests for InterpretationBlocks.parse(_:).
// All cases are pure (no SwiftUI / no network).

import XCTest
@testable import SeeTarotFeatures

final class InterpretationBlocksTests: XCTestCase {

    // MARK: - Empty / trivial inputs

    func testEmptyTextReturnsNoBlocks() {
        XCTAssertTrue(InterpretationBlocks.parse("").isEmpty)
    }

    func testWhitespaceOnlyReturnsNoBlocks() {
        XCTAssertTrue(InterpretationBlocks.parse("   \n  \n").isEmpty)
    }

    // MARK: - No-heading fallback (single intro block)

    func testNoHeadingYieldsIntroBlock() {
        let text = "The cards speak of change and renewal."
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].id, "-intro")
        XCTAssertEqual(blocks[0].title, "")
        XCTAssertEqual(blocks[0].body, text)
    }

    func testMultiLineNoHeadingYieldsSingleIntroBlock() {
        let text = "Line one.\nLine two.\nLine three."
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].id, "-intro")
    }

    // MARK: - Pre-heading intro block

    func testTextBeforeFirstHeadingBecomesIntroBlock() {
        let text = """
        Welcome to your reading.

        ### The Past
        Old energies linger.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[0].id, "-intro")
        XCTAssertTrue(blocks[0].body.contains("Welcome"))
        XCTAssertEqual(blocks[1].id, "the-past")
        XCTAssertEqual(blocks[1].title, "The Past")
        XCTAssertTrue(blocks[1].body.contains("Old energies"))
    }

    func testIntroBlockOmittedWhenTextStartsWithHeading() {
        let text = """
        ### The Present
        Focus on now.
        """
        let blocks = InterpretationBlocks.parse(text)
        // No pre-heading text → no intro block
        XCTAssertFalse(blocks.contains(where: { $0.id == "-intro" }))
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].title, "The Present")
    }

    // MARK: - Heading split

    func testThreeHeadingsSplitCorrectly() {
        let text = """
        ### Past
        Ancient wisdom.
        ### Present
        Current energies.
        ### Future
        What lies ahead.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0].id, "past")
        XCTAssertEqual(blocks[1].id, "present")
        XCTAssertEqual(blocks[2].id, "future")
        XCTAssertTrue(blocks[0].body.contains("Ancient wisdom"))
        XCTAssertTrue(blocks[1].body.contains("Current energies"))
        XCTAssertTrue(blocks[2].body.contains("What lies ahead"))
    }

    func testHeadingSlugIsStableAcrossReparses() {
        let text = """
        ### The High Priestess
        Intuition guides you.
        """
        let first = InterpretationBlocks.parse(text)
        let second = InterpretationBlocks.parse(text + "\n")
        XCTAssertEqual(first[0].id, second[0].id)
        XCTAssertEqual(first[0].id, "the-high-priestess")
    }

    func testHeadingSlugStripsNonAlphanumeric() {
        let text = """
        ### Strength & Courage!
        Raw power within.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 1)
        // Non-alpha chars stripped, only letters/numbers/hyphens retained
        XCTAssertFalse(blocks[0].id.contains("&"))
        XCTAssertFalse(blocks[0].id.contains("!"))
    }

    // MARK: - Partial-stream safety (no flicker on trailing partial heading)

    func testTrailingHeadingWithNoBodyIsWithheld() {
        // Simulates stream arriving up to `### The Future` but no body yet
        let partialText = """
        ### The Past
        Old energies fade.
        ### The Future
        """
        let blocks = InterpretationBlocks.parse(partialText)
        // Only "The Past" should appear; trailing heading has no body → withheld
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].id, "the-past")
    }

    func testTrailingHeadingWithBodyIsEmitted() {
        let text = """
        ### The Past
        Old energies fade.
        ### The Future
        Bright things await.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[1].id, "the-future")
        XCTAssertTrue(blocks[1].body.contains("Bright things"))
    }

    func testInProgressStreamAccumulatesStably() {
        // Simulate incremental SSE delta accumulation
        var accumulated = ""
        var previousIDs: [String] = []

        let deltas = [
            "### Card One\nThis card speaks",
            " of courage",
            " and strength.\n### Card Two\nA new path",
            " opens."
        ]

        for delta in deltas {
            accumulated += delta
            let blocks = InterpretationBlocks.parse(accumulated)
            // IDs of existing blocks must remain identical (no re-animation)
            let currentIDs = blocks.map(\.id)
            for previousID in previousIDs {
                XCTAssertTrue(currentIDs.contains(previousID),
                              "Block id '\(previousID)' disappeared during streaming")
            }
            // Monotone: count never decreases
            XCTAssertGreaterThanOrEqual(blocks.count, previousIDs.count)
            previousIDs = currentIDs
        }
    }

    // MARK: - Multiline body preservation

    func testMultilineBodyPreservedWithinBlock() {
        let text = """
        ### Reflection
        Line one of reflection.
        Line two of reflection.
        Line three of reflection.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertTrue(blocks[0].body.contains("Line one"))
        XCTAssertTrue(blocks[0].body.contains("Line three"))
    }

    // MARK: - Order stability

    func testBlockOrderMatchesTextOrder() {
        let text = """
        ### Alpha
        First.
        ### Beta
        Second.
        ### Gamma
        Third.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.map(\.id), ["alpha", "beta", "gamma"])
    }

    // MARK: - Edge: heading-only text (no body in any section)

    func testHeadingOnlyTextProducesNoBlocks() {
        // A heading with no body that is the last (and only) line → withheld
        let text = "### Lonely Heading"
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertTrue(blocks.isEmpty,
                      "Heading with no body should be withheld to prevent flicker")
    }

    // MARK: - M5: Duplicate heading slug de-duplication

    func testDuplicateHeadingsGetDistinctStableIds() {
        // AI may emit the same card name twice in a 3-card spread reading.
        let text = """
        ### Card
        First card body.
        ### Card
        Second card body.
        ### Card
        Third card body.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 3)
        let ids = blocks.map(\.id)
        // All three ids must be unique (no ForEach identity collision).
        XCTAssertEqual(Set(ids).count, 3, "Duplicate heading slugs must be disambiguated")
        // First occurrence keeps the plain slug; subsequent get -2, -3 suffix.
        XCTAssertEqual(ids[0], "card")
        XCTAssertEqual(ids[1], "card-2")
        XCTAssertEqual(ids[2], "card-3")
    }

    func testNonDuplicateHeadingsUnaffectedByDedup() {
        let text = """
        ### The Past
        Ancient wisdom.
        ### The Present
        Current energies.
        ### The Future
        Bright things await.
        """
        let blocks = InterpretationBlocks.parse(text)
        XCTAssertEqual(blocks.count, 3)
        // Non-duplicate slugs must not get numeric suffixes.
        XCTAssertEqual(blocks[0].id, "the-past")
        XCTAssertEqual(blocks[1].id, "the-present")
        XCTAssertEqual(blocks[2].id, "the-future")
    }

    func testDuplicateSlugIdsStableAcrossReparses() {
        // Same input always produces same ids regardless of how many times parsed.
        let text = """
        ### Star
        First appearance.
        ### Star
        Second appearance.
        """
        let firstParse  = InterpretationBlocks.parse(text)
        let secondParse = InterpretationBlocks.parse(text)
        let thirdParse  = InterpretationBlocks.parse(text + "\n")
        XCTAssertEqual(firstParse.map(\.id), secondParse.map(\.id),
                       "Ids must be stable across re-parses of identical text")
        XCTAssertEqual(firstParse.map(\.id), thirdParse.map(\.id),
                       "Trailing newline must not change ids")
        XCTAssertEqual(firstParse[0].id, "star")
        XCTAssertEqual(firstParse[1].id, "star-2")
    }

    func testDuplicateSlugStableUnderIncrementalStreaming() {
        // Simulate SSE stream: ids of already-emitted blocks must not change
        // as more text arrives and the second duplicate heading gets a body.
        let partial = """
        ### Card
        First card body.
        ### Card
        """
        let full = """
        ### Card
        First card body.
        ### Card
        Second card body.
        """
        let partialBlocks = InterpretationBlocks.parse(partial)
        let fullBlocks = InterpretationBlocks.parse(full)
        // Partial: only first block emitted (trailing heading withheld — no body).
        XCTAssertEqual(partialBlocks.count, 1)
        XCTAssertEqual(partialBlocks[0].id, "card")
        // Full: both blocks emitted with stable, distinct ids.
        XCTAssertEqual(fullBlocks.count, 2)
        XCTAssertEqual(fullBlocks[0].id, "card")
        XCTAssertEqual(fullBlocks[1].id, "card-2")
        // The first block's id is identical in both parses.
        XCTAssertEqual(partialBlocks[0].id, fullBlocks[0].id)
    }

    // MARK: - Intro + multiple headings full oracle simulation

    func testFullOracleTextParsesCorrectly() {
        let oracleText = """
        The stars have aligned for your reading today.

        ### Card 1 — The Fool
        New beginnings call. Step forward without fear.

        ### Card 2 — The Tower
        Sudden change disrupts — but clears the way.

        ### Card 3 — The Star
        Hope follows the storm. Renewal is certain.
        """
        let blocks = InterpretationBlocks.parse(oracleText)
        XCTAssertEqual(blocks.count, 4) // intro + 3 headed sections
        XCTAssertEqual(blocks[0].id, "-intro")
        XCTAssertTrue(blocks[0].body.contains("stars"))
        XCTAssertTrue(blocks[1].title.contains("The Fool"))
        XCTAssertTrue(blocks[2].title.contains("The Tower"))
        XCTAssertTrue(blocks[3].title.contains("The Star"))
    }
}
