import Foundation
import Network

@Observable
final class VPNDetector: @unchecked Sendable {

    static let shared = VPNDetector()

    private(set) var isVPNActive: Bool = false
    private(set) var isCellular: Bool = false

    private let queue = DispatchQueue(label: "vpn.detector")
    private let monitor = NWPathMonitor()
    private var currentPath: NWPath?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let wasVPN = self.currentPath?.usesInterfaceType(.other) ?? false
            let isVPN = path.usesInterfaceType(.other)
            let cellular = path.usesInterfaceType(.cellular)

            self.currentPath = path

            if path.status == .satisfied {
                DispatchQueue.main.async {
                    self.isVPNActive = isVPN
                    self.isCellular = cellular
                }
            }
        }
        monitor.start(queue: queue)
    }
}
