import Foundation
import SwiftData

/// Bookmarks, history and settings live in the default store, mirrored to
/// the reader's private iCloud database. The article cache is bulk and
/// rebuilds itself, so it stays in a store of its own on the device.
func makeFolioModelContainer() -> ModelContainer {
    let synced: [any PersistentModel.Type] = [Bookmark.self, HistoryEntry.self, SearchHistoryEntry.self, AppSettings.self]
    let local: [any PersistentModel.Type] = [CachedArticle.self]
    let configurations = [
        ModelConfiguration(schema: Schema(synced), cloudKitDatabase: .private("iCloud.me.scott.folio")),
        ModelConfiguration("Cache", schema: Schema(local), cloudKitDatabase: .none),
    ]
    do {
        return try ModelContainer(for: Schema(synced + local), configurations: configurations)
    } catch {
        fatalError("Failed to create Folio ModelContainer: \(error)")
    }
}
