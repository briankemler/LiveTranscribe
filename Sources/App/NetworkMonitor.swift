import Foundation
import Network
import Observation

/// Reports whether the device has a usable connection and, specifically, whether it's on Wi-Fi.
/// `TranscriptionService` reads `isOnWifi` before kicking off a model download — we don't burn
/// the user's cellular data on a 244 MB pull unless they explicitly opt in.
@MainActor
@Observable
final class NetworkMonitor {

    enum Reachability: Sendable, Equatable {
        case none
        case wifi
        /// Any non-Wi-Fi reachable path: cellular, hotspot, wired. We treat them all as "expensive".
        case cellular
    }

    private(set) var reachability: Reachability = .none

    var isOnWifi: Bool { reachability == .wifi }
    var isConnected: Bool { reachability != .none }

    private let monitor = NWPathMonitor()

    init() {
        let queue = DispatchQueue(label: "com.briankemler.LiveTranscribe.NetworkMonitor")
        monitor.pathUpdateHandler = { [weak self] path in
            let new: Reachability
            if path.status != .satisfied {
                new = .none
            } else if path.usesInterfaceType(.wifi) {
                new = .wifi
            } else {
                new = .cellular
            }
            Task { @MainActor [weak self] in
                self?.reachability = new
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
