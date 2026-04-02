import Foundation
import SwiftData

@Model
final class FavoriteDomain {
    var id: UUID
    var domain: String
    var addedAt: Date
    var lastStatusRaw: String
    var lastCheckedAt: Date?
    var monitoringEnabled: Bool
    var notifyOnChange: Bool

    var lastStatus: BlockStatus {
        get { BlockStatus(rawValue: lastStatusRaw) ?? .unknown }
        set { lastStatusRaw = newValue.rawValue }
    }

    init(domain: String, status: BlockStatus = .unknown) {
        self.id = UUID()
        self.domain = domain
        self.addedAt = Date()
        self.lastStatusRaw = status.rawValue
        self.lastCheckedAt = nil
        self.monitoringEnabled = true
        self.notifyOnChange = true
    }
}
