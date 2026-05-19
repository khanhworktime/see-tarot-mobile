// RitualTimeline.swift — SpreadRitualView animation timeline helpers
// Extracted from SpreadRitualView to keep that file within the 400-LOC limit.
// All functions are package-internal; behavior is identical to the original.

import SwiftUI
import SeeTarotDesignSystem

// MARK: - Fan layout builder

/// Computes the initial and animated `FanCardState` array for the fan phase.
enum RitualFanLayout {

    /// Returns the start states (opacity 0, centred) for `count` fan cards.
    static func initialStates(count: Int) -> [FanCardState] {
        let safeCount = max(count, 1)
        let angleStep: Double = safeCount > 1 ? 8.0 : 0.0
        let totalAngle = angleStep * Double(safeCount - 1)
        let startAngle = -totalAngle / 2

        return (0 ..< safeCount).map { idx in
            FanCardState(
                id: idx,
                angle: startAngle + angleStep * Double(idx),
                offset: .zero,
                opacity: 0
            )
        }
    }

    /// Applies the arc fan offsets to `states` (passed by reference).
    static func applyFanOffsets(_ states: [FanCardState]) -> [FanCardState] {
        let safeCount = max(states.count, 1)
        let angleStep: Double = safeCount > 1 ? 8.0 : 0.0
        let totalAngle = angleStep * Double(safeCount - 1)
        let startAngle = -totalAngle / 2

        return states.enumerated().map { idx, state in
            let angle = startAngle + angleStep * Double(idx)
            let radian = angle * .pi / 180
            let fanRadius: Double = 60
            let offsetX = sin(radian) * fanRadius
            let offsetY = -abs(cos(radian)) * fanRadius * 0.3
            return FanCardState(
                id: state.id,
                angle: angle,
                offset: CGSize(width: offsetX, height: offsetY),
                opacity: 1.0
            )
        }
    }
}

// MARK: - Deal layout builder

/// Maps `RitualCard` values to initial `DealtCardState` values placed at the
/// deck centre, ready for the deal animation.
enum RitualDealLayout {

    /// Returns dealt card states positioned at deck centre (pre-deal).
    static func initialStates(
        cards: [RitualCard],
        slots: [SpreadSlot],
        containerSize: CGSize
    ) -> [DealtCardState] {
        cards.enumerated().map { idx, card in
            DealtCardState(
                id: idx,
                card: card,
                offset: .zero,
                faceUp: false,
                opacity: 0,
                scale: 0.85
            )
        }
    }

    /// Returns dealt card states at their final slot positions (reduced-motion path).
    static func finalStates(
        cards: [RitualCard],
        slots: [SpreadSlot],
        containerSize: CGSize
    ) -> [DealtCardState] {
        cards.enumerated().map { idx, card in
            let centreX = containerSize.width / 2
            let centreY = containerSize.height / 2
            let slot = idx < slots.count ? slots[idx] : nil
            let offsetX = (slot?.frame.midX ?? centreX) - centreX
            let offsetY = (slot?.frame.midY ?? centreY) - centreY
            return DealtCardState(
                id: idx,
                card: card,
                offset: CGSize(width: offsetX, height: offsetY),
                faceUp: false,
                opacity: 0,
                scale: 1.0
            )
        }
    }

    /// Computes the slot-centre offset from the container centre for one slot.
    static func slotOffset(slot: SpreadSlot, containerSize: CGSize) -> CGSize {
        let centreX = containerSize.width / 2
        let centreY = containerSize.height / 2
        return CGSize(
            width: slot.frame.midX - centreX,
            height: slot.frame.midY - centreY
        )
    }
}
