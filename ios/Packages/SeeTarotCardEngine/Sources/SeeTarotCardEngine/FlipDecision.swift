import Foundation

/// Pure, testable decision for how a card transition should animate.
/// Extracted so host `swift test` covers the logic without UIKit.
public enum FlipStyle: Equatable, Sendable {
    case threeDFlip      // full Core Animation Y-axis flip
    case crossFade       // reduced-motion accessibility fallback
    case none            // no state change
}

public enum FlipDecision {
    /// `reduceMotion` mirrors `UIAccessibility.isReduceMotionEnabled`.
    public static func style(wasFaceUp: Bool, isFaceUp: Bool,
                             reduceMotion: Bool) -> FlipStyle {
        guard wasFaceUp != isFaceUp else { return .none }
        return reduceMotion ? .crossFade : .threeDFlip
    }
}
