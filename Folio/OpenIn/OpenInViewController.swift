import UIKit
import UniformTypeIdentifiers

/// "Open in Eigenwort" in the share sheet: takes the shared link, turns it
/// into the app's own URL and opens it. It shows nothing of its own unless
/// the link is not a Wikipedia article.
final class OpenInViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await open() }
    }

    private func open() async {
        let attachments = (extensionContext?.inputItems as? [NSExtensionItem])?.flatMap { $0.attachments ?? [] } ?? []
        let provider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
        guard let provider, let url = await url(from: provider), let link = WikipediaLink(url) else {
            decline()
            return
        }
        openApp(link.appURL)
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func url(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    /// An extension may not call UIApplication itself; the responder chain
    /// still ends in it.
    private func openApp(_ url: URL) {
        var responder: UIResponder? = self
        while let next = responder {
            if let application = next as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = next.next
        }
    }

    private func decline() {
        let alert = UIAlertController(
            title: "Not a Wikipedia article",
            message: "Eigenwort opens links to articles on wikipedia.org.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
        })
        present(alert, animated: true)
    }
}
