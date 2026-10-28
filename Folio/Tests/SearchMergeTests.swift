import Foundation
import Testing
@testable import Folio

/// Prefix search alone could not find "Nationalpark Donau-Auen" for "donau
/// auen". These pin when full text joins in and which list leads.
struct SearchMergeTests {

    private func result(_ title: String) -> SearchResult {
        SearchResult(title: title, summary: "", thumbnailURL: nil)
    }

    @Test("Full text joins once there is a phrase or four letters")
    func whenFullTextIsAsked() {
        #expect(!SearchMerge.wantsFullText("do"))
        #expect(!SearchMerge.wantsFullText("Bau"))
        #expect(SearchMerge.wantsFullText("Bauh"))
        #expect(SearchMerge.wantsFullText("donau auen"))
    }

    @Test("A phrase leads with full-text hits, a fragment with completions")
    func whoLeads() {
        let prefix = [result("Donau-Auen"), result("Donauauen"), result("Donau-Arena")]
        let fullText = [result("Nationalpark Donau-Auen"), result("Donau"), result("Donau-Auen")]
        let phrase = SearchMerge.merged(query: "donau auen", prefix: prefix, fullText: fullText)
        #expect(phrase.map(\.title) == ["Nationalpark Donau-Auen", "Donau", "Donau-Auen", "Donauauen", "Donau-Arena"])
        let fragment = SearchMerge.merged(query: "donau", prefix: prefix, fullText: fullText)
        #expect(fragment.map(\.title) == ["Donau-Auen", "Donauauen", "Donau-Arena", "Nationalpark Donau-Auen", "Donau"])
    }

    @Test("The merged list keeps to the limit")
    func limit() {
        let many = (0..<20).map { result("Title \($0)") }
        #expect(SearchMerge.merged(query: "title", prefix: many, fullText: many.reversed()).count == SearchMerge.limit)
    }
}
