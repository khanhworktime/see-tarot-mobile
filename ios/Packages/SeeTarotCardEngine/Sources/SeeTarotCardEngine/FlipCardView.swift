import SwiftUI
import SeeTarotDesignSystem

// MARK: - Loader closure type

/// Cache-first image loader abstraction — matches `CardImageLoader.image(cardId:url:)`
/// without importing SeeTarotPersistence into the CardEngine module.
/// Callers (Phase 08 / CardImage.swift) bridge by wrapping the actor method.
public typealias CardImageLoaderClosure = @Sendable (String, URL?) async -> Data?

// MARK: - UIKit flip card (iOS only)

#if canImport(UIKit)
import UIKit

/// UIKit card view performing a 3D Y-axis flip via Core Animation
/// (decision 0004 — NOT Metal). Two faces; perspective transform.
/// Name label has been moved OUT — it lives below the flip frame in SwiftUI.
public final class FlipCardUIView: UIView {
    private let backView = UIView()
    private let backImageView = UIImageView()
    private let frontView = UIView()
    private let frontImageView = UIImageView()
    private(set) var faceUp = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    private func setup() {
        layer.cornerRadius = 12
        clipsToBounds = true

        // ── Back face ────────────────────────────────────────────────────────
        backView.frame = bounds
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // bg #010726 fill — artwork (back.png) overlays on top
        backView.backgroundColor = UIColor(red: 1/255, green: 7/255,
                                           blue: 38/255, alpha: 1)
        backImageView.contentMode = .scaleToFill
        backImageView.clipsToBounds = true
        backImageView.frame = backView.bounds
        backImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backView.addSubview(backImageView)
        addSubview(backView)

        // ── Front face ───────────────────────────────────────────────────────
        frontView.frame = bounds
        frontView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // bg #010726 fill — artwork overlays on top
        frontView.backgroundColor = UIColor(red: 1/255, green: 7/255,
                                            blue: 38/255, alpha: 1)
        frontImageView.contentMode = .scaleToFill
        frontImageView.clipsToBounds = true
        frontImageView.frame = frontView.bounds
        frontImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frontView.addSubview(frontImageView)
        addSubview(frontView)

        // Start face-down
        frontView.isHidden = true
    }

    /// Apply loaded image data to front/back faces and reversed state.
    func configure(frontData: Data?, backData: Data?, reversed: Bool) {
        frontImageView.image = frontData.flatMap(UIImage.init)
        frontImageView.transform = reversed
            ? CGAffineTransform(rotationAngle: .pi) : .identity
        backImageView.image = backData.flatMap(UIImage.init)
    }

    func setFaceUp(_ isFaceUp: Bool, duration: Double, reduceMotion: Bool) {
        let style = FlipDecision.style(wasFaceUp: faceUp, isFaceUp: isFaceUp,
                                       reduceMotion: reduceMotion)
        faceUp = isFaceUp
        switch style {
        case .none:
            return
        case .crossFade:
            UIView.transition(with: self, duration: duration,
                              options: .transitionCrossDissolve) {
                self.applyFace(isFaceUp)
            }
        case .threeDFlip:
            UIView.transition(with: self, duration: duration,
                              options: isFaceUp ? .transitionFlipFromLeft
                                               : .transitionFlipFromRight) {
                self.applyFace(isFaceUp)
            }
        }
    }

    private func applyFace(_ showFront: Bool) {
        frontView.isHidden = !showFront
        backView.isHidden = showFront
    }
}

// MARK: - SwiftUI representable

/// SwiftUI bridge for the flip card.
/// The glow burst is applied as a SwiftUI overlay timed to the flip midpoint
/// (duration / 2) so it peaks exactly when both faces are at 90° — the
/// visually "transparent" threshold of a Core Animation Y-flip.
public struct FlipCardView: UIViewRepresentable {
    let imageURL: URL?
    let backURL: URL?
    let faceUp: Bool
    let name: String
    let reversed: Bool
    let duration: Double
    /// Cache-first loader. Nil → placeholder only (backward-compatible).
    let loader: CardImageLoaderClosure?

