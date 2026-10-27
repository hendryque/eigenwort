import Foundation

/// An article named by a link: a Wikipedia page on a desktop or phone host,
/// or the app's own `eigenwort://language/Title`. Shared with the share
/// extension, so it depends on nothing but Foundation.
struct WikipediaLink: Equatable, Sendable {
    let title: String
    let language: String

    static let scheme = "eigenwort"

    init?(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased(), !host.isEmpty else { return nil }
        let title: String?
        let language: String?
        if scheme == Self.scheme {
            language = host
            title = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
        } else if scheme == "https" || scheme == "http" {
            // en.wikipedia.org, de.m.wikipedia.org; not www or the portal.
            var labels = host.split(separator: ".").map(String.init)
            guard labels.count >= 3, labels.suffix(2) == ["wikipedia", "org"] else { return nil }
            labels.removeLast(2)
            if labels.last == "m" { labels.removeLast() }
            guard labels.count == 1, labels[0] != "www" else { return nil }
            language = labels[0]
            if url.path.hasPrefix("/wiki/") {
                title = String(url.path.dropFirst("/wiki/".count))
            } else if url.path == "/w/index.php" {
                title = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first { $0.name == "title" }?.value
            } else {
                title = nil
            }
        } else {
            return nil
        }
        guard let title, let language, !language.isEmpty else { return nil }
        let name = title.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        self.title = name
        self.language = language
    }

    /// The app's own URL for the article, which the share extension opens.
    var appURL: URL {
        let path = title.replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        return URL(string: "\(Self.scheme)://\(language)/\(path)")!
    }
}
