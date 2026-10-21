import SwiftUI

enum Theme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case sepia
    case dark
    case debug
    case gimmick

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Auto"
        case .light: "Light"
        case .sepia: "Sepia"
        case .dark: "Dark"
        case .debug: "De:Bug"
        case .gimmick: "Gimmick"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light, .sepia, .debug, .gimmick: .light
        case .dark: .dark
        }
    }

    /// Auto is not a look of its own, so resolve it against the device before
    /// anything reads a colour. Without this the chrome followed the system
    /// while the article stayed light.
    func resolved(for scheme: ColorScheme) -> Theme {
        guard self == .system else { return self }
        return scheme == .dark ? .dark : .light
    }

    /// The `data-theme` attribute value the article CSS branches on. Resolve
    /// first: Auto has no stylesheet of its own.
    var cssDataTheme: String {
        switch self {
        case .system, .light: "light"
        case .sepia: "sepia"
        case .dark: "dark"
        case .debug: "debug"
        case .gimmick: "gimmick"
        }
    }

    /// Every colour this theme paints with, for SwiftUI and the reader alike.
    var palette: Palette {
        switch self {
        case .system, .light: .light
        case .sepia: .sepia
        case .dark: .dark
        case .debug: .debug
        case .gimmick: .gimmick
        }
    }

    /// SF Symbol for the reader's theme-cycle button.
    var iconName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .sepia: "book"
        case .dark: "moon"
        case .debug: "ant"
        case .gimmick: "gift"
        }
    }

    /// The page ground. Resolve Auto before reading it.
    var paper: Color { palette.backgroundColor }

    /// Bars, cards and sheets: a tone off the ground so a surface sitting on
    /// the page still reads as its own.
    var barBackground: Color { palette.cardColor }

    /// Reader faces and metrics, mirrored by ArticleLoadingPreview. A theme
    /// may swap the display face, so the numbers travel with it.
    var bodyFontName: String {
        switch self {
        case .debug: "Besley-Regular"
        case .gimmick: "ComicNeue-Regular"
        default: "EBGaramond-Regular"
        }
    }
    var bodyBoldFontName: String {
        switch self {
        case .debug: "Besley-Bold"
        case .gimmick: "ComicNeue-Bold"
        default: "EBGaramond-Bold"
        }
    }
    var titleFontName: String {
        switch self {
        case .debug: "BarlowSemiCondensed-Bold"
        case .gimmick: "AlfaSlabOne-Regular"
        default: "EBGaramond-Italic"
        }
    }
    /// The costumes: De:Bug sets Besley for Sentinel and Barlow for Fakt.
    /// Gimmick sets Comic Neue for the comic's lettering, since nothing records
    /// Yps's text face, and Alfa Slab One for the heavy slab of its red Y.
    var webFontFamilies: [String] {
        switch self {
        case .debug: [BundledFonts.besley, BundledFonts.barlow]
        case .gimmick: [BundledFonts.comicNeue, BundledFonts.alfaSlab]
        default: [BundledFonts.garamond]
        }
    }

    /// Faces the reader waits for before revealing. Gating on these rather than
    /// on `document.fonts.ready` keeps the reveal off the load event, which
    /// waits for every image too.
    var webFontQueries: [String] { BundledFonts.queries(forFamilies: webFontFamilies) }

    /// Sized by x-height, not by nominal px, so themes read the same size:
    /// Garamond's is 0.409em, Besley's 0.520 and Comic Neue's 0.494, so 14px
    /// of the slab and 15px of the comic match 18px of the garalde.
    var bodySize: Double {
        switch self {
        case .debug: 14
        case .gimmick: 15
        default: 18
        }
    }

    /// Set so the interlinear channel, the line height less the real ink,
    /// lands a little over one x-height. Ink runs 1.085em deep in Garamond,
    /// 1.204 in Besley and 1.045 in Comic Neue.
    var bodyLineHeight: Double {
        switch self {
        case .debug: 1.75
        case .gimmick: 1.57
        default: 1.52
        }
    }

    /// Tables and captions are em of the body, so a smaller body shrinks them.
    /// This scales them back to Light's: x-heights of the data face are 0.508em
    /// in San Francisco, 0.506 in Barlow and 0.494 in Comic Neue.
    var dataScale: Double {
        switch self {
        case .debug: 1.29
        case .gimmick: 1.23
        default: 1
        }
    }

    /// The cap in rem holds a fixed character count per face, so a wider face
    /// needs a wider one to reach the same measure. Only binds on iPad.
    var measureRem: Double {
        switch self {
        case .debug: 34
        case .gimmick: 23
        default: 26
        }
    }
    /// Gimmick sets display titles like the logo's Y: yellow, with a hard
    /// offset shadow in the rim's blue, rather than white over the scrim.
    var hasLogoTitles: Bool { self == .gimmick }

    var heroTitleSize: Double {
        switch self {
        case .debug: 42
        case .gimmick: 36
        default: 44.2
        }
    }
    var textOnlyTitleSize: Double {
        switch self {
        case .debug: 38
        case .gimmick: 32
        default: 40.8
        }
    }
}

private struct FolioThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    /// The reader theme, already resolved against the device so Auto never
    /// reaches a view. ContentView sets it once.
    var folioTheme: Theme {
        get { self[FolioThemeKey.self] }
        set { self[FolioThemeKey.self] = newValue }
    }
}
