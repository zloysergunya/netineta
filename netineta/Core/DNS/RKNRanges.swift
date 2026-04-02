import Foundation

struct RKNRanges: Sendable {

    struct CIDRRange: Sendable {
        let network: UInt32
        let mask: UInt32
    }

    static let ranges: [CIDRRange] = [
        CIDRRange(network: ipToUInt32("188.186.0.0"), mask: cidrMask(17)),
        CIDRRange(network: ipToUInt32("31.44.184.0"), mask: cidrMask(24)),
        CIDRRange(network: ipToUInt32("95.167.114.0"), mask: cidrMask(24)),
        CIDRRange(network: ipToUInt32("212.109.218.0"), mask: cidrMask(24)),
    ]

    static func isRKNAddress(_ ip: String) -> Bool {
        let ipValue = ipToUInt32(ip)
        guard ipValue != 0 else { return false }
        return ranges.contains { range in
            (ipValue & range.mask) == range.network
        }
    }

    private static func ipToUInt32(_ ip: String) -> UInt32 {
        let parts = ip.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4 else { return 0 }
        return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    }

    private static func cidrMask(_ prefix: Int) -> UInt32 {
        guard prefix > 0 && prefix <= 32 else { return 0 }
        return UInt32.max << (32 - prefix)
    }
}
