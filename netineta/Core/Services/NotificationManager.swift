import Foundation
import UserNotifications

actor NotificationManager {

    static let shared = NotificationManager()

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func notifyDomainStatusChanged(domain: String, newStatus: BlockStatus) async {
        let content = UNMutableNotificationContent()
        content.title = "Статус изменился"

        switch newStatus {
        case .accessible:
            content.body = "\(domain) снова доступен"
        case .blockedDNS:
            content.body = "\(domain) заблокирован (DNS)"
        case .blockedDPI:
            content.body = "\(domain) заблокирован (DPI)"
        case .unknown:
            content.body = "\(domain) — статус неизвестен"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "domain-\(domain)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func notifySystemStatusChanged(newStatus: SystemStatus) async {
        let content = UNMutableNotificationContent()
        content.title = "Статус белых списков изменился"
        content.body = newStatus.localizedDescription
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "system-status-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func notifyDailySummary(blockedCount: Int, totalCount: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Ежедневная сводка"
        content.body = "\(blockedCount) из \(totalCount) ваших сайтов заблокированы"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-summary-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
