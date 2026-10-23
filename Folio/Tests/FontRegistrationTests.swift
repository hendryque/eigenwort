import Foundation
import Testing
import UIKit
@testable import Folio

/// Fonts are listed twice, BundledFonts.faces for the reader and UIAppFonts
/// for SwiftUI. These keep both lists, the bundle and the views in step, so a
/// face cannot be half-added or linger unused as Barlow Medium once did.
struct FontRegistrationTests {

    private var registered: Set<String> {
        Set(Bundle.main.object(forInfoDictionaryKey: "UIAppFonts") as? [String] ?? [])
    }

    private var bundled: Set<String> {
        let urls = ["otf", "ttf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        return Set(urls.map(\.lastPathComponent))
    }

    /// The app's sources, read from the host: the simulator can see them.
    private var sourceFiles: [URL] {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let walker = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        return (walker?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }

    /// PostScript names SwiftUI asks for: each theme's, each role's, and any a
    /// view names directly. The files are named after their PostScript names.
    private var namedInCode: Set<String> {
        var names = Set(Theme.allCases.flatMap { [$0.bodyFontName, $0.bodyBoldFontName, $0.titleFontName] })
        for theme in Theme.allCases {
            for role in TypeRole.allCases {
                names.formUnion(TypeWeight.allCases.compactMap { theme.faceName(role, $0) })
            }
        }
        for file in sourceFiles {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            for match in text.matches(of: #/\.custom\("([^"]+)"/#) { names.insert(String(match.1)) }
        }
        return names
    }

    @Test("Every font file in the bundle is registered, and nothing else is")
    func registrationMatchesTheBundle() {
        #expect(!bundled.isEmpty)
        #expect(registered == bundled, "registered but missing: \(registered.subtracting(bundled)), bundled but unregistered: \(bundled.subtracting(registered))")
    }

    @Test("Every face SwiftUI names resolves")
    func namedFacesResolve() throws {
        try #require(!sourceFiles.isEmpty, "the sources are not readable from the test host")
        for name in namedInCode {
            #expect(UIFont(name: name, size: 12) != nil, "\(name) is not registered")
        }
    }

    @Test("Every bundled face is used by the reader or by SwiftUI")
    func noFaceIsDeadWeight() throws {
        try #require(!sourceFiles.isEmpty, "the sources are not readable from the test host")
        let used = Set(BundledFonts.faces.map(\.file)).union(namedInCode)
        for file in bundled {
            let name = (file as NSString).deletingPathExtension
            #expect(used.contains(name), "\(file) is bundled but nothing uses it")
        }
    }
}
