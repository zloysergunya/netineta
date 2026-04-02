import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class HistoryViewModel {
    var searchText: String = ""
    var statusFilter: BlockStatus?
    var showClearConfirmation: Bool = false
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func deleteCheck(_ check: DomainCheck) {
        modelContext?.delete(check)
        try? modelContext?.save()
    }

    func clearAll() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: DomainCheck.self)
            try context.save()
        } catch {
            // ignore
        }
    }

    func groupedByDay(_ checks: [DomainCheck]) -> [(date: String, checks: [DomainCheck])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ru_RU")

        var grouped: [String: [DomainCheck]] = [:]
        var order: [String] = []

        for check in checks {
            let key = formatter.string(from: check.checkedAt)
            if grouped[key] == nil {
                order.append(key)
                grouped[key] = []
            }
            grouped[key]?.append(check)
        }

        return order.map { (date: $0, checks: grouped[$0] ?? []) }
    }
}
