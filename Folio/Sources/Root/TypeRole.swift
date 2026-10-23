import SwiftUI
import UIKit

/// The reader's three roles, for the SwiftUI surfaces: display for titles over
/// pictures, text for titles read down a list, data for what sits beside them.
enum TypeRole: CaseIterable {
    case display, text, data
}

enum TypeWeight: CaseIterable {
    case regular, medium, bold
}

extension Theme {
    /// The face a role takes, or nil for San Francisco. Faces without a medium
    /// cut fall back to regular; the magazines' display faces have one weight.
    func faceName(_ role: TypeRole, _ weight: TypeWeight = .regular) -> String? {
        switch (role, self) {
        case (.display, .debug): "BarlowSemiCondensed-Bold"
        case (.display, .gimmick): "AlfaSlabOne-Regular"
        case (.display, _):
            switch weight {
            case .regular: "EBGaramond-Italic"
            case .medium: "EBGaramond-MediumItalic"
            case .bold: "EBGaramond-BoldItalic"
            }
        case (.text, .debug), (.text, .gimmick): weight == .bold ? bodyBoldFontName : bodyFontName
        case (.text, _):
            switch weight {
            case .regular: "EBGaramond-Regular"
            case .medium: "EBGaramond-Medium"
            case .bold: "EBGaramond-Bold"
            }
        case (.data, .debug): weight == .regular ? "BarlowSemiCondensed-Regular" : "BarlowSemiCondensed-Bold"
        case (.data, .gimmick): weight == .regular ? "ComicNeue-Regular" : "ComicNeue-Bold"
        case (.data, _): nil
        }
    }

    /// A display or text face at Light's `size`, scaled to read the same size
    /// in this theme and with Dynamic Type from `style`.
    func font(_ role: TypeRole, _ weight: TypeWeight = .regular, size: Double, relativeTo style: Font.TextStyle) -> Font {
        guard let name = faceName(role, weight) else { return dataFont(style, weight) }
        return .custom(name, size: size * scale(role), relativeTo: style)
    }

    /// The data face at a text style's size: San Francisco itself where the
    /// theme keeps it, so those themes look exactly as they did.
    func dataFont(_ style: Font.TextStyle, _ weight: TypeWeight = .regular) -> Font {
        guard let name = faceName(.data, weight) else {
            return weight == .regular ? .system(style) : .system(style, weight: weight == .bold ? .semibold : .medium)
        }
        let size = UIFont.preferredFont(
            forTextStyle: style.uiTextStyle,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        ).pointSize
        return .custom(name, size: size * scale(.data), relativeTo: style)
    }

    /// Display sizes follow the hero titles, text the body, both set by
    /// x-height in Theme. Data matches San Francisco's 0.508em x-height:
    /// Barlow's 0.506 does already, Comic Neue's 0.494 needs 3% more.
    private func scale(_ role: TypeRole) -> Double {
        switch role {
        case .display: heroTitleSize / Theme.light.heroTitleSize
        case .text: bodySize / Theme.light.bodySize
        case .data: self == .gimmick ? 1.03 : 1
        }
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
