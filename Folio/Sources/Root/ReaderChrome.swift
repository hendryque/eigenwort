import SwiftUI

/// What the app's header and the reader tell each other. The header publishes
/// its height; the reader says when it is being read down, and the header
/// slides away on the same rule as the reader's own bar.
@MainActor @Observable
final class ReaderChrome {
    var headerHeight: CGFloat = 0
    /// Where the header ends on screen. Views in a navigation stack do not
    /// inherit the root's inset for it, so they pad down to this line.
    var headerBottom: CGFloat = 0
    var isHeaderHidden = false
}

extension View {
    /// Pads a screen down to where the header rests. Measured outside the
    /// padding, so the padding cannot move what it is measured from.
    func clearsHeader() -> some View { modifier(ClearsHeader()) }
}

private struct ClearsHeader: ViewModifier {
    @Environment(ReaderChrome.self) private var chrome: ReaderChrome?
    @State private var top: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.top, max(0, (chrome?.headerBottom ?? 0) - top))
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top = $0 }
    }
}
