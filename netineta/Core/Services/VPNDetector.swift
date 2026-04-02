import Foundation
import Network
#if canImport(Darwin)
import Darwin
#endif

@Observable
final class VPNDetector: @unchecked Sendable {

    static let shared = VPNDetector()

    private(set) var isVPNActive: Bool = false
    private var pathMonitor: NWPathMonitor?

    init() {
        checkInterfaces()
        startMonitoring()
    }

    func checkInterfaces() {
        isVPNActive = detectViaInterfaces()
    }

    private func detectViaInterfaces() -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let firstAddr = addrs else {
            return false
        }
        defer { freeifaddrs(addrs) }

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddr

        while let addr = current {
            let flags = Int32(addr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0

            if isUp && isRunning, let sockaddr = addr.pointee.ifa_addr {
                let family = sockaddr.pointee.sa_family
                // Only consider interfaces with an IPv4 or IPv6 address assigned
                if family == UInt8(AF_INET) || family == UInt8(AF_INET6) {
                    let name = String(cString: addr.pointee.ifa_name)
                    // ipsec* — IPSec VPN
                    // ppp* — PPTP/L2TP VPN
                    // utun* with IP — WireGuard, OpenVPN, IKEv2
                    //   BUT utun0 is often used by the system itself (e.g. Back to My Mac),
                    //   so we skip utun0 and only flag utun1+ as VPN indicators
                    if name.hasPrefix("ipsec") || name.hasPrefix("ppp") {
                        return true
                    }
                    if name.hasPrefix("utun") {
                        let suffix = name.dropFirst(4)
                        if let num = Int(suffix), num >= 1 {
                            return true
                        }
                    }
                }
            }

            current = addr.pointee.ifa_next
        }

        return false
    }

    private func startMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isVPNActive = self?.detectViaInterfaces() ?? false
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
        pathMonitor = monitor
    }
}
