import Foundation
import SwiftData
import SwiftUI

enum HistoryRetention: String, CaseIterable {
    case week = "7 дней"
    case month = "30 дней"
    case threeMonths = "90 дней"
    case forever = "Бессрочно"

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .forever: return nil
        }
    }
}

enum DNSTimeout: Int, CaseIterable {
    case three = 3
    case five = 5
    case ten = 10

    var label: String { "\(rawValue) сек" }
}

enum MonitoringInterval: Int, CaseIterable {
    case one = 1
    case three = 3
    case six = 6
    case twelve = 12

    var label: String { "\(rawValue) ч" }
}

@Observable
@MainActor
final class SettingsViewModel {

    var dnsTimeout: DNSTimeout {
        get { DNSTimeout(rawValue: UserDefaults.standard.integer(forKey: "dnsTimeout")) ?? .five }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "dnsTimeout") }
    }

    var monitoringInterval: MonitoringInterval {
        get { MonitoringInterval(rawValue: UserDefaults.standard.integer(forKey: "monitoringInterval")) ?? .three }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "monitoringInterval") }
    }

    var historyRetention: HistoryRetention {
        get { HistoryRetention(rawValue: UserDefaults.standard.string(forKey: "historyRetention") ?? "") ?? .month }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "historyRetention") }
    }

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    var notifyDomainChanges: Bool {
        get { UserDefaults.standard.bool(forKey: "notifyDomainChanges") }
        set { UserDefaults.standard.set(newValue, forKey: "notifyDomainChanges") }
    }

    var notifySystemStatus: Bool {
        get { UserDefaults.standard.bool(forKey: "notifySystemStatus") }
        set { UserDefaults.standard.set(newValue, forKey: "notifySystemStatus") }
    }

    var notifyDailySummary: Bool {
        get { UserDefaults.standard.bool(forKey: "notifyDailySummary") }
        set { UserDefaults.standard.set(newValue, forKey: "notifyDailySummary") }
    }

    var showClearConfirmation: Bool = false
    var isUpdatingReferenceList: Bool = false
    var isExporting: Bool = false
    var exportURL: URL?

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func updateReferenceList() async {
        isUpdatingReferenceList = true
        _ = await ReferenceListUpdater.shared.updateIfNeeded()
        isUpdatingReferenceList = false
    }

    func clearHistory() {
        guard let context = modelContext else { return }
        try? context.delete(model: DomainCheck.self)
        try? context.save()
    }

    func exportJSON() async {
        guard let context = modelContext else { return }
        isExporting = true

        var descriptor = FetchDescriptor<DomainCheck>(
            sortBy: [SortDescriptor(\DomainCheck.checkedAt, order: .reverse)]
        )
        let checks = (try? context.fetch(descriptor)) ?? []

        struct ExportCheck: Codable {
            let domain: String
            let status: String
            let checkedAt: Date
            let dnsResponseIP: String?
            let resolverUsed: String
            let isVPNActive: Bool
        }

        let exportData = checks.map {
            ExportCheck(
                domain: $0.domain,
                status: $0.statusRaw,
                checkedAt: $0.checkedAt,
                dnsResponseIP: $0.dnsResponseIP,
                resolverUsed: $0.resolverUsed,
                isVPNActive: $0.isVPNActive
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(exportData) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("runetmonitor_export.json")
            try? data.write(to: tempURL)
            exportURL = tempURL
        }

        isExporting = false
    }

    func exportCSV() async {
        guard let context = modelContext else { return }
        isExporting = true

        var csvDescriptor = FetchDescriptor<DomainCheck>(
            sortBy: [SortDescriptor(\DomainCheck.checkedAt, order: .reverse)]
        )
        let checks = (try? context.fetch(csvDescriptor)) ?? []

        var csv = "domain,status,checkedAt,dnsResponseIP,resolverUsed,isVPNActive\n"
        let formatter = ISO8601DateFormatter()

        for check in checks {
            csv += "\(check.domain),\(check.statusRaw),\(formatter.string(from: check.checkedAt)),\(check.dnsResponseIP ?? ""),\(check.resolverUsed),\(check.isVPNActive)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("runetmonitor_export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL

        isExporting = false
    }

    func requestNotificationPermission() async {
        _ = await NotificationManager.shared.requestPermission()
    }
}
