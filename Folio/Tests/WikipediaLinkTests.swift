import Foundation
import Testing
@testable import Folio

/// A link pasted into search or handed over by the share extension names an
/// article, in its language, or nothing at all.
struct WikipediaLinkTests {

    private func link(_ string: String) -> WikipediaLink? { URL(string: string).flatMap(WikipediaLink.init) }

    @Test("Article links on the desktop and phone hosts")
    func pageLinks() {
        #expect(link("https://en.wikipedia.org/wiki/Bauhaus") == WikipediaLink(title: "Bauhaus", language: "en"))
        #expect(link("https://de.m.wikipedia.org/wiki/Loher_M%C3%BChle#Geschichte") == WikipediaLink(title: "Loher Mühle", language: "de"))
        #expect(link("http://en.wikipedia.org/w/index.php?title=Natalya_Voronina&action=view") == WikipediaLink(title: "Natalya Voronina", language: "en"))
    }

    @Test("Other links are not articles")
    func otherLinks() {
        #expect(link("https://www.wikipedia.org/") == nil)
        #expect(link("https://en.wikipedia.org/") == nil)
        #expect(link("https://commons.wikimedia.org/wiki/File:Bauhaus.jpg") == nil)
        #expect(link("https://example.com/wiki/Bauhaus") == nil)
        #expect(link("https://en.wikipedia.org/wiki/") == nil)
    }

    @Test("The app's own URL names the same article both ways")
    func ownScheme() throws {
        let original = try #require(link("https://de.wikipedia.org/wiki/Loher_M%C3%BChle"))
        #expect(original.appURL.absoluteString == "eigenwort://de/Loher_M%C3%BChle")
        #expect(WikipediaLink(original.appURL) == original)
        #expect(link("eigenwort://en/Metropolitan_Museum_of_Art") == WikipediaLink(title: "Metropolitan Museum of Art", language: "en"))
    }
}

private extension WikipediaLink {
    init(title: String, language: String) {
        self = WikipediaLink(URL(string: "\(WikipediaLink.scheme)://\(language)/\(title.replacingOccurrences(of: " ", with: "_"))")!)!
    }
}
