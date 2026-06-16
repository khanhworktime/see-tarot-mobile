import SwiftUI

// MARK: - Particle

/// A single particle in the star-field. All fields are plain value types
/// so the struct fits in a contiguous array with no heap indirection.
public struct Particle: Sendable {
    /// Normalised position in [0,1]×[0,1] — scaled to canvas size at draw time.
    var x: Float
    var y: Float
    /// Velocity in normalised units per second.
    var vx: Float
    var vy: Float
    /// Visual radius in points (pre-computed, constant across frames).
    let radius: Float
    /// Depth in [0,1] — drives alpha: deeper ≡ dimmer.
    let depth: Float
    /// Impulse velocity from touch interaction, decays each tick.
    var impulseVx: Float
    var impulseVy: Float
}

// MARK: - ParticleSystem

/// Pure value-type particle simulation.
/// `advance` is a free-standing pure function (see extension below) so it can
/// be called from unit tests without any SwiftUI or UIKit dependency.
public struct ParticleSystem: Sendable {

    // MARK: Constants

    /// Maximum number of live particles. Tuned for ≥60fps on iPhone-12 class.
    public static let maxCount = 150

    /// Impulse decay per second (fraction of velocity remaining after 1 s).
    /// 0.02 → impulse halves in ~0.22 s; effectively zero after ~1.5 s.
    private static let impulseDecay: Float = 0.02

    /// How strongly a touch nudges nearby particles (points/s² per normalised unit).
    private static let impulseMagnitude: Float = 0.25

    /// Radius below which touch has full effect (normalised units).
    private static let impulseRadius: Float = 0.25

    // MARK: State

    public private(set) var particles: [Particle]

    // MARK: Init

    /// Seed the system with `count` randomly positioned particles.
    /// - Parameter seed: deterministic seed for testing; pass `nil` for random.
    public init(count: Int = ParticleSystem.maxCount, seed: UInt64? = nil) {
        let n = min(count, ParticleSystem.maxCount)
        var rng = seed.map { Xorshift64(state: $0) } ?? Xorshift64(state: UInt64.random(in: 1 ... .max))
        particles = (0 ..< n).map { _ in
            let depth = rng.nextFloat()          // 0 = near, 1 = far
            let baseSpeed: Float = 0.003 + (1 - depth) * 0.007   // near = faster
            let angle = rng.nextFloat() * .pi * 2
            return Particle(
                x: rng.nextFloat(),
                y: rng.nextFloat(),
                vx: cos(angle) * baseSpeed,
                vy: sin(angle) * baseSpeed,
                radius: 1.0 + (1 - depth) * 1.5,
                depth: depth,
                impulseVx: 0,
                impulseVy: 0
            )
        }
    }

    // MARK: Simulation step

    /// Advance simulation by `dt` seconds within `bounds`.
    /// - Parameters:
    ///   - dt: Time delta in seconds (clamped to max 1/30 s to avoid tunnelling).
    ///   - bounds: Canvas size in points.
    ///   - impulse: Optional touch point in canvas coordinates; nil = no touch.
    /// - Returns: A new `ParticleSystem` with updated state.
    @discardableResult
    public mutating func advance(
        dt: Float,
        bounds: CGSize,
        impulse: CGPoint?
    ) -> ParticleSystem {
        self = ParticleSystem.step(system: self, dt: dt, bounds: bounds, impulse: impulse)
        return self
    }
}

// MARK: - Pure simulation step (testable, no SwiftUI)

extension ParticleSystem {

    /// Stateless step function — takes old state, returns new state.
    /// This is the function targeted by unit tests.
    static func step(
        system: ParticleSystem,
        dt: Float,
        bounds: CGSize,
        impulse: CGPoint?
    ) -> ParticleSystem {
        let safeDt = min(dt, 1.0 / 30.0)
        let decay = pow(impulseDecay, safeDt)

        var updated = system
        let w = Float(bounds.width)
        let h = Float(bounds.height)
        guard w > 0, h > 0 else { return updated }

        let normImpulse: (x: Float, y: Float)? = impulse.map {
            (Float($0.x) / w, Float($0.y) / h)
        }

        for idx in updated.particles.indices {
            var p = updated.particles[idx]

            // Apply impulse
            if let ni = normImpulse {
                let dx = p.x - ni.x
                let dy = p.y - ni.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < impulseRadius, dist > 0 {
                    let strength = impulseMagnitude * (1 - dist / impulseRadius)
                    p.impulseVx += (dx / dist) * strength
                    p.impulseVy += (dy / dist) * strength
                }
            }

            // Decay impulse
            p.impulseVx *= decay
            p.impulseVy *= decay

            // Integrate position (drift + impulse)
            p.x += (p.vx + p.impulseVx) * safeDt
            p.y += (p.vy + p.impulseVy) * safeDt

            // Wrap edges
            p.x = wrap(p.x)
            p.y = wrap(p.y)

            updated.particles[idx] = p
        }
        return updated
    }

    private static func wrap(_ v: Float) -> Float {
        if v < 0 { return v + 1.0 }
        if v > 1 { return v - 1.0 }
        return v
    }
}

// MARK: - StaticGradientBackground

/// Static palette-tinted gradient used for reduced-motion and low-power paths.
/// Identical frame/layout to the particle path — no layout shift on switch.
public struct StaticGradientBackground: View {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public var body: some View {
        LinearGradient(
            stops: [
                .init(color: tokens.palette.bg, location: 0),
                .init(color: tokens.palette.bgLayer1.opacity(0.8), location: 0.4),
                .init(color: tokens.palette.bgLayer2.opacity(0.6), location: 0.7),
                .init(color: tokens.palette.accentSilver.opacity(0.08), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Xorshift64 (deterministic RNG, no Foundation dependency)

/// Minimal xorshift64 PRNG — deterministic, allocation-free.
/// Internal only; not exported.
struct Xorshift64: Sendable {
    var state: UInt64

    mutating func next() -> UInt64 {
        var x = state
        x ^= x << 13
        x ^= x >> 7
        x ^= x << 17
        state = x
        return x
    }

    /// Uniform Float in [0, 1).
    mutating func nextFloat() -> Float {
        Float(next() >> 40) / Float(1 << 24)
    }
}
