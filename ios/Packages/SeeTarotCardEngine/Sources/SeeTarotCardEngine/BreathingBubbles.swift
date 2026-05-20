// BreathingBubbles.swift — CardEngine / Phase 09-Pass2 (Visual Tuning)
//
// 4–6 large, softly blurred glowing orbs that breathe (scale 0.9→1.1)
// and drift slowly (±30 pt). Each bubble has an independent phase offset.
// Reduced-motion path: static, no breathing or drift.
//
// Pass 2 changes:
//   - Opacity range bumped 0.10–0.20 → 0.22–0.40 for visible glow presence.
//   - Blur radius reduced 60–120 → 30–60 — still soft but readable as orbs.
//   - Tint palette now uses aurora colors (violet, cyan, pink) + accentSilver.
//   - Layout slots repositioned: ≥2 bubbles in upper third + 1 lower-centre.
//   - Breathing cycle tightened to 5–8 s for more felt presence.

import SwiftUI

// MARK: - Internal slot descriptor (replaces large tuple for lint compliance)

private struct BubbleSlot: Sendable {
    let x: CGFloat
    let y: CGFloat
    let diameter: CGFloat
    let blur: CGFloat
    let opacity: Double
    let phase: Double
    let breathPeriod: Double
    let driftPeriod: Double
}

// MARK: - Bubble descriptor

private struct Bubble: Sendable {
    /// Fractional anchor 0–1 within the parent bounds.
    let anchorX: CGFloat
    let anchorY: CGFloat
    let diameter: CGFloat
    let color: Color
    let opacity: Double
    let blurRadius: CGFloat
    /// Phase offset (seconds) into the breathing/drift cycle.
    let phase: Double
    /// Breathing period in seconds.
    let breathPeriod: Double
    /// Drift period in seconds (X axis).
    let driftPeriod: Double
}

// MARK: - BreathingBubbles

/// Atmospheric background element: large blurred glowing circles that breathe and drift.
/// Place behind content; use `.ignoresSafeArea()` on the enclosing container.
public struct BreathingBubbles: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bubbleCount: Int
    private let tints: [Color]?

    /// - Parameters:
    ///   - bubbleCount: Number of bubbles (clamped 4–6). Default 5.
    ///   - tints: Optional palette tints. Nil = uses aurora violet/cyan/pink + accentSilver.
    public init(bubbleCount: Int = 5, tints: [Color]? = nil) {
        self.bubbleCount = min(max(bubbleCount, 4), 6)
        self.tints = tints
    }

    public var body: some View {
        GeometryReader { geo in
            let bubbles = makeBubbles(in: geo.size)
            if reduceMotion {
                staticBubbles(bubbles, geo: geo)
            } else {
                animatedBubbles(bubbles, geo: geo)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Reduced-motion: static

    private func staticBubbles(_ bubbles: [Bubble], geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(bubbles.indices, id: \.self) { idx in
                let b = bubbles[idx]
                Circle()
                    .fill(b.color.opacity(b.opacity))
                    .frame(width: b.diameter, height: b.diameter)
                    .blur(radius: b.blurRadius)
                    .position(
                        x: b.anchorX * geo.size.width,
                        y: b.anchorY * geo.size.height
                    )
            }
        }
    }

    // MARK: - Animated: TimelineView breathing + drift

    private func animatedBubbles(_ bubbles: [Bubble], geo: GeometryProxy) -> some View {
        TimelineView(.animation) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(bubbles.indices, id: \.self) { idx in
                    let b = bubbles[idx]
                    let anim = animation(for: b, at: now)

                    Circle()
                        .fill(b.color.opacity(b.opacity))
                        .frame(width: b.diameter, height: b.diameter)
                        .blur(radius: b.blurRadius)
                        .scaleEffect(anim.scale)
                        .position(
                            x: b.anchorX * geo.size.width + anim.dx,
                            y: b.anchorY * geo.size.height + anim.dy
                        )
                }
            }
        }
    }

    // MARK: - Animation computation

    /// Animated offsets for a bubble at timestamp `now`.
    private struct BubbleAnim {
        let scale: CGFloat
        let dx: CGFloat
        let dy: CGFloat
    }

    /// Computes breathing scale and drift offsets for a bubble at timestamp `now`.
    private func animation(for bubble: Bubble, at now: Double) -> BubbleAnim {
        let breathT = (now + bubble.phase) / bubble.breathPeriod * 2 * .pi
        // Sine in [-1,1] → scale in [0.9, 1.1]
        let scale = CGFloat(0.9 + 0.1 * (sin(breathT) + 1.0))

        let driftAmp: Double = 30
        let driftT = (now + bubble.phase * 1.2) / bubble.driftPeriod * 2 * .pi
        let driftTB = (now + bubble.phase * 0.8) / (bubble.driftPeriod * 1.3) * 2 * .pi
        let dx = CGFloat(sin(driftT) * driftAmp)
        let dy = CGFloat(cos(driftTB) * driftAmp * 0.7)

        return BubbleAnim(scale: scale, dx: dx, dy: dy)
    }

    // MARK: - Bubble factory

    // Predefined layout slots — enough for max 6 bubbles.
    // Upper-third heavy (0–1), mid-screen (2), lower-centre (3), side edges (4–5).
    // blur 30–60 (was 60–120); opacity 0.22–0.40 (was 0.10–0.20); breath 5–8 s.
    private static let bubbleSlots: [BubbleSlot] = [
        BubbleSlot(x: 0.15, y: 0.18, diameter: 280, blur: 45, opacity: 0.32, phase: 0.0, breathPeriod: 6, driftPeriod: 14),
        BubbleSlot(x: 0.82, y: 0.14, diameter: 220, blur: 35, opacity: 0.28, phase: 1.7, breathPeriod: 5, driftPeriod: 18),
        BubbleSlot(x: 0.50, y: 0.50, diameter: 340, blur: 55, opacity: 0.24, phase: 3.1, breathPeriod: 8, driftPeriod: 12),
        BubbleSlot(x: 0.50, y: 0.78, diameter: 200, blur: 38, opacity: 0.30, phase: 4.4, breathPeriod: 7, driftPeriod: 20),
        BubbleSlot(x: 0.88, y: 0.62, diameter: 260, blur: 48, opacity: 0.22, phase: 2.3, breathPeriod: 6, driftPeriod: 16),
        BubbleSlot(x: 0.08, y: 0.55, diameter: 180, blur: 32, opacity: 0.26, phase: 5.0, breathPeriod: 5, driftPeriod: 22)
    ]

    private func makeBubbles(in size: CGSize) -> [Bubble] {
        let resolvedTints = tints ?? defaultTints
        return (0 ..< bubbleCount).map { idx in
            let s = Self.bubbleSlots[idx]
            let tint = resolvedTints[idx % resolvedTints.count]
            return Bubble(
                anchorX: s.x, anchorY: s.y,
                diameter: s.diameter,
                color: tint,
                opacity: s.opacity,
                blurRadius: s.blur,
                phase: s.phase,
                breathPeriod: s.breathPeriod,
                driftPeriod: s.driftPeriod
            )
        }
    }

    private var defaultTints: [Color] {
        [
            tokens.palette.auroraViolet,
            tokens.palette.auroraCyan,
            tokens.palette.auroraPink,
            tokens.palette.accentSilver
        ]
    }
}