    public init(
        imageURL: URL?,
        faceUp: Bool,
        name: String,
        reversed: Bool,
        duration: Double = 0.35,
        backURL: URL? = nil,
        loader: CardImageLoaderClosure? = nil
    ) {
        self.imageURL = imageURL
        self.backURL = backURL
        self.faceUp = faceUp
        self.name = name
        self.reversed = reversed
        self.duration = duration
        self.loader = loader
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> FlipCardUIView {
        let view = FlipCardUIView(
            frame: CGRect(x: 0, y: 0, width: 95, height: 155))
        // Kick off initial image load
        context.coordinator.load(front: imageURL, back: backURL,
                                 reversed: reversed, loader: loader, into: view)
        return view
    }

    public func updateUIView(_ view: FlipCardUIView, context: Context) {
        // Re-load if URLs or reversed state changed
        context.coordinator.load(front: imageURL, back: backURL,
                                 reversed: reversed, loader: loader, into: view)
        view.setFaceUp(faceUp, duration: duration,
                       reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    /// Manages async image loading so it does not fire on every SwiftUI update.
    public final class Coordinator: @unchecked Sendable {
        private var lastFrontURL: URL?
        private var lastBackURL: URL?
        private var lastReversed: Bool = false
        private var task: Task<Void, Never>?

        func load(front: URL?, back: URL?, reversed: Bool,
                  loader: CardImageLoaderClosure?,
                  into view: FlipCardUIView) {
            guard front != lastFrontURL || back != lastBackURL
                    || reversed != lastReversed else { return }
            lastFrontURL = front
            lastBackURL = back
            lastReversed = reversed
            task?.cancel()
            // Bind to the @Sendable typealias before capture to prevent the
            // "converting non-Sendable function value" diagnostic (same pattern
            // used in SpreadRitualView.dealtCardsLayer).
            let sendableLoader: CardImageLoaderClosure? = loader
            task = Task { @MainActor in
                guard let sendableLoader else {
                    view.configure(frontData: nil, backData: nil,
                                   reversed: reversed)
                    return
                }
                async let frontData = sendableLoader(
                    front.map { $0.lastPathComponent } ?? "_front_nil", front)
                let backKey = CardBackURL.cacheKey(for: front)
                async let backData  = sendableLoader(backKey, back)
                let (frontBytes, backBytes) = await (frontData, backData)
                guard !Task.isCancelled else { return }
                view.configure(frontData: frontBytes, backData: backBytes,
                               reversed: reversed)
            }
        }
    }
}

// MARK: - Glow burst overlay (SwiftUI, threeDFlip only)

/// A radial silver glow that appears at the mid-flip threshold then fades.
/// Rendered as a pure SwiftUI overlay — no Metal, no CALayer additions.
struct GlowBurstModifier: ViewModifier {
    let color: Color
    let trigger: Bool          // changes when a flip starts
    let flipDuration: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content.overlay(
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.85), color.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 48
                    )
                )
                .opacity(opacity)
                .allowsHitTesting(false)
        )
        .onChange(of: trigger) { _, _ in
            opacity = 0
            Task {
                // Wait until the flip reaches 90° (half-duration)
                try? await Task.sleep(for: .seconds(flipDuration / 2))
                withAnimation(.easeIn(duration: 0.08)) { opacity = 1 }
                try? await Task.sleep(for: .seconds(0.12))
                withAnimation(.easeOut(duration: 0.18)) { opacity = 0 }
            }
        }
    }
}

extension View {
    /// Attaches a half-flip silver glow burst; no-op when `style` is not
    /// `.threeDFlip` (reduced-motion / no state change).
    func glowBurst(
        color: Color,
        trigger: Bool,
        flipStyle: FlipStyle,
        flipDuration: Double
    ) -> some View {
        Group {
            if flipStyle == .threeDFlip {
                self.modifier(GlowBurstModifier(
                    color: color, trigger: trigger,
                    flipDuration: flipDuration))
            } else {
                self
            }
        }
    }
}

#endif // canImport(UIKit)
