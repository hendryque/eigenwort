import UIKit

/// German has single words wider than the column, and titles do not hyphenate:
/// the size comes down until the widest word fits, to its floor, past which
/// fit.js hyphenates. article.css applies the same rule to these widths.
enum TitleFit {
    /// Of the theme's own size, not the enlarged one, and never below the text.
    static let floor = 0.6

    /// A theme title size (`themeSize`, as at 100%) for `room` points of
    /// column. At an exact fit SwiftUI wraps the last letter: a point of slack.
    static func size(_ themeSize: Double, fontScale: Double, for title: String, in theme: Theme, room: Double) -> Double {
        let nominal = themeSize * ArticleTitle.scale(fontScale)
        let widest = widestPiece(of: title, fontName: theme.titleFontName, tracking: theme.titleTracking)
        guard widest > 0, room > 1 else { return nominal }
        let lowest = max(themeSize * floor, theme.bodySize * fontScale)
        return max(lowest, min(nominal, (room - 1) / widest))
    }

    /// The widest piece a line cannot break, in em of the face, with `tracking`
    /// (CSS letter-spacing, in em) after every character as WebKit sets it.
    static func widestPiece(of title: String, fontName: String, tracking: Double) -> Double {
        guard let font = UIFont(name: fontName, size: 100) else { return 0 }
        return pieces(of: title).map { piece in
            (piece as NSString).size(withAttributes: [.font: font]).width / 100 + Double(piece.count) * tracking
        }.max() ?? 0
    }

    /// The title cut where WebKit and Core Text may break it: at spaces, and
    /// after a hyphen or dash, which stays with the piece before it.
    static func pieces(of title: String) -> [String] {
        var pieces: [String] = []
        var current = ""
        for character in title {
            if character.isWhitespace {
                if !current.isEmpty { pieces.append(current) }
                current = ""
                continue
            }
            current.append(character)
            if breaksAfter.contains(character) {
                pieces.append(current)
                current = ""
            }
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces
    }

    private static let breaksAfter: Set<Character> = ["-", "\u{2010}", "\u{2013}", "\u{2014}"]
}
