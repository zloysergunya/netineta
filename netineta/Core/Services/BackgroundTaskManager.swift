import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundTaskManager: Sendable {

    static let shared = BackgroundTaskManager()

    static let refreshTaskID = "com.kotov.netineta.refresh"

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskID,
            using: nil
        ) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            Task {
                await self.handleAppRefresh(appRefreshTask)
            }
        }
    }

    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour minimum
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleAppRefresh(_ task: BGAppRefreshTask) async {
        // Schedule next refresh
        scheduleRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Check system status
        let result = await SystemStatusService.shared.checkStatus()

        // Check if status changed
        let previousStatus = UserDefaults.standard.string(forKey: "lastSystemStatus")
        if let previousStatus, previousStatus != result.status.rawValue {
            await NotificationManager.shared.notifySystemStatusChanged(newStatus: result.status)
        }
        UserDefaults.standard.set(result.status.rawValue, forKey: "lastSystemStatus")

        // Check favorite domains (simplified — full implementation needs SwiftData context)
        task.setTaskCompleted(success: true)
    }
}
