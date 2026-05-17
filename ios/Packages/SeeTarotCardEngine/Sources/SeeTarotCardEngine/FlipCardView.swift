import SwiftUI
import SeeTarotDesignSystem

#if canImport(UIKit)
import UIKit

/// UIKit card view performing a 3D Y-axis flip via Core Animation
/// (decision 0004 — NOT Metal). Two faces; perspective transform.
public final class FlipCardUIView: UIView {
    private let backView = UIView()
    private let frontView = UIView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private(set) var faceUp = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    private func setup() {
        layer.cornerRadius = 12
        clipsToBounds = true
        for v in [backView, frontView] {
            v.frame = bounds
            v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(v)
        }
        backView.backgroundColor = UIColor(
            red: 0.42, green: 0.36, blue: 0.78, alpha: 1)   // brand accent
        frontView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = frontView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frontView.addSubview(imageView)
        nameLabel.font = .preferredFont(forTextStyle: .caption1)
        nameLabel.textAlignment = .center
        nameLabel.frame = CGRect(x: 0, y: bounds.height - 22,
                                 width: bounds.width, height: 20)
        nameLabel.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        frontView.addSubview(nameLabel)
        frontView.isHidden = true
    }

    func configure(image: UIImage?, name: String, reversed: Bool) {
        imageView.image = image
        imageView.transform = reversed ? CGAffineTransform(rotationAngle: .pi)
                                       : .identity
        nameLabel.text = name
    }

    func setFaceUp(_ up: Bool, duration: Double, reduceMotion: Bool) {
        let style = FlipDecision.style(wasFaceUp: faceUp, isFaceUp: up,
                                       reduceMotion: reduceMotion)
        faceUp = up
        switch style {
        case .none:
            return
        case .crossFade:
            UIView.transition(with: self, duration: duration,
                              options: .transitionCrossDissolve) {
                self.applyFace(up)
            }
        case .threeDFlip:
            UIView.transition(with: self, duration: duration,
                              options: up ? .transitionFlipFromLeft
                                          : .transitionFlipFromRight) {
                self.applyFace(up)
            }
        }
    }

    private func applyFace(_ up: Bool) {
        frontView.isHidden = !up
        backView.isHidden = up
    }
}

/// SwiftUI bridge for the flip card.
public struct FlipCardView: UIViewRepresentable {
    let imageURL: URL?
    let faceUp: Bool
    let name: String
    let reversed: Bool
    let duration: Double

    public init(imageURL: URL?, faceUp: Bool, name: String,
                reversed: Bool, duration: Double = 0.35) {
        self.imageURL = imageURL
        self.faceUp = faceUp
        self.name = name
        self.reversed = reversed
        self.duration = duration
    }

    public func makeUIView(context: Context) -> FlipCardUIView {
        let view = FlipCardUIView(
            frame: CGRect(x: 0, y: 0, width: 90, height: 150))
        view.configure(image: nil, name: name, reversed: reversed)
        return view
    }

    public func updateUIView(_ view: FlipCardUIView, context: Context) {
        view.configure(image: view.image(for: imageURL),
                        name: name, reversed: reversed)
        view.setFaceUp(
            faceUp, duration: duration,
            reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }
}

private extension FlipCardUIView {
    /// E02 keeps artwork loading minimal; async image fetch is wired in the
    /// reading UI layer (Phase 03) which already has the cache.
    func image(for url: URL?) -> UIImage? { nil }
}
#endif
