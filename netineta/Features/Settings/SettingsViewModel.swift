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
        didSet { UserDefaults.standard.set(dnsTimeout.rawValue, forKey: "dnsTimeout") }
    }

    var monitoringInterval: MonitoringInterval {
        didSet { UserDefaults.standard.set(monitoringInterval.rawValue, forKey: "monitoringInterval") }
    }

    var historyRetention: HistoryRetention {
        didSet { UserDefaults.standard.set(historyRetention.rawValue, forKey: "historyRetention") }
    }

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    var notifyDomainChanges: Bool {
        didSet { UserDefaults.standard.set(notifyDomainChanges, forKey: "notifyDomainChanges") }
    }

    var notifySystemStatus: Bool {
        didSet { UserDefaults.standard.set(notifySystemStatus, forKey: "notifySystemStatus") }
    }

    var notifyDailySummary: Bool {
        didSet { UserDefaults.standard.set(notifyDailySummary, forKey: "notifyDailySummary") }
    }

    var showClearConfirmation: Bool = false

    init() {
        let ud = UserDefaults.standard
        self.dnsTimeout = DNSTimeout(rawValue: ud.integer(forKey: "dnsTimeout")) ?? .five
        self.monitoringInterval = MonitoringInterval(rawValue: ud.integer(forKey: "monitoringInterval")) ?? .three
        self.historyRetention = HistoryRetention(rawValue: ud.string(forKey: "historyRetention") ?? "") ?? .month
        self.notificationsEnabled = ud.bool(forKey: "notificationsEnabled")
        self.notifyDomainChanges = ud.bool(forKey: "notifyDomainChanges")
        self.notifySystemStatus = ud.bool(forKey: "notifySystemStatus")
        self.notifyDailySummary = ud.bool(forKey: "notifyDailySummary")
    }
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
