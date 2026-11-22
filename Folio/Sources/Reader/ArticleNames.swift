import Foundation

/// The names an open article answers to: the one asked for and the one a
/// redirect resolved it to, each as a link spells it (underscores) and as
/// search does (spaces). A bookmark or history row saved under any of them is
/// this article; new rows are saved under the resolved name, with spaces.
struct ArticleNames: Sendable {
    let all: [String]

    init(requested: String, resolved: String) {
        var names: [String] = []
        for name in [resolved, requested] {
            for form in [name.replacingOccurrences(of: "_", with: " "), name.replacingOccurrences(of: " ", with: "_")]
            where !names.contains(form) {
                names.append(form)
            }
        }
        all = names
    }

    func contains(_ title: String) -> Bool { all.contains(title) }
}
