import Foundation
import SwiftData

@Model
final class SystemStatusSnapshot {
    var id: UUID
    var statusRaw: String
    var checkedAt: Date
    var blockedCorrect: Int
    var blockedTotal: Int
    var accessibleCorrect: Int
    var accessibleTotal: Int
    var isVPNActive: Bool

    var status: SystemStatus {
        get { SystemStatus(rawValue: statusRaw) ?? .unknown }
        set { statusRaw = newValue.rawValue }
    }

    init(result: SystemStatusResult, isVPNActive: Bool = false) {
        self.id = UUID()
        self.statusRaw = result.status.rawValue
        self.checkedAt = result.checkedAt
        self.blockedCorrect = result.blockedCorrect
        self.blockedTotal = result.blockedTotal
        self.accessibleCorrect = result.accessibleCorrect
        self.accessibleTotal = result.accessibleTotal
        self.isVPNActive = isVPNActive
    }
}
