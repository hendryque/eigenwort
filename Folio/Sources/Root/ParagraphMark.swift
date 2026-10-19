import SwiftUI

/// The app icon's paragraph: one word in the accent among grey ones. Drawn
/// rather than bundled so it takes each theme's colours. With the word
/// missing it is the error page's picture: the one thing that did not arrive.
struct ParagraphMark: View {
    /// Points per grid unit. The header's third of a point lands every edge
    /// on a 3x pixel.
    var unit: CGFloat = 1.0 / 3
    var isWordMissing = false

    @Environment(\.folioTheme) private var theme

    // Each line is its indent and word widths: the first indented, the last short.
    private static let lines: [(indent: CGFloat, words: [CGFloat])] = [
        (9, [18, 26]), (0, [15, 24, 10]), (0, [27, 26]), (0, [18, 12])
    ]
    private static let accent = (line: 1, word: 1)
    private static let stroke: CGFloat = 7, pitch: CGFloat = 14, gap: CGFloat = 4, width: CGFloat = 57

    var body: some View {
        Canvas { context, _ in
            context.scaleBy(x: unit, y: unit)
            let hairline = 1 / unit
            for (row, line) in Self.lines.enumerated() {
                var x = line.indent
                for (index, word) in line.words.enumerated() {
                    let rect = CGRect(x: x, y: CGFloat(row) * Self.pitch, width: word, height: Self.stroke)
                    if (row, index) != Self.accent {
                        context.fill(Path(rect), with: .color(theme.palette.secondaryColor.opacity(0.45)))
                    } else if isWordMissing {
                        context.stroke(
                            Path(rect.insetBy(dx: hairline / 2, dy: hairline / 2)),
                            with: .color(theme.palette.accentColor),
                            style: StrokeStyle(lineWidth: hairline, dash: [3 * hairline, 2 * hairline])
                        )
                    } else {
                        context.fill(Path(rect), with: .color(theme.palette.accentColor))
                    }
                    x += word + Self.gap
                }
            }
        }
        .frame(width: Self.width * unit, height: (CGFloat(Self.lines.count - 1) * Self.pitch + Self.stroke) * unit)
    }
}
