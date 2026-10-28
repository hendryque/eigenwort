import Foundation

/// Titles that begin with the query, or hits anywhere in title and text.
enum SearchScope: Sendable {
    case titlePrefix, fullText
}

enum WikipediaEndpoint {
    case featured(language: String, date: Date)
    case summary(title: String, language: String)
    case mobileHTML(title: String, language: String)
    case random(language: String)
    case search(query: String, language: String, limit: Int, scope: SearchScope)
    case langlinks(title: String, language: String)
    case related(title: String, language: String)
    case nearby(language: String, latitude: Double, longitude: Double, radiusMeters: Int, limit: Int)
    case mediaList(title: String, language: String)

    func url() -> URL? {
        switch self {
        case .featured(let language, let date):
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy/MM/dd"
            let path = formatter.string(from: date)
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/feed/featured/\(path)")

        case .summary(let title, let language):
            guard let escaped = Self.encodePathTitle(title) else { return nil }
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/page/summary/\(escaped)")

        case .mobileHTML(let title, let language):
            guard let escaped = Self.encodePathTitle(title) else { return nil }
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/page/mobile-html/\(escaped)")

        case .random(let language):
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/page/random/summary")

        case .search(let query, let language, let limit, let scope):
            // A search generator + prop=pageimages|description gives us titles,
            // short descriptions, and row-sized thumbnails in one round trip.
            // The two generators take the same parameters under their own prefix.
            let (generator, p) = scope == .titlePrefix ? ("prefixsearch", "gps") : ("search", "gsr")
            var components = URLComponents(string: "https://\(language).wikipedia.org/w/api.php")
            components?.queryItems = [
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "formatversion", value: "2"),
                URLQueryItem(name: "generator", value: generator),
                URLQueryItem(name: "\(p)search", value: query),
                URLQueryItem(name: "\(p)limit", value: String(limit)),
                URLQueryItem(name: "\(p)namespace", value: "0"),
                URLQueryItem(name: "prop", value: "pageimages|description"),
                URLQueryItem(name: "piprop", value: "thumbnail"),
                URLQueryItem(name: "pithumbsize", value: String(ThumbnailWidth.row))
            ]
            return components?.url

        case .langlinks(let title, let language):
            var components = URLComponents(string: "https://\(language).wikipedia.org/w/api.php")
            components?.queryItems = [
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "langlinks"),
                URLQueryItem(name: "titles", value: title),
                URLQueryItem(name: "lllimit", value: "50"),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "formatversion", value: "2"),
                URLQueryItem(name: "redirects", value: "1")
            ]
            return components?.url

        case .related(let title, let language):
            guard let escaped = Self.encodePathTitle(title) else { return nil }
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/page/related/\(escaped)")

        case .mediaList(let title, let language):
            guard let escaped = Self.encodePathTitle(title) else { return nil }
            return URL(string: "https://\(language).wikipedia.org/api/rest_v1/page/media-list/\(escaped)")

        case .nearby(let language, let lat, let lon, let radius, let limit):
            var components = URLComponents(string: "https://\(language).wikipedia.org/w/api.php")
            components?.queryItems = [
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "formatversion", value: "2"),
                URLQueryItem(name: "prop", value: "pageimages|description|coordinates"),
                URLQueryItem(name: "piprop", value: "thumbnail"),
                URLQueryItem(name: "pithumbsize", value: String(ThumbnailWidth.row)),
                URLQueryItem(name: "coprop", value: "type|name|dim|country|region"),
                URLQueryItem(name: "colimit", value: String(limit)),
                URLQueryItem(name: "generator", value: "geosearch"),
                URLQueryItem(name: "ggscoord", value: "\(lat)|\(lon)"),
                URLQueryItem(name: "ggsradius", value: String(radius)),
                URLQueryItem(name: "ggslimit", value: String(limit))
            ]
            return components?.url
        }
    }

    static func articleURL(title: String, language: String) -> URL? {
        guard let escaped = encodePathTitle(title) else { return nil }
        return URL(string: "https://\(language).wikipedia.org/wiki/\(escaped)")
    }

    static func historyURL(title: String, language: String) -> URL? {
        var components = URLComponents(string: "https://\(language).wikipedia.org/w/index.php")
        components?.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "action", value: "history")
        ]
        return components?.url
    }

    private static func encodePathTitle(_ title: String) -> String? {
        let underscored = title.replacingOccurrences(of: " ", with: "_")
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        return underscored.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
