import SwiftUI

struct SavedArticleRow: View {
    @Environment(\.folioTheme) private var theme
    let title: String
    let summary: String?
    let thumbnailURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RowThumbnail(url: thumbnailURL?.wikimediaResized(to: ThumbnailWidth.row), side: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.replacingOccurrences(of: "_", with: " "))
                    .font(theme.font(.text, size: 17, relativeTo: .body))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let summary, !summary.isEmpty {
                    Text(summary)
                        .font(theme.dataFont(.subheadline))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// A row's picture, square and rounded, on a tone off the ground until it
/// arrives. Over a card, pass the paper so the square still shows.
struct RowThumbnail: View {
    @Environment(\.folioTheme) private var theme
    let url: URL?
    let side: CGFloat
    var cornerRadius: CGFloat = 6
    var ground: Color?

    var body: some View {
        RemoteImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default: ground ?? theme.barBackground
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct EmptyStateView: View {
    @Environment(\.folioTheme) private var theme
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(theme.dataFont(.headline, .bold))
            Text(message)
                .font(theme.dataFont(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
