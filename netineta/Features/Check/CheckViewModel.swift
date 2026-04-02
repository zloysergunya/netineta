import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class CheckViewModel {
    var domainInput: String = ""
    var isChecking: Bool = false
    var lastResult: DomainCheckResult?
    var isLoadingStatus: Bool = false
    var systemStatusResult: SystemStatusResult?
    var errorMessage: String?
    var showShareSheet: Bool = false

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var normalizedDomain: String {
        domainInput.normalizedDomain
    }

    var isValidInput: Bool {
        domainInput.normalizedDomain.isValidDomain
    }

    func checkDomain() async {
        let domain = normalizedDomain
        guard domain.isValidDomain else {
            errorMessage = "Некорректный домен"
            return
        }

        errorMessage = nil
        isChecking = true
        lastResult = nil

        let result = await DomainChecker.shared.check(domain)
        lastResult = result
        isChecking = false

        // Save to history
        saveCheck(result)
    }

    func refreshSystemStatus() async {
        isLoadingStatus = true
        let result = await SystemStatusService.shared.checkStatus()
        systemStatusResult = result
        isLoadingStatus = false

        // Save snapshot
        saveSnapshot(result)
    }

    func addToFavorites() {
        guard let result = lastResult, let context = modelContext else { return }

        let domainToCheck = result.domain
        let descriptor = FetchDescriptor<FavoriteDomain>(
            predicate: #Predicate { $0.domain == domainToCheck }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let favorite = FavoriteDomain(domain: result.domain, status: result.status)
        favorite.lastCheckedAt = result.checkedAt
        context.insert(favorite)
        try? context.save()
    }

    func isFavorite() -> Bool {
        guard let result = lastResult, let context = modelContext else { return false }
        let domain = result.domain
        let descriptor = FetchDescriptor<FavoriteDomain>(
            predicate: #Predicate { $0.domain == domain }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    var shareText: String {
        guard let result = lastResult else { return "" }
        return """
        \(result.domain): \(result.status.localizedDescription)
        DNS (Яндекс): \(result.yandexIPs.joined(separator: ", ").isEmpty ? "нет ответа" : result.yandexIPs.joined(separator: ", "))
        DNS (Cloudflare): \(result.cloudflareIPs.joined(separator: ", ").isEmpty ? "нет ответа" : result.cloudflareIPs.joined(separator: ", "))
        Проверено: \(result.checkedAt.formatted())
        — RuNet Monitor
        """
    }

    private func saveCheck(_ result: DomainCheckResult) {
        guard let context = modelContext else { return }
        let check = DomainCheck(
            domain: result.domain,
            status: result.status,
            checkedAt: result.checkedAt,
            dnsResponseIP: result.yandexIPs.first,
            resolverUsed: result.resolverUsed,
            isVPNActive: result.isVPNActive
        )
        context.insert(check)
        try? context.save()
    }

    private func saveSnapshot(_ result: SystemStatusResult) {
        guard let context = modelContext else { return }
        let isVPN = VPNDetector.shared.isVPNActive
        let snapshot = SystemStatusSnapshot(result: result, isVPNActive: isVPN)
        context.insert(snapshot)
        try? context.save()
    }
}
