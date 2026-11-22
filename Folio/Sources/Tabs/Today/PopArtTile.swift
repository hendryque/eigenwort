import SwiftUI

/// Gimmick's Today, set as pop art: each picture as real halftone in a pair of
/// the costume's colours, the title in the ink that reads on that pair.
struct PopArtTile: View {
    @Environment(\.folioTheme) private var theme
    @Environment(\.displayScale) private var displayScale
    let article: ArticleSummary
    let position: Int
    let language: String

    @State private var picture: UIImage?

    private var pair: PopArtPair {
        let pairs = PopArtPair.pairs(in: theme.palette)
        return pairs[position % pairs.count]
    }

    private var url: URL? { article.imageURL(width: ThumbnailWidth.tile) }

    var body: some View {
        GeometryReader { geo in
            let key = "\(url?.absoluteString ?? "flat")|\(pair.light)|\(pair.dark)|\(Int(geo.size.width))"
            ZStack(alignment: .bottomLeading) {
                Color(rgb: pair.light)
                if let shown = picture ?? Halftone.cached(key) {
                    // Cropped from the top, as the grid's tiles are.
                    Image(uiImage: shown)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                }
                LinearGradient(colors: [Color(rgb: pair.dark).opacity(0.9), .clear], startPoint: .bottom, endPoint: .center)
                VStack(alignment: .leading, spacing: 6) {
                    TileTitle(title: article.title, language: language, weight: .medium, size: 22)
                        .popArtInk(pair, theme: theme)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if let description = article.description, !description.isEmpty {
                        Text(description)
                            .font(theme.font(.text, .medium, size: 13, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(width: geo.size.width, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .task(id: key) {
                picture = await Halftone.picture(
                    at: url, fill: geo.size, scale: displayScale,
                    light: UIColor(Color(rgb: pair.light)), dark: UIColor(Color(rgb: pair.dark)), key: key
                )
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
    }
}

/// Two of Gimmick's colours, the dots in the dark one on the light one, and
/// whether the title reads better white than in the logo's yellow.
struct PopArtPair: Equatable {
    let light: UInt32
    let dark: UInt32
    let whiteTitle: Bool

    /// Only the palette's own colours: yellow, red, blue, cream and the band's
    /// purples. Yellow on red is the one pair the logo's ink does not read on.
    static func pairs(in palette: Palette) -> [PopArtPair] {
        let purples = palette.band ?? (palette.accent, palette.link)
        return [
            PopArtPair(light: palette.card, dark: palette.link, whiteTitle: false),
            PopArtPair(light: palette.card, dark: palette.accent, whiteTitle: true),
            PopArtPair(light: palette.background, dark: purples.0, whiteTitle: false),
            PopArtPair(light: palette.card, dark: purples.1, whiteTitle: false)
        ]
    }
}

private extension View {
    @ViewBuilder
    func popArtInk(_ pair: PopArtPair, theme: Theme) -> some View {
        if pair.whiteTitle {
            foregroundStyle(.white)
                .shadow(color: theme.palette.foregroundColor, radius: 0, x: 1.3, y: 1.3)
        } else {
            titleInk(theme, size: 22)
        }
    }
}
