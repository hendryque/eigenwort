import Foundation
import Testing
@testable import Folio

/// A link to "Königsläuferspiel" opens "Läuferspiel": the article is headed
/// by the name it has, with a note of the one that led there.
struct RedirectTests {

    private let page = #"<html><head><link rel="dc:isVersionOf" href="//de.wikipedia.org/wiki/L%C3%A4uferspiel"></head><body><p>Beim Läuferspiel handelt es sich um eine Eröffnung des Schachspiels.</p></body></html>"#

    @Test("The page names the article a redirect reached")
    func resolvedTitle() {
        #expect(ArticleHTML.resolvedTitle(in: page) == "Läuferspiel")
        #expect(ArticleHTML.resolvedTitle(in: "<html><body></body></html>") == nil)
    }

    @Test("A redirect is headed by the article it reached, with a note")
    func headerAndNote() {
        let html = ArticleHTML.render(
            rawHTML: page,
            theme: .light,
            fontScale: 1.0,
            systemScale: 1.0,
            language: "de",
            title: "Königsläuferspiel",
            articleURL: URL(string: "https://de.wikipedia.org/wiki/K%C3%B6nigsl%C3%A4uferspiel")!,
            heroImageURL: nil,
            heroFocalPoint: nil
        ).html
        #expect(html.contains(#"<h1 class="folio-title">Läuferspiel</h1>"#))
        #expect(html.contains(#"<p class="folio-redirect">Weitergeleitet von Königsläuferspiel</p>"#))
    }

    @Test("Names that differ only in form are no redirect")
    func sameArticle() {
        #expect(ArticleHTML.redirectNote(from: "fabiano_Caruana", to: "Fabiano Caruana", language: "de") == nil)
        #expect(ArticleHTML.redirectNote(from: "NYC", to: "New York City", language: "en") == "Redirected from NYC")
    }
}
