import Foundation
import Testing
@testable import Folio

/// The title sizes that once clipped: a German word wider than the column.
/// 335pt is the column of a 375pt phone.
struct TitleFitTests {

    private let column = 335.0

    @Test("A title breaks at spaces and after hyphens and dashes, nowhere else")
    func pieces() {
        #expect(TitleFit.pieces(of: "Baden-Württemberg") == ["Baden-", "Württemberg"])
        #expect(TitleFit.pieces(of: "Magnus Carlsen–Fabiano  Caruana") == ["Magnus", "Carlsen–", "Fabiano", "Caruana"])
        #expect(TitleFit.pieces(of: "Hinterfirmiansreut") == ["Hinterfirmiansreut"])
    }

    @Test("A title that fits keeps the theme's size")
    func shortTitleUnchanged() {
        for theme in Theme.allCases {
            #expect(TitleFit.size(theme.heroTitleSize, for: "Fabiano Caruana", in: theme, room: column) == theme.heroTitleSize)
        }
    }

    @Test("Gimmick's slab brings Hinterfirmiansreut down until it fits")
    func wideWordShrinks() {
        let theme = Theme.gimmick
        let size = TitleFit.size(theme.heroTitleSize, for: "Hinterfirmiansreut", in: theme, room: column)
        let widest = TitleFit.widestPiece(of: "Hinterfirmiansreut", fontName: theme.titleFontName, tracking: theme.titleTracking)
        #expect(size < theme.heroTitleSize)
        #expect(size * widest <= column + 0.01)
    }

    @Test("Past 60% the size holds, and the word is left to hyphenate")
    func floorHolds() {
        let title = "Grundstücksverkehrsgenehmigungszuständigkeitsübertragungsverordnung"
        for theme in Theme.allCases {
            let size = TitleFit.size(theme.heroTitleSize, for: title, in: theme, room: column)
            #expect(abs(size - theme.heroTitleSize * TitleFit.floor) < 0.001)
        }
    }

    @Test("Every width on the header is one a theme's stylesheet reads")
    func stylesheetsReadTheWidths() throws {
        let css = try ["article", "theme-debug", "theme-gimmick"].map { name in
            let url = try #require(Bundle.main.url(forResource: name, withExtension: "css"))
            return try String(contentsOf: url, encoding: .utf8)
        }.joined()
        let style = ArticleHTML.titleFitStyle("Bundesverfassungsgericht")
        let keys = style.split(separator: ";").compactMap { $0.split(separator: ":").first?.trimmingCharacters(in: .whitespaces) }
        #expect(keys.count == Set(Theme.allCases.map(\.titleFontName)).count)
        for key in keys {
            #expect(css.contains("var(\(key)"))
        }
    }
}
