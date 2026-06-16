import XCTest
@testable import SeeTarotCardEngine

final class SpreadLayoutTests: XCTestCase {

    // Standard container: iPhone 14 Pro width, generous height
    private let container = CGRect(x: 0, y: 0, width: 390, height: 500)

    // MARK: - One-card layout

    func testOneCardSlotCount() {
        let slots = SpreadLayout.slots(count: 1, in: container)
        XCTAssertEqual(slots.count, 1)
    }

    func testOneCardPositionIndex() {
        let slots = SpreadLayout.slots(count: 1, in: container)
        XCTAssertEqual(slots[0].position, 0)
    }

    func testOneCardFrameSize() {
        let slots = SpreadLayout.slots(count: 1, in: container)
        let frame = slots[0].frame
        XCTAssertEqual(frame.width, SpreadLayout.cardWidth)
        XCTAssertEqual(frame.height, SpreadLayout.cardHeight)
    }

    func testOneCardIsCentredHorizontally() {
        let slots = SpreadLayout.slots(count: 1, in: container)
        let frame = slots[0].frame
        let expectedMidX = container.midX
        XCTAssertEqual(frame.midX, expectedMidX, accuracy: 0.5)
    }

    func testOneCardIsCentredVertically() {
        let slots = SpreadLayout.slots(count: 1, in: container)
        let frame = slots[0].frame
        let expectedMidY = container.midY
        XCTAssertEqual(frame.midY, expectedMidY, accuracy: 0.5)
    }

    // MARK: - Three-card layout

    func testThreeCardSlotCount() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        XCTAssertEqual(slots.count, 3)
    }

    func testThreeCardPositionIndices() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        XCTAssertEqual(slots.map(\.position), [0, 1, 2])
    }

    func testThreeCardFrameSizes() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        for slot in slots {
            XCTAssertEqual(slot.frame.width, SpreadLayout.cardWidth,
                           "Card \(slot.position) width mismatch")
            XCTAssertEqual(slot.frame.height, SpreadLayout.cardHeight,
                           "Card \(slot.position) height mismatch")
        }
    }

    func testThreeCardRowIsCentredHorizontally() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        let leftEdge  = slots[0].frame.minX
        let rightEdge = slots[2].frame.maxX
        let rowCentreX = (leftEdge + rightEdge) / 2
        XCTAssertEqual(rowCentreX, container.midX, accuracy: 0.5,
                       "3-card row should be centred in container")
    }

    func testThreeCardRowIsCentredVertically() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        for slot in slots {
            XCTAssertEqual(slot.frame.midY, container.midY, accuracy: 0.5,
                           "Card \(slot.position) should be centred vertically")
        }
    }

    func testThreeCardHorizontalSpacing() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        let gap01 = slots[1].frame.minX - slots[0].frame.maxX
        let gap12 = slots[2].frame.minX - slots[1].frame.maxX
        XCTAssertEqual(gap01, SpreadLayout.cardGap, accuracy: 0.5,
                       "Gap between card 0→1 should equal cardGap")
        XCTAssertEqual(gap12, SpreadLayout.cardGap, accuracy: 0.5,
                       "Gap between card 1→2 should equal cardGap")
    }

    func testThreeCardLeftToRightOrder() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        XCTAssertLessThan(slots[0].frame.minX, slots[1].frame.minX,
                          "Card 0 must be left of card 1")
        XCTAssertLessThan(slots[1].frame.minX, slots[2].frame.minX,
                          "Card 1 must be left of card 2")
    }

    func testThreeCardFramesDoNotOverlap() {
        let slots = SpreadLayout.slots(count: 3, in: container)
        XCTAssertFalse(slots[0].frame.intersects(slots[1].frame),
                       "Card 0 and 1 frames should not overlap")
        XCTAssertFalse(slots[1].frame.intersects(slots[2].frame),
                       "Card 1 and 2 frames should not overlap")
    }

    // MARK: - Unsupported counts

    func testZeroCountReturnsEmpty() {
        let slots = SpreadLayout.slots(count: 0, in: container)
        XCTAssertTrue(slots.isEmpty)
    }

    func testUnsupportedCountReturnsEmpty() {
        let slots = SpreadLayout.slots(count: 5, in: container)
        XCTAssertTrue(slots.isEmpty, "Count 5 is not a supported spread in v1")
    }

    func testNegativeCountReturnsEmpty() {
        let slots = SpreadLayout.slots(count: -1, in: container)
        XCTAssertTrue(slots.isEmpty)
    }

    // MARK: - Celtic (defined but hidden)

    func testCelticSlotCount() {
        let slots = SpreadLayout.slots(count: 10, in: container)
        XCTAssertEqual(slots.count, 10, "Celtic cross must produce exactly 10 slots")
    }

    func testCelticSlotPositionIndices() {
        let slots = SpreadLayout.slots(count: 10, in: container)
        let positions = slots.map(\.position)
        XCTAssertEqual(positions, Array(0 ..< 10))
    }

    func testCelticSlotFrameSizes() {
        let slots = SpreadLayout.slots(count: 10, in: container)
        for slot in slots {
            XCTAssertEqual(slot.frame.width, SpreadLayout.cardWidth,
                           "Celtic slot \(slot.position) width mismatch")
            XCTAssertEqual(slot.frame.height, SpreadLayout.cardHeight,
                           "Celtic slot \(slot.position) height mismatch")
        }
    }

    // MARK: - SpreadSlot Equatable

    func testSpreadSlotEquatableSameValues() {
        let frame = CGRect(x: 10, y: 20, width: 95, height: 155)
        let slotA = SpreadSlot(position: 0, frame: frame)
        let slotB = SpreadSlot(position: 0, frame: frame)
        XCTAssertEqual(slotA, slotB)
    }

    func testSpreadSlotEquatableDifferentPosition() {
        let frame = CGRect(x: 10, y: 20, width: 95, height: 155)
        let slotA = SpreadSlot(position: 0, frame: frame)
        let slotB = SpreadSlot(position: 1, frame: frame)
        XCTAssertNotEqual(slotA, slotB)
    }

    // MARK: - Constants sanity

    func testCardDimensionConstants() {
        XCTAssertEqual(SpreadLayout.cardWidth,  95)
        XCTAssertEqual(SpreadLayout.cardHeight, 155)
        XCTAssertGreaterThan(SpreadLayout.cardGap, 0)
    }

    // MARK: - Narrow container (smaller than 3-card row)

    func testThreeCardLayoutInNarrowContainer() {
        // Container narrower than 3-card row — slots still returned; caller clips if needed
        let narrow = CGRect(x: 0, y: 0, width: 200, height: 400)
        let slots = SpreadLayout.slots(count: 3, in: narrow)
        XCTAssertEqual(slots.count, 3,
                       "Layout returns slots even if they extend beyond container")
        // Spacing still correct despite overflow
        let gap = slots[1].frame.minX - slots[0].frame.maxX
        XCTAssertEqual(gap, SpreadLayout.cardGap, accuracy: 0.5)
    }
}
