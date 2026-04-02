import Foundation
import SwiftData
import SwiftUI

enum StatsPeriod: String, CaseIterable {
    case week = "7 дней"
    case month = "30 дней"
    case all = "Всё время"

    var startDate: Date? {
        switch self {
        case .week: return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: Date())
        case .all: return nil
        }
    }
}

struct DailyCheckCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct StatusRatio: Identifiable {
    let id = UUID()
    let status: BlockStatus
    let count: Int
}

struct DomainFrequency: Identifiable {
    let id = UUID()
    let domain: String
    let count: Int
}

@Observable
@MainActor
final class StatisticsViewModel {
    var selectedPeriod: StatsPeriod = .week
    var selectedDomain: String?

    func dailyCounts(from checks: [DomainCheck]) -> [DailyCheckCount] {
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]

        for check in filteredChecks(checks) {
            let day = calendar.startOfDay(for: check.checkedAt)
            grouped[day, default: 0] += 1
        }

        return grouped.map { DailyCheckCount(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func statusRatios(from checks: [DomainCheck]) -> [StatusRatio] {
        var counts: [BlockStatus: Int] = [:]
        for check in filteredChecks(checks) {
            counts[check.status, default: 0] += 1
        }
        return counts.map { StatusRatio(status: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func topDomains(from checks: [DomainCheck], limit: Int = 5) -> [DomainFrequency] {
        var counts: [String: Int] = [:]
        for check in filteredChecks(checks) {
            counts[check.domain, default: 0] += 1
        }
        return counts.map { DomainFrequency(domain: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    func domainTimeline(from checks: [DomainCheck], domain: String) -> [DomainCheck] {
        filteredChecks(checks)
            .filter { $0.domain == domain }
            .sorted { $0.checkedAt < $1.checkedAt }
    }

    func availableDomains(from checks: [DomainCheck]) -> [String] {
        Array(Set(checks.map(\.domain))).sorted()
    }

    private func filteredChecks(_ checks: [DomainCheck]) -> [DomainCheck] {
        guard let startDate = selectedPeriod.startDate else { return checks }
        return checks.filter { $0.checkedAt >= startDate }
    }
}
