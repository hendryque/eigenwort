import Foundation
import Testing
import UIKit
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
            #expect(TitleFit.size(theme.heroTitleSize, fontScale: 1, for: "Fabiano Caruana", in: theme, room: column) == theme.heroTitleSize)
        }
    }

    @Test("Gimmick's slab brings Hinterfirmiansreut down until it fits")
    func wideWordShrinks() {
        let theme = Theme.gimmick
        let size = TitleFit.size(theme.heroTitleSize, fontScale: 1, for: "Hinterfirmiansreut", in: theme, room: column)
        let widest = TitleFit.widestPiece(of: "Hinterfirmiansreut", fontName: theme.titleFontName, tracking: theme.titleTracking)
        #expect(size < theme.heroTitleSize)
        #expect(size * widest <= column + 0.01)
    }

    private let giant = "Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz"

    @Test("Past 60% of the theme's size the size holds, and the word is left to hyphenate")
    func floorHolds() {
        for theme in Theme.allCases {
            let size = TitleFit.size(theme.heroTitleSize, fontScale: 1, for: giant, in: theme, room: column)
            #expect(abs(size - theme.heroTitleSize * TitleFit.floor) < 0.001)
        }
    }

    @Test("Enlarged text does not raise the floor: the word stays whole")
    func enlargedKeepsWordWhole() {
        let theme = Theme.gimmick
        let title = "Bundesverfassungsgericht"
        let size = TitleFit.size(theme.heroTitleSize, fontScale: 1.2, for: title, in: theme, room: column)
        let widest = TitleFit.widestPiece(of: title, fontName: theme.titleFontName, tracking: theme.titleTracking)
        #expect(size * widest <= column)
        #expect(size > theme.heroTitleSize * TitleFit.floor)
    }

    @Test("A title never drops below the text it heads")
    func neverBelowText() {
        let theme = Theme.light
        let size = TitleFit.size(theme.heroTitleSize, fontScale: 1.6, for: giant, in: theme, room: column)
        #expect(abs(size - theme.bodySize * 1.6) < 0.001)
    }

    @Test("In a list row only a word too wide for it gets soft hyphens")
    func rowHyphenation() throws {
        let font = try #require(UIFont(name: "EBGaramond-Bold", size: 19))
        let row = 280.0
        #expect(TitleFit.hyphenatingTooWide("Fabiano Caruana", font: font, room: row, language: "de") == "Fabiano Caruana")
        let title = "Das \(giant)"
        let set = TitleFit.hyphenatingTooWide(title, font: font, room: row, language: "de")
        #expect(set.hasPrefix("Das "))
        #expect(set.contains("\u{00AD}"))
        #expect(set.replacingOccurrences(of: "\u{00AD}", with: "") == title)
    }

    @Test("A tile title keeps its size, gives up to 15% for a long word, then holds")
    func tileShare() {
        #expect(TitleFit.share(widest: 100, room: 160, floor: TileTitle.floor) == 1)
        #expect(abs(TitleFit.share(widest: 170, room: 160, floor: TileTitle.floor) - 159.0 / 170) < 1e-9)
        #expect(TitleFit.share(widest: 300, room: 160, floor: TileTitle.floor) == TileTitle.floor)
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
