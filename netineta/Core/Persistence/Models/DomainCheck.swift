import Foundation
import SwiftData

@Model
final class DomainCheck {
    var id: UUID
    var domain: String
    var statusRaw: String
    var checkedAt: Date
    var dnsResponseIP: String?
    var resolverUsed: String
    var isVPNActive: Bool

    var status: BlockStatus {
        get { BlockStatus(rawValue: statusRaw) ?? .unknown }
        set { statusRaw = newValue.rawValue }
    }

    init(domain: String, status: BlockStatus, checkedAt: Date = Date(),
         dnsResponseIP: String? = nil, resolverUsed: String = "77.88.8.8",
         isVPNActive: Bool = false) {
        self.id = UUID()
        self.domain = domain
        self.statusRaw = status.rawValue
        self.checkedAt = checkedAt
        self.dnsResponseIP = dnsResponseIP
        self.resolverUsed = resolverUsed
        self.isVPNActive = isVPNActive
    }
}
