import Foundation

/// A word as a dictionary gives it: its senses, grouped by part of speech.
struct DictionaryEntry: Sendable, Equatable {
    struct Group: Sendable, Equatable {
        let partOfSpeech: String
        let senses: [String]
    }

    let word: String
    /// The form that was selected, when the entry is its lemma's.
    var selectedForm: String?
    let groups: [Group]
    let url: URL
}

/// English Wiktionary's REST definitions, keyed by language code.
struct WiktionaryUsage: Decodable, Sendable {
    struct Definition: Decodable, Sendable { let definition: String }
    let partOfSpeech: String
    let definitions: [Definition]
}

/// Reading Wiktionary. English Wiktionary serves definitions as JSON for any
/// language's words; German Wiktionary has no such endpoint, but its pages
/// follow a strict house template, so their wikitext reads reliably.
enum Wiktionary {
    static let groupLimit = 4
    static let senseLimit = 5

    /// The word a selection asks about: soft hyphens and edge punctuation
    /// gone, nothing longer than a short phrase.
    static func word(fromSelection selection: String) -> String? {
        let trimmed = selection
            .replacingOccurrences(of: "\u{00AD}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))
        guard !trimmed.isEmpty, trimmed.count <= 40, trimmed.split(separator: " ").count <= 3 else { return nil }
        return trimmed
    }

    enum GermanPage: Equatable {
        case entry([DictionaryEntry.Group])
        /// An inflected form whose page only points at its lemma.
        case formOf(String)
        case none
    }

    /// The German section's senses, by the part of speech its headings name.
    static func parseGerman(_ wikitext: String) -> GermanPage {
        var groups: [DictionaryEntry.Group] = []
        var lemma: String?
        var inGerman = false, inSenses = false
        var partOfSpeech = "", senses: [String] = []
        func close() {
            if !senses.isEmpty { groups.append(.init(partOfSpeech: partOfSpeech, senses: Array(senses.prefix(senseLimit)))) }
            senses = []
        }
        for raw in wikitext.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("==") && !line.hasPrefix("===") {
                close()
                inSenses = false
                inGerman = line.contains("{{Sprache|Deutsch}}")
                continue
            }
            guard inGerman else { continue }
            if line.hasPrefix("===") && !line.hasPrefix("====") {
                close()
                inSenses = false
                partOfSpeech = heading(line)
            } else if line.hasPrefix("=") {
                inSenses = false
            } else if line == "{{Bedeutungen}}" {
                inSenses = true
            } else if line.hasPrefix("{{") {
                inSenses = false
                if lemma == nil, let match = line.firstMatch(of: /^\{\{Grundformverweis[^|]*\|([^|}]+)/) {
                    lemma = String(match.1)
                }
            } else if inSenses, let match = line.firstMatch(of: /^:\[[^\]]+\]\s*(.+)$/) {
                let sense = plain(String(match.1))
                if !sense.isEmpty { senses.append(sense) }
            }
        }
        close()
        if !groups.isEmpty { return .entry(Array(groups.prefix(groupLimit))) }
        return lemma.map(GermanPage.formOf) ?? .none
    }

    /// `=== {{Wortart|Substantiv|Deutsch}}, {{f}} ===` reads "Substantiv, f".
    private static func heading(_ line: String) -> String {
        let kinds = line.matches(of: /\{\{Wortart\|([^|}]+)/).map { String($0.1) }
        let genders = line.matches(of: /\{\{([mfn])\}\}/).map { String($0.1) }
        return ([kinds.joined(separator: " · ")] + genders).filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// Wiki markup to text: links by their label, context labels kept in
    /// parentheses, translations by their word, everything else dropped.
    static func plain(_ wikitext: String) -> String {
        var text = wikitext
            .replacing(/<ref[^>]*\/>/, with: "")
            .replacing(/<ref[^>]*>[\s\S]*?<\/ref>/, with: "")
            .replacing(/\[\[(?:[^\]|]*\|)?([^\]]*)\]\]/) { String($0.1) }
            .replacing(/\[https?:\/\/\S+ ([^\]]*)\]/) { String($0.1) }
        // Innermost first, so a template inside another is read before it.
        while let match = text.firstMatch(of: /\{\{([^{}]*)\}\}/) {
            let parts = match.1.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            let arguments = parts.dropFirst().filter { !$0.isEmpty && !$0.contains("=") }
            let replacement = switch parts.first {
            case "K": "(" + arguments.joined(separator: ", ") + ")"
            case "Ü", "Üt": arguments.dropFirst().first ?? ""
            default: ""
            }
            text.replaceSubrange(match.range, with: replacement)
        }
        return tidy(text.replacing("'''", with: "").replacing("''", with: ""))
    }

    /// English Wiktionary's definitions arrive as HTML fragments.
    static func plain(html: String) -> String {
        tidy(html
            .replacing(/<[^>]+>/, with: "")
            .replacing("&amp;", with: "&").replacing("&lt;", with: "<").replacing("&gt;", with: ">")
            .replacing("&quot;", with: "\"").replacing("&#39;", with: "'"))
    }

    private static func tidy(_ text: String) -> String {
        text
            .replacing(/<[^>]+>/, with: "")
            .replacing("&nbsp;", with: " ")
            .replacing(/\s+/, with: " ")
            .replacing(/\s+([,.;:)])/) { String($0.1) }
            .trimmingCharacters(in: .whitespaces)
    }

    /// The usages for the language asked for, else English, else any.
    static func groups(_ usages: [String: [WiktionaryUsage]], language: String) -> [DictionaryEntry.Group] {
        let key = [language, "en"].first { usages[$0] != nil } ?? usages.keys.sorted().first
        return (key.flatMap { usages[$0] } ?? []).compactMap { usage in
            let senses = usage.definitions.map { plain(html: $0.definition) }.filter { !$0.isEmpty }
            return senses.isEmpty ? nil : .init(partOfSpeech: usage.partOfSpeech, senses: Array(senses.prefix(senseLimit)))
        }
        .prefix(groupLimit)
        .map { $0 }
    }
}
