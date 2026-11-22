import Testing
@testable import Folio

/// Rows saved before a redirect was resolved, or under a link's underscores,
/// still belong to the article they name.
struct ArticleNamesTests {

    @Test("A bookmark saved under the redirect name is the article it reached")
    func redirectName() {
        let names = ArticleNames(requested: "Königsläuferspiel", resolved: "Läuferspiel")
        #expect(names.contains("Königsläuferspiel"))
        #expect(names.contains("Läuferspiel"))
    }

    @Test("A row a link saved with underscores matches when search opens it")
    func underscoreSpelling() {
        let names = ArticleNames(requested: "Fabiano Caruana", resolved: "Fabiano Caruana")
        #expect(names.contains("Fabiano_Caruana"))
        #expect(names.contains("Fabiano Caruana"))
    }

    @Test("Another article does not match, and each name is listed once")
    func onlyThisArticle() {
        let names = ArticleNames(requested: "Fabiano_Caruana", resolved: "Fabiano Caruana")
        #expect(!names.contains("Magnus Carlsen"))
        #expect(names.all == ["Fabiano Caruana", "Fabiano_Caruana"])
    }
}
