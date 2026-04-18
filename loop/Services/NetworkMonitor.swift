import Network
import Foundation

/// Wraps NWPathMonitor with @Observable so views can reactively gate
/// features that require a network connection (e.g. poster scanning).
@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "loop.network-monitor")

    private(set) var isConnected: Bool = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            // NWPathMonitor fires on its private queue; hop to main for @Observable.
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
