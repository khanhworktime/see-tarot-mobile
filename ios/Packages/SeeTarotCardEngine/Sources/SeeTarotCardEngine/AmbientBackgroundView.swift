import SwiftUI
import SeeTarotDesignSystem

/// Cosmic particle-field ambient background.
///
/// **API contract (stable across phases):** `public init()` only.
/// Consumed by `RootView` as `.background(AmbientBackgroundView())`.
///
/// Rendering paths:
/// - **Full:** `TimelineView(.animation)` + `Canvas` particle field.
///   Touch via `DragGesture(minimumDistance:0)` injects a radial impulse.
///   Pauses when the scene moves to background or the view disappears.
/// - **Fallback:** `StaticGradientBackground` — identical frame, no ticking.
///   Activated when `accessibilityReduceMotion == true` OR
///   `ProcessInfo.processInfo.isLowPowerModeEnabled == true`.
public struct AmbientBackgroundView: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        if reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled {
            StaticGradientBackground()
        } else {
            ParticleCanvas()
        }
    }
}

// MARK: - ParticleCanvas

/// Inner view that owns simulation state so it can be conditionally mounted.
/// Unmounting (reduced-motion switch) stops all ticks automatically.
private struct ParticleCanvas: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.scenePhase) private var scenePhase

    @State private var system = ParticleSystem()
    @State private var isPaused = false
    @State private var impulsePoint: CGPoint? = nil
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused)) { tl in
                Canvas { ctx, size in
                    // Capture size for next tick (pure read inside Canvas is fine)
                    let snapshot = system   // local copy — no mutation inside Canvas
                    drawBackground(ctx: ctx, size: size)
                    drawParticles(ctx: ctx, size: size, system: snapshot)
                }
                // Drive simulation from timeline date — single-param closure
                // is available on all supported OS versions (iOS 17 / macOS 13).
                .task(id: tl.date) {
                    let size = geo.size
                    guard !isPaused, size.width > 0 else { return }
                    system.advance(
                        dt: 1.0 / 60.0,
                        bounds: size,
                        impulse: impulsePoint
                    )
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in impulsePoint = v.location }
                .onEnded   { _ in impulsePoint = nil }
        )
        .onDisappear { isPaused = true }
        .onAppear    { isPaused = false }
        // scenePhase: use single-param onChange (iOS 14+, macOS 11+).
        .onChange(of: scenePhase) { phase in
            isPaused = phase != .active
        }
    }

    // MARK: - Draw helpers (zero-alloc inside Canvas closure)

    private func drawBackground(ctx: GraphicsContext, size: CGSize) {
        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(tokens.palette.bg)
        )
    }

    private func drawParticles(ctx: GraphicsContext, size: CGSize, system: ParticleSystem) {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return }

        for p in system.particles {
            let alpha = Double(0.25 + (1.0 - p.depth) * 0.75)
            let cx = Double(p.x) * w
            let cy = Double(p.y) * h
            let r  = Double(p.radius)
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(tokens.palette.starlight.opacity(alpha))
            )
        }
    }
}
