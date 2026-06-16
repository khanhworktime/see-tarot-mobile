import XCTest
@testable import SeeTarotCardEngine

final class ParticleSystemTests: XCTestCase {

    private let bounds = CGSize(width: 390, height: 844)

    // MARK: - Count cap

    func testCountCapEnforced() {
        let over = ParticleSystem(count: ParticleSystem.maxCount + 999, seed: 1)
        XCTAssertEqual(over.particles.count, ParticleSystem.maxCount)
    }

    func testCountZeroIsEmpty() {
        let empty = ParticleSystem(count: 0, seed: 1)
        XCTAssertTrue(empty.particles.isEmpty)
    }

    // MARK: - Determinism

    func testAdvanceIsDeterministic() {
        let dt: Float = 1.0 / 60.0
        var sysA = ParticleSystem(count: 50, seed: 42)
        var sysB = ParticleSystem(count: 50, seed: 42)

        sysA.advance(dt: dt, bounds: bounds, impulse: nil)
        sysB.advance(dt: dt, bounds: bounds, impulse: nil)

        for (a, b) in zip(sysA.particles, sysB.particles) {
            XCTAssertEqual(a.x, b.x, accuracy: 1e-6)
            XCTAssertEqual(a.y, b.y, accuracy: 1e-6)
        }
    }

    func testDifferentSeedsDiffer() {
        let sysA = ParticleSystem(count: 10, seed: 1)
        let sysB = ParticleSystem(count: 10, seed: 2)
        // Extremely unlikely to be identical with different seeds
        let anyDiff = zip(sysA.particles, sysB.particles).contains { a, b in
            abs(a.x - b.x) > 1e-4
        }
        XCTAssertTrue(anyDiff)
    }

    // MARK: - Position wrapping

    func testParticlesStayNormalised() {
        var sys = ParticleSystem(count: ParticleSystem.maxCount, seed: 7)
        // Run 120 frames
        for _ in 0 ..< 120 {
            sys.advance(dt: 1.0 / 60.0, bounds: bounds, impulse: nil)
        }
        for p in sys.particles {
            XCTAssertGreaterThanOrEqual(p.x, 0.0, "x wrapped below 0")
            XCTAssertLessThanOrEqual(p.x, 1.0, "x wrapped above 1")
            XCTAssertGreaterThanOrEqual(p.y, 0.0, "y wrapped below 0")
            XCTAssertLessThanOrEqual(p.y, 1.0, "y wrapped above 1")
        }
    }

    // MARK: - Impulse decay

    func testImpulseDecaysToNearZero() {
        var sys = ParticleSystem(count: 10, seed: 3)
        let touchPoint = CGPoint(x: 195, y: 422)   // centre of bounds

        // Single impulse tick
        sys.advance(dt: 1.0 / 60.0, bounds: bounds, impulse: touchPoint)

        // Run 2 seconds of ticks without further touch.
        // With impulseDecay = 0.02/s: after 2 s residual ≈ initial * 0.02^2 = 4e-4 × initial.
        // Max initial impulse magnitude ≈ impulseMagnitude (0.25), so max residual ≈ 1e-4.
        for _ in 0 ..< 120 {
            sys.advance(dt: 1.0 / 60.0, bounds: bounds, impulse: nil)
        }

        for p in sys.particles {
            XCTAssertEqual(p.impulseVx, 0, accuracy: 0.001,
                           "impulseVx did not decay: \(p.impulseVx)")
            XCTAssertEqual(p.impulseVy, 0, accuracy: 0.001,
                           "impulseVy did not decay: \(p.impulseVy)")
        }
    }

    func testImpulseIsNonZeroAfterTouch() {
        var sys = ParticleSystem(count: 50, seed: 5)
        let centre = CGPoint(x: 195, y: 422)

        // Find a particle that should be near the touch point (within impulse radius)
        // and check that after advance, at least one particle has non-zero impulse.
        sys.advance(dt: 1.0 / 60.0, bounds: bounds, impulse: centre)

        let anyAffected = sys.particles.contains {
            abs($0.impulseVx) > 0 || abs($0.impulseVy) > 0
        }
        XCTAssertTrue(anyAffected, "No particle received impulse from touch")
    }

    // MARK: - Large dt clamping (tunnelling guard)

    func testLargeDtDoesNotTunnel() {
        var sys = ParticleSystem(count: 20, seed: 9)
        // Simulate a 5-second stall — dt clamped to 1/30 s internally
        sys.advance(dt: 5.0, bounds: bounds, impulse: nil)

        for p in sys.particles {
            XCTAssertGreaterThanOrEqual(p.x, 0.0)
            XCTAssertLessThanOrEqual(p.x, 1.0)
            XCTAssertGreaterThanOrEqual(p.y, 0.0)
            XCTAssertLessThanOrEqual(p.y, 1.0)
        }
    }

    // MARK: - Zero-size bounds guard

    func testZeroBoundsDoesNotCrash() {
        var sys = ParticleSystem(count: 10, seed: 11)
        let before = sys.particles.map { ($0.x, $0.y) }
        sys.advance(dt: 1.0 / 60.0, bounds: .zero, impulse: nil)
        let after = sys.particles.map { ($0.x, $0.y) }
        // Positions unchanged when bounds are zero (guard returns early)
        for (b, a) in zip(before, after) {
            XCTAssertEqual(b.0, a.0)
            XCTAssertEqual(b.1, a.1)
        }
    }

    // MARK: - Particle depth / radius invariants

    func testDepthAndRadiusInRange() {
        let sys = ParticleSystem(count: ParticleSystem.maxCount, seed: 17)
        for p in sys.particles {
            XCTAssertGreaterThanOrEqual(p.depth, 0.0)
            XCTAssertLessThanOrEqual(p.depth, 1.0)
            XCTAssertGreaterThan(p.radius, 0.0)
        }
    }
}
