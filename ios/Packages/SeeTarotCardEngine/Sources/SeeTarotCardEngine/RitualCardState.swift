// RitualCardState.swift — SpreadRitualView data models
// Internal state types for the fan and deal phases of the ritual animation.
// Kept package-internal (no `public`) — only consumed by SpreadRitualView.

import Foundation
import SwiftUI

// MARK: - FanCardState

/// One card's position/angle in the pre-deal fan overlay.
struct FanCardState: Identifiable {
    let id: Int
    var angle: Double
    var offset: CGSize
    var opacity: Double
}

// MARK: - DealtCardState

/// One card's presentation state after it has been dealt to its slot.
struct DealtCardState: Identifiable {
    let id: Int
    let card: RitualCard
    var offset: CGSize
    var faceUp: Bool
    var opacity: Double
    var scale: CGFloat
}
