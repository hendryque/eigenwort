import Foundation

/// Prefix search is instant but knows only how a title begins; full text
/// knows the whole title ("Nationalpark Donau-Auen" for "donau auen") but is
/// slower and noise on two letters. When to ask the second, and who leads.
enum SearchMerge {
    static let limit = 12

    /// Full text is worth asking once there is a phrase or four letters.
    static func wantsFullText(_ query: String) -> Bool {
        query.contains(" ") || query.count >= 4
    }

    /// A phrase is a name the reader knows, so full-text hits lead; a single
    /// fragment is a title being completed, so the completions do.
    static func fullTextLeads(_ query: String) -> Bool {
        query.contains(" ")
    }

    static func merged(query: String, prefix: [SearchResult], fullText: [SearchResult]) -> [SearchResult] {
        let ordered = fullTextLeads(query) ? fullText + prefix : prefix + fullText
        var seen = Set<String>()
        return Array(ordered.filter { seen.insert($0.title).inserted }.prefix(limit))
    }
}
