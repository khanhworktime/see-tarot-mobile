import SwiftUI
import SeeTarotDesignSystem

// MARK: - RitualPhase

/// Ordered state machine for the spread ritual animation sequence.
/// Pure enum — transition logic lives in `SpreadRitualView`; testable in isolation.
public enum RitualPhase: Equatable, Sendable {
    /// Deck shown face-down; riffle/scatter particles reactive.
    case shuffle
    /// Cards arc into a fan; user sees the face-down spread.
    case fan
    /// User is pressing and holding the deck; particles converge inward.
    /// Skipped when `reduceMotion == true`.
    case hold
    /// User released (or reduced-motion path bypassed hold); cards dealing out.
    case dealing
    /// All cards in position and flipped face-up; ritual complete.
    case done
}

// MARK: - RitualCard

/// Immutable value representing one card slot in the ritual display.
public struct RitualCard: Identifiable, Sendable {
    public let id: Int          // matches `position` in spread slot
    public let name: String
    public let imageURL: URL?
    public let reversed: Bool

    public init(id: Int, name: String, imageURL: URL?, reversed: Bool) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.reversed = reversed
    }
}

// MARK: - ParticleConvergeAction

/// Optional environment hook so `SpreadRitualView` can pull ambient
/// particles inward during hold-to-focus without hard-coupling to
/// `AmbientBackgroundView`. If the environment value is `nil`, the ritual
/// still functions correctly — the hook degrades gracefully.
public struct ParticleConvergeAction: Sendable {
    /// Called with `true` when the hold begins; `false` when released.
    public let setConverging: @Sendable (Bool) -> Void

    public init(setConverging: @Sendable @escaping (Bool) -> Void) {
        self.setConverging = setConverging
    }
}

private struct ParticleConvergeKey: EnvironmentKey {
    static let defaultValue: ParticleConvergeAction? = nil
}

public extension EnvironmentValues {
    /// Inject to receive converge start/stop signals from `SpreadRitualView`.
    var particleConverge: ParticleConvergeAction? {
        get { self[ParticleConvergeKey.self] }
        set { self[ParticleConvergeKey.self] = newValue }
    }
}

// MARK: - SpreadRitualView

/// Orchestrates the ceremonial deal sequence in front of the Oracle reading.
/// Full motion: shuffle → fan → hold-to-focus → release → deal + staggered flip.
/// Reduced-motion: shuffle (crossfade) → straight deal + crossfade reveal.
/// Data models in `RitualCardState.swift`; layout helpers in `RitualTimeline.swift`.
public struct SpreadRitualView: View {

    // MARK: Inputs

    let cards: [RitualCard]
    let spread: SpreadKind
    let reduceMotion: Bool
    let loader: CardImageLoaderClosure?

    // MARK: Environment

    @Environment(\.designTokens) private var tokens
    @Environment(\.particleConverge) private var convergeHook

    // MARK: Phase state

    @State private var phase: RitualPhase = .shuffle
    @State private var deckScale: CGFloat  = 1.0
    @State private var deckOpacity: Double = 1.0
    @State private var fanCards: [FanCardState] = []
    @State private var dealtCards: [DealtCardState] = []
    @State private var isHolding: Bool = false
    @State private var holdProgress: Double = 0.0  // 0→1 while held
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var containerSize: CGSize = .zero

    // MARK: Timing constants

    private let shuffleDuration: Double = 0.55
    private let fanDuration: Double     = 0.45
    private let dealStaggerMs: Double   = 0.040   // 40 ms = midpoint of 30–50 ms spec
    private let holdFillDuration: Double = 1.2    // time to fill the hold ring

    // MARK: Init

    public init(
        cards: [RitualCard],
        spread: SpreadKind,
        reduceMotion: Bool,
        loader: CardImageLoaderClosure? = nil
    ) {
        self.cards = cards
        self.spread = spread
        self.reduceMotion = reduceMotion
        self.loader = loader
    }

