import SwiftUI

/// What the app's header and the reader tell each other. The header publishes
/// its height; the reader says when it is being read down, and the header
/// slides away on the same rule as the reader's own bar.
@MainActor @Observable
final class ReaderChrome {
    var headerHeight: CGFloat = 0
    /// Where the header ends on screen. A pushed view does not inherit the
    /// root's inset for it, so the reader pads itself down to this line.
    var headerBottom: CGFloat = 0
    var isHeaderHidden = false
}
