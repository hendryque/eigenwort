import Foundation

/// Decides whether the reader's bar shows. It hides while you read down and
/// returns when you scroll up on purpose or reach either end of the article.
/// A pause changes nothing, since a pause is when you are reading.
struct ToolbarReveal: Equatable {
    private(set) var isVisible = true
    private var lastY: Double?
    private var upwardTravel: Double = 0

    /// Within this distance of the top or the end, the bar always shows: you
    /// have just arrived or are about to leave.
    static let edge: Double = 80
    /// Upward travel that counts as wanting the bar, not a thumb settling.
    static let intent: Double = 24

    /// `remaining` is the scrollable distance left below the viewport.
    mutating func update(y: Double, remaining: Double) {
        defer { lastY = y }
        guard let lastY, y >= Self.edge, remaining >= Self.edge else {
            // The first report is where the article opened, possibly a restored
            // position: arriving is not scrolling, so the bar stays.
            isVisible = true
            upwardTravel = 0
            return
        }
        let delta = y - lastY
        if delta > 0 {
            upwardTravel = 0
            isVisible = false
        } else {
            upwardTravel -= delta
            if upwardTravel >= Self.intent { isVisible = true }
        }
    }
}
