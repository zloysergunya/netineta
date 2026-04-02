import Foundation
import SwiftData

enum AppDatabase {

    static let appGroupID = "group.com.kotov.netineta"

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            DomainCheck.self,
            FavoriteDomain.self,
            SystemStatusSnapshot.self,
        ])

        let storeURL: URL
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            storeURL = groupURL.appendingPathComponent("runetmonitor.store")
        } else {
            // Fallback for simulator / no App Group entitlement
            storeURL = URL.applicationSupportDirectory.appendingPathComponent("runetmonitor.store")
        }

        let config = ModelConfiguration(
            "RuNetMonitor",
            url: storeURL
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
