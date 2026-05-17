import SwiftUI

/// Seam for the real card-rendering surface (draw / flip / spread layout) that
/// E02 implements (Core Animation / UIKit via `UIViewRepresentable`,
/// decision 0004). E01 defines only the contract so E02 can build without
/// reshaping the foundation. No real animation here (YAGNI).
public protocol CardSurface {
    associatedtype Body: View
    /// `faceUp` toggles the flip; `position` is the slot in the spread.
    func cardView(imageURL: URL?, faceUp: Bool, position: Int) -> Body
}

/// Placeholder surface — proves the seam compiles; replaced in E02.
public struct PlaceholderCardSurface: CardSurface {
    public init() {}
    public func cardView(imageURL: URL?, faceUp: Bool,
                         position: Int) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
            .overlay(Text(faceUp ? "★" : "?").font(.title))
            .frame(width: 80, height: 130)
            .accessibilityLabel("Card slot \(position)")
    }
}
