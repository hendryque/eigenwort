import SwiftUI

/// De:Bug's Today, set as a contents page on newsprint: the picture in
/// greyscale, under it a magenta number, the title in Barlow and its line in
/// Besley, an ink rule over each entry. The title never sits on a picture.
struct ContentsEntry: View {
    @Environment(\.folioTheme) private var theme
    let article: ArticleSummary
    let position: Int
    let language: String

    private var palette: Palette { theme.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Without a picture the grey still holds the row's rhythm: the ink
            // thinned, since the card tone is nearly the paper itself.
            palette.foregroundColor.opacity(0.12)
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .overlay(alignment: .top) {
                    RemoteImage(url: article.imageURL(width: ThumbnailWidth.tile)) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill().grayscale(1).contrast(1.1)
                        } else {
                            Color.clear
                        }
                    }
                }
                .clipped()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%02d", position + 1))
                    .font(theme.font(.display, size: 15, relativeTo: .caption))
                    .foregroundStyle(Color(rgb: palette.link))
                TileTitle(title: article.title, language: language, size: 19)
                    .foregroundStyle(palette.foregroundColor)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let description = article.description, !description.isEmpty {
                Text(description)
                    .font(theme.font(.text, size: 11, relativeTo: .caption))
                    .foregroundStyle(palette.secondaryColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.foregroundColor).frame(height: 1.5)
        }
    }
}
