// FloatingCardsBackground.swift — CardEngine / Phase 09-Pass2 (Visual Tuning)
//
// Three CeremonialCardFace instances in a ZStack, scattered with 3D angles
// and SUPER SLOW continuous drift/rotation via TimelineView(.animation).
// Each card has an independent phase offset so they never sync.
//
// Pass 2 changes:
//   - Card opacity: 0.55 → per-slot values 0.75–0.90 (form-occluded card stays 0.55).
//   - Scales bumped: 1.0 / 1.15 / 1.3 (was 0.9 / 1.1 / 1.3).
//   - Upper-left card repositioned to x:0.82 → x:0.85 to peek past the form panel edge.
//   - Reduced-motion path: static, no breathing or drift.

import SwiftUI
import SeeTarotDesignSystem

// MARK: - Card layout descriptor (internal)

private struct CardSlot: Sendable {
    let kind: CeremonialFaceKind
    /// Fractional anchor in 0–1 space (multiplied by geometry at render).
    let anchorX: CGFloat
    let anchorY: CGFloat
    /// Base display scale.
    let scale: CGFloat
    /// Static 3D rotation angles (degrees) applied even in reduced-motion.
    let rotX: Double
    let rotY: Double
    let rotZ: Double
    /// Phase offset (0–1) into the drift/rotation cycle.
    let phaseOffset: Double
    /// Drift period in seconds.
    let driftPeriod: Double
    /// Rotation period in seconds.
    let spinPeriod: Double
    /// Render opacity — higher for cards visible beside/above the form panel.
    let opacity: Double
}

// Upper-corner card: peeks into the top-right corner past the form edge.
// Centre-right card: clearly visible beside the form at mid-height.
// Lower card: largest, sits below the form, fully visible.
private let defaultSlots: [CardSlot] = [
    CardSlot(kind: .back, anchorX: 0.85, anchorY: 0.20,
             scale: 1.15, rotX: 12, rotY: -18, rotZ: -8,
             phaseOffset: 0.0, driftPeriod: 18, spinPeriod: 22,
             opacity: 0.88),               // top-corner peek — high pop
    CardSlot(kind: .face(BundledCard.theStar), anchorX: 0.80, anchorY: 0.45,
             scale: 1.0, rotX: -8, rotY: 20, rotZ: 6,
             phaseOffset: 0.37, driftPeriod: 15, spinPeriod: 19,
             opacity: 0.78),               // mid-right beside form
    CardSlot(kind: .face(BundledCard.theMoon), anchorX: 0.42, anchorY: 0.80,
             scale: 1.3, rotX: 10, rotY: -10, rotZ: 4,
             phaseOffset: 0.65, driftPeriod: 20, spinPeriod: 14,
             opacity: 0.55)                // lower-centre, partially behind form
]

// MARK: - FloatingCardsBackground

/// Background layer of three floating ceremonial card faces.
/// Place behind content in a ZStack; use `.ignoresSafeArea()` on the container.
public struct FloatingCardsBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let kinds: [CeremonialFaceKind]

    /// - Parameter kinds: Card kinds in display order (back → front).
    ///   Must have exactly 3 elements; extras are ignored, missing use defaults.
    public init(kinds: [CeremonialFaceKind] = [.back, .face(BundledCard.theStar), .face(BundledCard.theMoon)]) {
        self.kinds = kinds
    }

    public var body: some View {
        GeometryReader { geo in
            if reduceMotion {
                staticLayout(geo: geo)
            } else {
                animatedLayout(geo: geo)
            }
        }
        .allowsHitTesting(false)  // background — never intercept touches
    }

    // MARK: - Reduced-motion: static

    private func staticLayout(geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(slots.indices, id: \.self) { idx in
                let slot = slots[idx]
                CeremonialCardFace(kind: slot.kind)
                    .scaleEffect(slot.scale)
                    .rotation3DEffect(.degrees(slot.rotX), axis: (1, 0, 0))
                    .rotation3DEffect(.degrees(slot.rotY), axis: (0, 1, 0))
                    .rotation3DEffect(.degrees(slot.rotZ), axis: (0, 0, 1))
                    .position(
                        x: slot.anchorX * geo.size.width,
                        y: slot.anchorY * geo.size.height
                    )
                    .opacity(slot.opacity)
            }
        }
    }

    // MARK: - Full motion: TimelineView-driven drift

    private func animatedLayout(geo: GeometryProxy) -> some View {
        TimelineView(.animation) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(slots.indices, id: \.self) { idx in
                    let slot = slots[idx]
                    let off = offsets(for: slot, at: now)

                    CeremonialCardFace(kind: slot.kind)
                        .scaleEffect(slot.scale)
                        .rotation3DEffect(.degrees(slot.rotX), axis: (1, 0, 0))
                        .rotation3DEffect(.degrees(slot.rotY + off.dRotY), axis: (0, 1, 0))
                        .rotation3DEffect(.degrees(slot.rotZ), axis: (0, 0, 1))
                        .position(
                            x: slot.anchorX * geo.size.width + off.dx,
                            y: slot.anchorY * geo.size.height + off.dy
                        )
                        .opacity(slot.opacity)
                }
            }
        }
    }

    // MARK: - Drift computation

    /// Card drift and rotation offsets at a given timestamp.
    private struct CardOffsets {
        let dx: CGFloat
        let dy: CGFloat
        let dRotY: Double
    }

    /// Computes drift and rotation offsets for a card slot at timestamp `time`.
    private func offsets(for slot: CardSlot, at time: Double) -> CardOffsets {
        let driftAmp: Double = 30   // ±30 pt drift
        let rotAmp: Double = 6      // ±6° Y rotation

        let phase = slot.phaseOffset * slot.driftPeriod
        let sineT = (time + phase) / slot.driftPeriod * 2 * .pi
        let sineTB = (time + phase * 1.3) / (slot.driftPeriod * 1.15) * 2 * .pi
        let sineR = (time + phase * 0.7) / slot.spinPeriod * 2 * .pi

        return CardOffsets(
            dx: CGFloat(sin(sineT) * driftAmp),
            dy: CGFloat(cos(sineTB) * driftAmp * 0.6),
            dRotY: sin(sineR) * rotAmp
        )
    }

    // MARK: - Slot resolution

    private var slots: [CardSlot] {
        zip(defaultSlots, kinds.prefix(3)).map { base, kind in
            CardSlot(kind: kind,
                     anchorX: base.anchorX, anchorY: base.anchorY,
                     scale: base.scale,
                     rotX: base.rotX, rotY: base.rotY, rotZ: base.rotZ,
                     phaseOffset: base.phaseOffset,
                     driftPeriod: base.driftPeriod,
                     spinPeriod: base.spinPeriod,
                     opacity: base.opacity)
        }
    }
}
