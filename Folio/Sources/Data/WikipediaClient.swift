import Foundation

actor WikipediaClient {
    static let shared = WikipediaClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = [
                "User-Agent": UserAgent.value,
                "Accept-Language": "en, de;q=0.8"
            ]
            config.requestCachePolicy = .useProtocolCachePolicy
            config.timeoutIntervalForRequest = 20
            self.session = URLSession(configuration: config)
        }
        self.decoder = JSONDecoder()
    }

    func featured(language: String, date: Date = .now) async throws -> FeaturedFeed {
        try await get(.featured(language: language, date: date))
    }

    func summary(title: String, language: String) async throws -> ArticleSummary {
        try await get(.summary(title: title, language: language))
    }

    func random(language: String) async throws -> ArticleSummary {
        try await get(.random(language: language))
    }

    func mobileHTML(title: String, language: String) async throws -> String {
        let request = try buildRequest(.mobileHTML(title: title, language: language), accept: "text/html")
        let (data, response) = try await dataAsync(for: request)
        try validate(response: response)
        guard let html = String(data: data, encoding: .utf8) else {
            throw WikipediaError.empty
        }
        return html
    }

    func search(query: String, language: String, scope: SearchScope = .titlePrefix, limit: Int = SearchMerge.limit) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let response: SearchPagesResponse = try await get(
            .search(query: trimmed, language: language, limit: limit, scope: scope)
        )
        return response.results
    }

    func langlinks(title: String, language: String) async throws -> [LangLink] {
        struct Response: Decodable {
            struct Query: Decodable {
                struct Page: Decodable { let langlinks: [LangLink]? }
                let pages: [Page]?
            }
            let query: Query?
        }
        let response: Response = try await get(.langlinks(title: title, language: language))
        return response.query?.pages?.first?.langlinks ?? []
    }

    /// Articles like this one, by Wikipedia's own reckoning. The REST related
    /// endpoint is gone; CirrusSearch's morelike: gives the same, with the
    /// search rows' description and picture.
    func related(title: String, language: String) async throws -> [SearchResult] {
        let query = "morelike:" + title.replacingOccurrences(of: " ", with: "_")
        return try await search(query: query, language: language, scope: .fullText, limit: 6)
    }

    /// A selected word, from the dictionary in the article's language first,
    /// then the other; as written, then lowercased, as a sentence's first
    /// word would be. Nil when neither has an entry.
    func define(_ word: String, language: String) async throws -> DictionaryEntry? {
        let forms = [word, word.lowercased()].reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        let germanFirst = language == "de"
        for german in [germanFirst, !germanFirst] {
            for form in forms {
                let entry = german
                    ? try await germanEntry(form)
                    : try await englishEntry(form, language: language)
                if let entry { return entry }
            }
        }
        return nil
    }

    private func germanEntry(_ word: String, followingForm form: String? = nil) async throws -> DictionaryEntry? {
        struct Response: Decodable {
            struct Parse: Decodable { let title: String; let wikitext: String }
            let parse: Parse?
        }
        let response: Response = try await get(.wiktionaryWikitext(word: word, language: "de"))
        guard let page = response.parse else { return nil }
        switch Wiktionary.parseGerman(page.wikitext) {
        case .entry(let groups):
            guard let url = WikipediaEndpoint.wiktionaryURL(word: page.title, language: "de") else { return nil }
            return DictionaryEntry(word: page.title, selectedForm: form, groups: groups, url: url)
        case .formOf(let lemma) where form == nil:
            return try await germanEntry(lemma, followingForm: page.title)
        default:
            return nil
        }
    }

    private func englishEntry(_ word: String, language: String) async throws -> DictionaryEntry? {
        let usages: [String: [WiktionaryUsage]]
        do {
            usages = try await get(.wiktionaryDefinitions(word: word))
        } catch WikipediaError.httpStatus(404) {
            return nil
        }
        let groups = Wiktionary.groups(usages, language: language)
        guard !groups.isEmpty, let url = WikipediaEndpoint.wiktionaryURL(word: word, language: "en") else { return nil }
        return DictionaryEntry(word: word, groups: groups, url: url)
    }

    func mediaList(title: String, language: String) async throws -> [MediaItem] {
        let response: MediaListResponse = try await get(.mediaList(title: title, language: language))
        return response.galleryImages
    }

    func nearby(
        latitude: Double,
        longitude: Double,
        language: String,
        radiusMeters: Int = 10_000,
        limit: Int = 150
    ) async throws -> [NearbyArticle] {
        let response: NearbyResponse = try await get(
            .nearby(language: language, latitude: latitude, longitude: longitude, radiusMeters: radiusMeters, limit: limit)
        )
        return response.articles
    }

    private func get<T: Decodable>(_ endpoint: WikipediaEndpoint) async throws -> T {
        let request = try buildRequest(endpoint, accept: "application/json")
        let (data, response) = try await dataAsync(for: request)
        try validate(response: response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw WikipediaError.decoding(String(describing: error))
        }
    }

    private func buildRequest(_ endpoint: WikipediaEndpoint, accept: String) throws -> URLRequest {
        guard let url = endpoint.url() else { throw WikipediaError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        return request
    }

    private func dataAsync(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw WikipediaError.mapping(error)
        } catch {
            throw WikipediaError.transport(error.localizedDescription)
        }
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard 200..<300 ~= http.statusCode else {
            throw WikipediaError.httpStatus(http.statusCode)
        }
    }
}
