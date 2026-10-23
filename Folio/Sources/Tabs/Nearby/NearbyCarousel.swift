import SwiftUI

struct NearbyCarousel: View {
    @Environment(\.folioTheme) private var theme
    let articles: [NearbyArticle]
    @Binding var selectedID: Int?
    let language: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(articles) { article in
                        NearbyCard(article: article, language: language)
                            .id(article.id)
                            .frame(width: 280)
                            .onTapGesture {
                                selectedID = article.id
                            }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .onChange(of: selectedID) { _, newID in
                guard let newID else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
            .onChange(of: articles.first?.id) { _, newFirstID in
                guard let newFirstID else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(newFirstID, anchor: .leading)
                }
            }
        }
    }
}

private struct NearbyCard: View {
    @Environment(\.folioTheme) private var theme
    let article: NearbyArticle
    let language: String

    // The batch geosearch only carries thumbnails for its first 50 pages —
    // cards beyond that fetch their own lazily (LazyHStack: visible ones only).
    @State private var fetchedThumbnail: URL?

    private static let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        NavigationLink(value: ArticleDestination(title: article.title, language: language)) {
            HStack(spacing: 12) {
                RowThumbnail(url: article.thumbnailURL ?? fetchedThumbnail, side: 64, cornerRadius: 8, ground: theme.paper)

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title.replacingOccurrences(of: "_", with: " "))
                        .font(theme.font(.text, .medium, size: 16, relativeTo: .body))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let desc = article.description, !desc.isEmpty {
                        Text(desc)
                            .font(theme.dataFont(.caption))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(theme.barBackground, in: Self.shape)
            .overlay {
                // Gimmick's rim, as on its search oval.
                if let edge = theme.palette.edge {
                    Self.shape.strokeBorder(Color(rgb: edge), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .task(id: article.id) {
            guard article.thumbnailURL == nil, fetchedThumbnail == nil else { return }
            fetchedThumbnail = (try? await WikipediaClient.shared.summary(title: article.title, language: language))?
                .thumbnailURL?
                .wikimediaResized(to: ThumbnailWidth.row)
        }
    }
}
