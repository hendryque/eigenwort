import CoreGraphics

/// What a one-finger drag in the lightbox means. It picks an axis once it has
/// moved far enough to tell, and keeps it: sideways pages, vertically closes,
/// so a slightly diagonal swipe never does both.
struct LightboxDrag: Equatable {
    enum Axis { case horizontal, vertical }
    enum Outcome: Equatable { case stay, page(Int), dismiss }

    private(set) var axis: Axis?

    /// Travel before the axis is decided, so a tap's jitter decides nothing.
    static let decide: CGFloat = 10
    /// Vertical travel that closes on release.
    static let dismiss: CGFloat = 110
    /// A flick closes too: where the finger's speed would have carried it.
    static let flick: CGFloat = 260

    mutating func update(_ translation: CGSize) {
        guard axis == nil, max(abs(translation.width), abs(translation.height)) >= Self.decide else { return }
        axis = abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
    }

    /// `predicted` is the gesture's predicted end translation. A page turns
    /// once the drag would end past half the width, so a flick turns it too.
    func outcome(translation: CGSize, predicted: CGSize, width: CGFloat) -> Outcome {
        switch axis {
        case .horizontal:
            guard abs(predicted.width) > width / 2 else { return .stay }
            return .page(predicted.width < 0 ? 1 : -1)
        case .vertical:
            let closes = abs(translation.height) > Self.dismiss || abs(predicted.height) > Self.flick
            return closes ? .dismiss : .stay
        case nil:
            return .stay
        }
    }
}
