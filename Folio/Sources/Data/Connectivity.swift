import Foundation
import Network

/// Whether the device has a usable path, so a failure from being offline can
/// retry by itself the moment the connection comes back.
@MainActor @Observable
final class Connectivity {
    static let shared = Connectivity()

    private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { path in
            let isOnline = path.status == .satisfied
            Task { @MainActor in Connectivity.shared.isOnline = isOnline }
        }
        monitor.start(queue: DispatchQueue(label: "Connectivity"))
    }
}
