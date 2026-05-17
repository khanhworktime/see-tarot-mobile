import SwiftUI

/// Production `CardSurface` — the flip card (decision 0004). On non-UIKit
/// hosts (unit-test target) it degrades to a simple view so the seam still
/// compiles; flip logic itself is tested via `FlipDecision`.
public struct RealCardSurface: CardSurface {
    let name: String
    let reversed: Bool

    public init(name: String = "", reversed: Bool = false) {
        self.name = name
        self.reversed = reversed
    }

    public func cardView(imageURL: URL?, faceUp: Bool,
                         position: Int) -> some View {
        #if canImport(UIKit)
        FlipCardView(imageURL: imageURL, faceUp: faceUp,
                     name: name, reversed: reversed)
            .frame(width: 90, height: 150)
            .accessibilityLabel("Card slot \(position), "
                + (faceUp ? "revealed \(name)" : "face down"))
        #else
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
            .frame(width: 90, height: 150)
            .accessibilityLabel("Card slot \(position)")
        #endif
    }
}
