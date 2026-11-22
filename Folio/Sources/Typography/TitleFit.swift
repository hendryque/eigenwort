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
        return pieces(of: title).map { width(of: $0, font: font) / 100 + Double($0.count) * tracking }.max() ?? 0
    }

    static func width(of piece: String, font: UIFont) -> Double {
        (piece as NSString).size(withAttributes: [.font: font]).width
    }

    /// For text that cannot shrink, a list row's title: only a piece wider than
    /// `room` gets soft hyphens, so it breaks at a syllable instead of any
    /// letter, and every word that fits a line still never breaks.
    static func hyphenatingTooWide(_ title: String, font: UIFont, room: Double, language: String) -> String {
        guard room > 0 else { return title }
        return title.split(separator: " ", omittingEmptySubsequences: false).map { word in
            pieces(of: String(word)).map { piece in
                // A point under the room, or SwiftUI breaks it at a letter first.
                width(of: piece, font: font) > room - 1 ? softHyphens(in: piece, language: language) : piece
            }.joined()
        }.joined(separator: " ")
    }

    /// The word with a soft hyphen wherever the system's dictionary for
    /// `language` allows a break, the dictionaries WebKit hyphenates with.
    static func softHyphens(in word: String, language: String) -> String {
        let locale = Locale(identifier: language) as CFLocale
        guard CFStringIsHyphenationAvailableForLocale(locale) else { return word }
        let text = word as NSString
        let whole = CFRange(location: 0, length: text.length)
        var breaks: [Int] = []
        var before = text.length
        while true {
            let at = CFStringGetHyphenationLocationBeforeIndex(word as CFString, before, whole, 0, locale, nil)
            guard at != kCFNotFound, at > 0, at < before else { break }
            breaks.append(at)
            before = at
        }
        let hyphenated = NSMutableString(string: word)
        for at in breaks { hyphenated.insert("\u{00AD}", at: at) }
        return hyphenated as String
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