    // MARK: Body

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deck / fan phase — visible until dealing
                if phase == .shuffle || phase == .fan || phase == .hold {
                    deckView(in: geo.size)
                }

                // Dealt cards — visible from dealing phase onward
                if phase == .dealing || phase == .done {
                    dealtCardsLayer(in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                containerSize = geo.size
                startRitual(in: geo.size)
            }
        }
        // Prevent layout collapse when no cards yet
        .frame(minHeight: SpreadLayout.cardHeight + 40)
    }

    // MARK: - Deck View (shuffle / fan / hold phases)

    @ViewBuilder
    private func deckView(in size: CGSize) -> some View {
        ZStack {
            // Stacked deck representation — 4 offset layers
            ForEach(0 ..< 4, id: \.self) { layerIndex in
                RoundedRectangle(cornerRadius: 12)
                    .fill(tokens.palette.bgLayer2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(tokens.palette.accentSilver.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: SpreadLayout.cardWidth, height: SpreadLayout.cardHeight)
                    .offset(
                        x: CGFloat(layerIndex) * -1.5,
                        y: CGFloat(layerIndex) * -1.5
                    )
                    .scaleEffect(deckScale)
                    .opacity(deckOpacity)
            }

            if phase == .fan || phase == .hold { fanOverlay }
            if phase == .fan || phase == .hold { holdRingOverlay }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            LongPressGesture(minimumDuration: 0.0)
                .simultaneously(with: DragGesture(minimumDistance: 0))
                .onChanged { _ in
                    guard phase == .fan || phase == .hold else { return }
                    beginHold()
                }
                .onEnded { _ in
                    endHold(triggeredDeal: true, in: containerSize)
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard phase == .fan || phase == .hold else { return }
                    beginHold()
                }
                .onEnded { _ in
                    endHold(triggeredDeal: true, in: containerSize)
                }
        )
        .accessibilityLabel("Tarot deck. Press and hold to focus, then release to deal.")
        .accessibilityAction(named: "Deal cards") {
            endHold(triggeredDeal: true, in: containerSize)
        }
    }

    // MARK: - Fan overlay

    @ViewBuilder
    private var fanOverlay: some View {
        ZStack {
            ForEach(fanCards) { cardState in
                RoundedRectangle(cornerRadius: 10)
                    .fill(tokens.palette.bgLayer1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                tokens.palette.accentSilver.opacity(0.35),
                                lineWidth: 0.8
                            )
                    )
                    .frame(width: SpreadLayout.cardWidth - 8, height: SpreadLayout.cardHeight - 12)
                    .rotationEffect(.degrees(cardState.angle))
                    .offset(cardState.offset)
                    .opacity(cardState.opacity)
            }
        }
    }

    // MARK: - Hold ring overlay

    @ViewBuilder
    private var holdRingOverlay: some View {
        Circle()
            .trim(from: 0, to: holdProgress)
            .stroke(
                tokens.palette.accentSilver.opacity(0.7),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: SpreadLayout.cardWidth + 16, height: SpreadLayout.cardWidth + 16)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: holdFillDuration), value: holdProgress)
            .opacity(phase == .hold ? 1 : 0)
    }

    // MARK: - Dealt cards layer

    @ViewBuilder
    private func dealtCardsLayer(in size: CGSize) -> some View {
        // Capture with explicit Sendable type so the compiler doesn't widen
        // it to a non-Sendable function value inside the ForEach closure.
        let sendableLoader: CardImageLoaderClosure? = loader
        ZStack {
            ForEach(dealtCards) { state in
                RealCardSurface(
                    name: state.card.name,
                    reversed: state.card.reversed,
                    loader: sendableLoader
                )
                .cardView(
                    imageURL: state.card.imageURL,
                    faceUp: state.faceUp,
                    position: state.card.id
                )
                .offset(state.offset)
                .opacity(state.opacity)
                .scaleEffect(state.scale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ritual timeline entry point

    private func startRitual(in size: CGSize) {
        if reduceMotion {
            startReducedMotionPath(in: size)
        } else {
            startFullRitual(in: size)
        }
    }

    // MARK: Full ritual (shuffle → fan → hold → deal → flip)

    private func startFullRitual(in size: CGSize) {
        phase = .shuffle
        withAnimation(.easeInOut(duration: shuffleDuration / 2).repeatCount(2, autoreverses: true)) {
            deckScale = 1.03
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(shuffleDuration))
            guard !Task.isCancelled else { return }
            await advanceToFan()
        }
    }

    @MainActor
    private func advanceToFan() async {
        phase = .fan
        deckScale = 1.0
        fanCards = RitualFanLayout.initialStates(count: cards.count)
        withAnimation(.spring(response: fanDuration, dampingFraction: 0.75)) {
            fanCards = RitualFanLayout.applyFanOffsets(fanCards)
        }
    }

    // MARK: Hold-to-focus

    private func beginHold() {
        guard !isHolding else { return }
        isHolding = true
        phase = .hold
        convergeHook?.setConverging(true)
        withAnimation(.linear(duration: holdFillDuration)) {
            holdProgress = 1.0
        }
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(holdFillDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true)) {
                deckScale = 1.06
            }
        }
    }

    private func endHold(triggeredDeal: Bool, in size: CGSize) {
        guard isHolding || phase == .fan else { return }
        isHolding = false
        holdTask?.cancel()
        holdTask = nil
        convergeHook?.setConverging(false)
        if triggeredDeal { performDeal(in: size) }
    }

    // MARK: Deal + staggered flip

    private func performDeal(in size: CGSize) {
        phase = .dealing
        fanCards = []
        let container = CGRect(origin: .zero, size: size)
        let slots = SpreadLayout.slots(count: cards.count, in: container)
        dealtCards = RitualDealLayout.initialStates(cards: cards, slots: slots,
                                                    containerSize: size)
        withAnimation(.easeOut(duration: 0.2)) {
            deckOpacity = 0
            deckScale = 0.9
        }
        scheduleDealAndFlip(slots: slots, containerSize: size)
    }

    private func scheduleDealAndFlip(slots: [SpreadSlot], containerSize: CGSize) {
        for (index, slot) in slots.enumerated() {
            let dealDelay = Double(index) * dealStaggerMs
            let flipDelay = dealDelay + 0.30
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(dealDelay))
                guard !Task.isCancelled else { return }
                let slotOffset = RitualDealLayout.slotOffset(slot: slot,
                                                             containerSize: containerSize)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                    if index < dealtCards.count {
                        dealtCards[index].offset = slotOffset
                        dealtCards[index].opacity = 1.0
                        dealtCards[index].scale = 1.0
                    }
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(flipDelay))
                guard !Task.isCancelled else { return }
                if index < dealtCards.count { dealtCards[index].faceUp = true }
                if index == slots.indices.last {
                    try? await Task.sleep(for: .seconds(0.40))
                    phase = .done
                }
            }
        }
        if slots.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                phase = .done
            }
        }
    }

    // MARK: - Reduced motion path

    private func startReducedMotionPath(in size: CGSize) {
        phase = .shuffle
        let container = CGRect(origin: .zero, size: size)
        let slots = SpreadLayout.slots(count: cards.count, in: container)
        dealtCards = RitualDealLayout.finalStates(cards: cards, slots: slots,
                                                  containerSize: size)
        withAnimation(.easeIn(duration: 0.3)) { deckOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            phase = .dealing
            withAnimation(.easeIn(duration: 0.25)) {
                for idx in dealtCards.indices { dealtCards[idx].opacity = 1.0 }
            }
            try? await Task.sleep(for: .seconds(0.30))
            for idx in dealtCards.indices { dealtCards[idx].faceUp = true }
            try? await Task.sleep(for: .seconds(0.25))
            phase = .done
        }
    }
}
