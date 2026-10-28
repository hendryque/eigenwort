import Foundation
import Testing
@testable import Folio

/// German Wiktionary has no definitions API, so its pages are read from
/// wikitext. These pin that reading on real entries.
struct WiktionaryTests {

    private func fixture(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/wiktionary-de-\(name).txt")
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test("A plain entry: part of speech with gender, one sense")
    func treibgut() throws {
        let page = Wiktionary.parseGerman(try fixture("Treibgut"))
        #expect(page == .entry([.init(
            partOfSpeech: "Substantiv, n",
            senses: ["Gegenstand, der auf dem Wasser/im Wasser von der Bewegung des Wassers bewegt wird"]
        )]))
    }

    @Test("Links read by their label, context labels stay, other blocks are not senses")
    func bank() throws {
        guard case .entry(let groups) = Wiktionary.parseGerman(try fixture("Bank")) else {
            Issue.record("no entry")
            return
        }
        #expect(groups.count >= 2)
        #expect(groups[0].partOfSpeech == "Substantiv, f")
        #expect(groups[0].senses.first == "Sitz- oder Ablagegelegenheit für mehrere Personen oder Dinge nebeneinander")
        #expect(groups[0].senses.count == Wiktionary.senseLimit)
        #expect(!groups[0].senses.contains("Bk."))
    }

    @Test("An inflected form points at its lemma")
    func inflectedForm() throws {
        #expect(Wiktionary.parseGerman(try fixture("Staemmen")) == .formOf("Stamm"))
    }

    @Test("Markup becomes text")
    func markup() {
        #expect(Wiktionary.plain("{{K|Sport|kurz für}} [[Auswechselbank]], [[Ersatzbank]]") == "(Sport, kurz für) Auswechselbank, Ersatzbank")
        #expect(Wiktionary.plain("lateinisch ''{{Ü|la|ovis}}''<ref>{{Ref-DWDS}}</ref>") == "lateinisch ovis")
        #expect(Wiktionary.plain(html: "<a href=\"/wiki/debris\">Debris</a> floating in a <a>river</a> or sea.") == "Debris floating in a river or sea.")
    }

    @Test("A selection becomes the word it asks about")
    func selection() {
        #expect(Wiktionary.word(fromSelection: " Treib\u{00AD}gut, ") == "Treibgut")
        #expect(Wiktionary.word(fromSelection: "„Auen“") == "Auen")
        #expect(Wiktionary.word(fromSelection: "one two three four") == nil)
        #expect(Wiktionary.word(fromSelection: " , ") == nil)
    }
}
