import SwiftUI

/// What a selection asks Wiktionary about, and in which article's language.
struct WordLookup: Identifiable, Hashable {
    let word: String
    let language: String
    var id: String { "\(language)|\(word)" }
}

/// A selected word, asked of Wiktionary: its senses by part of speech and a
/// link to the entry. A sheet, as iOS's own Look Up is.
struct WordLookupSheet: View {
    let lookup: WordLookup
    let theme: Theme

    private enum Phase {
        case loading, found(DictionaryEntry), missing, failed(LoadFailure)
    }

    @State private var phase = Phase.loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.paper)
        .preferredColorScheme(theme.colorScheme)
        .environment(\.folioTheme, theme)
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            headword(lookup.word)
            ProgressView()
                .padding(.top, 24)
                .frame(maxWidth: .infinity)
        case .found(let entry):
            headword(entry.word)
            if let form = entry.selectedForm {
                note("\(form) is a form of \(entry.word)")
            }
            ForEach(entry.groups.indices, id: \.self) { index in
                group(entry.groups[index])
            }
            Link("\(entry.word) on Wiktionary", destination: entry.url)
                .font(theme.dataFont(.subheadline))
                .foregroundStyle(theme.palette.accentColor)
                .padding(.top, 22)
        case .missing:
            headword(lookup.word)
            note("Wiktionary has no entry for this word.")
        case .failed(let failure):
            headword(lookup.word)
            LoadFailureView(headline: "Couldn't ask Wiktionary", failure: failure, retry: { Task { await load() } }, isCompact: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }

    private func headword(_ word: String) -> some View {
        Text(word)
            .font(theme.font(.text, .bold, size: 30, relativeTo: .title))
            .foregroundStyle(theme.palette.foregroundColor)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(theme.dataFont(.subheadline))
            .foregroundStyle(theme.palette.secondaryColor)
            .padding(.top, 4)
    }

    private func group(_ group: DictionaryEntry.Group) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.partOfSpeech)
                .font(theme.dataFont(.subheadline))
                .foregroundStyle(theme.palette.secondaryColor)
                .padding(.bottom, 2)
            ForEach(group.senses.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1)")
                        .foregroundStyle(theme.palette.accentColor)
                        .frame(minWidth: 12, alignment: .trailing)
                    Text(group.senses[index])
                        .foregroundStyle(theme.palette.foregroundColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(theme.font(.text, size: 19, relativeTo: .body))
            }
        }
        .padding(.top, 18)
    }

    private func load() async {
        phase = .loading
        do {
            let entry = try await WikipediaClient.shared.define(lookup.word, language: lookup.language)
            phase = entry.map(Phase.found) ?? .missing
        } catch {
            guard let failure = LoadFailure(error) else { return }
            phase = .failed(failure)
        }
    }
}
