import Foundation

struct DomainCheckResult: Sendable {
    let domain: String
    let status: BlockStatus
    let yandexIPs: [String]
    let cloudflareIPs: [String]
    let resolverUsed: String
    let isVPNActive: Bool
    let checkedAt: Date
}

actor DomainChecker {

    static let shared = DomainChecker()

    private let yandexDNS = "77.88.8.8"
    private let cloudflareDNS = "1.1.1.1"

    func check(_ domain: String, timeout: TimeInterval = 5) async -> DomainCheckResult {
        let isVPN = await MainActor.run { VPNDetector.shared.isVPNActive }
        let checkedAt = Date()

        // Resolve via both DNS servers in parallel
        async let yandexResult = resolveQuietly(domain: domain, server: yandexDNS, timeout: timeout)
        async let cloudflareResult = resolveQuietly(domain: domain, server: cloudflareDNS, timeout: timeout)

        let yandex = await yandexResult
        let cloudflare = await cloudflareResult

        let yandexIPs = yandex?.addresses ?? []
        let cloudflareIPs = cloudflare?.addresses ?? []

        // Determine status
        let status: BlockStatus

        if yandex == nil {
            // Yandex timeout
            status = .unknown
        } else if yandex!.isNXDomain && !(cloudflare?.isNXDomain ?? true) {
            // Yandex says NXDOMAIN, Cloudflare has records → DNS block
            status = .blockedDNS
        } else if yandexIPs.contains(where: { RKNRanges.isRKNAddress($0) }) {
            // Yandex returned RKN stub IP
            status = .blockedDNS
        } else if !yandexIPs.isEmpty {
            // DNS looks normal — check HTTP
            let httpOk = await HTTPChecker.shared.check(domain: domain, timeout: timeout)
            status = httpOk ? .accessible : .blockedDPI
        } else if yandex!.isNXDomain && (cloudflare?.isNXDomain ?? true) {
            // Both say NXDOMAIN — domain doesn't exist
            status = .accessible
        } else {
            status = .unknown
        }

        return DomainCheckResult(
            domain: domain,
            status: status,
            yandexIPs: yandexIPs,
            cloudflareIPs: cloudflareIPs,
            resolverUsed: yandexDNS,
            isVPNActive: isVPN,
            checkedAt: checkedAt
        )
    }

    private func resolveQuietly(domain: String, server: String, timeout: TimeInterval) async -> DNSResolver.ResolveResult? {
        do {
            return try await DNSResolver.shared.resolve(domain: domain, server: server, timeout: timeout)
        } catch {
            return nil
        }
    }
}
