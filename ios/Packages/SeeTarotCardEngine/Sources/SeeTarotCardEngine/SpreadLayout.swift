import CoreGraphics

// MARK: - SpreadSlot

/// A single slot in a tarot spread — its position index and the CGRect
/// it occupies within the given container bounds.
public struct SpreadSlot: Sendable, Equatable {
    /// Zero-based position index (L→R for 1/3-card; celtic has distinct ordering).
    public let position: Int
    /// Frame in container-local coordinates.
    public let frame: CGRect

    public init(position: Int, frame: CGRect) {
        self.position = position
        self.frame = frame
    }
}

// MARK: - SpreadKind

/// Spread variants. Celtic is defined for data-driven completeness but
/// **not surfaced to the user** in v1 (no entry point exists).
public enum SpreadKind: Sendable {
    case oneCard
    case threeCard
    case celtic   // defined but hidden — v1 placeholder
}

// MARK: - SpreadLayout

/// Pure, stateless layout calculator. All methods are free of SwiftUI or UIKit.
/// Suitable for unit testing without a rendering host.
///
/// Card frame size: 95×155 pt (matches `RealCardSurface` / Phase 04 contract).
/// Horizontal gap between cards: 16 pt (`.spacing.md` equivalent).
public enum SpreadLayout {

    // MARK: Constants

    /// Standard card width per Phase-04 contract.
    public static let cardWidth: CGFloat  = 95
    /// Standard card height per Phase-04 contract.
    public static let cardHeight: CGFloat = 155
    /// Horizontal gap between adjacent cards.
    public static let cardGap: CGFloat    = 16

    // MARK: Public API

    /// Compute spread slot frames for `count` cards within `container`.
    ///
    /// - Parameters:
    ///   - count: Number of cards (1 or 3 in v1; 10 maps to `.celtic`).
    ///   - container: Bounding rectangle (the available canvas in points).
    /// - Returns: Array of `SpreadSlot` ordered L→R (position 0 = leftmost).
    ///   Returns an empty array for unsupported counts (celtic hidden).
    public static func slots(count: Int, in container: CGRect) -> [SpreadSlot] {
        switch count {
        case 1:  return oneCardSlots(in: container)
        case 3:  return threeCardSlots(in: container)
        case 10: return celticSlots(in: container)  // defined, not surfaced
        default: return []
        }
    }

    // MARK: - One-card layout

    /// Single card centred horizontally and vertically in the container.
    private static func oneCardSlots(in container: CGRect) -> [SpreadSlot] {
        let originX = container.midX - cardWidth / 2
        let originY = container.midY - cardHeight / 2
        let frame = CGRect(x: originX, y: originY, width: cardWidth, height: cardHeight)
        return [SpreadSlot(position: 0, frame: frame)]
    }

    // MARK: - Three-card layout

    /// Three cards centred as a horizontal row, evenly spaced, vertically centred.
    private static func threeCardSlots(in container: CGRect) -> [SpreadSlot] {
        let totalWidth = cardWidth * 3 + cardGap * 2
        let startX = container.midX - totalWidth / 2
        let originY = container.midY - cardHeight / 2

        return (0 ..< 3).map { index in
            let originX = startX + CGFloat(index) * (cardWidth + cardGap)
            let frame = CGRect(x: originX, y: originY, width: cardWidth, height: cardHeight)
            return SpreadSlot(position: index, frame: frame)
        }
    }

    // MARK: - Celtic cross layout (v1 hidden — not surfaced)

    /// 10-card Celtic Cross slot map. Positions follow the traditional
    /// left-to-right/top-to-bottom reading order used by most digital tarot apps.
    /// The layout is NOT accessible from the UI in v1.
    ///
    /// Slot positions:
    /// ```
    ///  0 = Significator (centre)
    ///  1 = Crossing card (overlaid, rotated 90°)
    ///  2 = Foundation (below centre)
    ///  3 = Recent past (left)
    ///  4 = Crown (above centre)
    ///  5 = Near future (right)
    ///  6-9 = Staff column (bottom-to-top, right side)
    /// ```
    private static func celticSlots(in container: CGRect) -> [SpreadSlot] {
        let centreX = container.midX - cardWidth / 2
        let centreY = container.midY - cardHeight / 2
        let step = cardHeight + cardGap

        // Cross cluster
        let cross: [(x: CGFloat, y: CGFloat)] = [
            (centreX, centreY),                            // 0: significator
            (centreX, centreY),                            // 1: crossing (same pos, rotated by caller)
            (centreX, centreY + step),                     // 2: foundation
            (centreX - (cardWidth + cardGap), centreY),    // 3: recent past
            (centreX, centreY - step),                     // 4: crown
            (centreX + (cardWidth + cardGap), centreY)     // 5: near future
        ]

        // Staff column — 4 cards stacked right side, bottom to top
        let staffX = centreX + 2 * (cardWidth + cardGap)
        let staffBase = centreY + step * 1.5
        let staff: [(x: CGFloat, y: CGFloat)] = (0 ..< 4).map { idx in
            (staffX, staffBase - CGFloat(idx) * step)
        }

        let allPositions = cross + staff
        return allPositions.enumerated().map { index, pos in
            SpreadSlot(
                position: index,
                frame: CGRect(x: pos.x, y: pos.y, width: cardWidth, height: cardHeight)
            )
        }
    }
}
