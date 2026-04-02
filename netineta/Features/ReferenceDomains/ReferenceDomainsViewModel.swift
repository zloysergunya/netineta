import Foundation
import SwiftUI

enum DomainCategory: String, CaseIterable {
    case blocked = "Ожидаемо заблокированы"
    case accessible = "Ожидаемо доступны"
    case ruGov = "Российские гос. сервисы"
    case unstable = "Нестабильные"
}

@Observable
@MainActor
final class ReferenceDomainsViewModel {

    var blockedDomains: [String] = []
    var accessibleDomains: [String] = []
    var ruGovDomains: [String] = []
    var unstableDomains: [String] = []

    var blockedResults: [String: BlockStatus] = [:]
    var accessibleResults: [String: BlockStatus] = [:]
    var ruGovResults: [String: BlockStatus] = [:]
    var unstableResults: [String: BlockStatus] = [:]

    var isChecking: Bool = false
    var showAddSheet: Bool = false
    var addCategory: DomainCategory = .blocked
    var newDomainInput: String = ""

    private var configVersion: Int = 1

    func load(from statusResult: SystemStatusResult?) async {
        let config = await ReferenceListUpdater.shared.loadConfig()
        configVersion = config.version
        blockedDomains = config.blocked
        accessibleDomains = config.accessible
        ruGovDomains = config.ruGov
        unstableDomains = config.unstable

        if let statusResult {
            blockedResults = statusResult.blockedResults
            accessibleResults = statusResult.accessibleResults
            ruGovResults = statusResult.ruGovResults
            unstableResults = statusResult.unstableResults
        }
    }

    func recheckAll() async {
        isChecking = true
        let result = await SystemStatusService.shared.checkStatus()
        blockedResults = result.blockedResults
        accessibleResults = result.accessibleResults
        ruGovResults = result.ruGovResults
        unstableResults = result.unstableResults
        isChecking = false
    }

    func addDomain() async {
        let domain = newDomainInput.normalizedDomain
        guard domain.isValidDomain else { return }
        guard !allDomains.contains(domain) else { return }

        let category = addCategory
        switch category {
        case .blocked: blockedDomains.append(domain)
        case .accessible: accessibleDomains.append(domain)
        case .ruGov: ruGovDomains.append(domain)
        case .unstable: unstableDomains.append(domain)
        }

        newDomainInput = ""
        await saveConfig()

        let checkResult = await DomainChecker.shared.check(domain)
        switch category {
        case .blocked: blockedResults[domain] = checkResult.status
        case .accessible: accessibleResults[domain] = checkResult.status
        case .ruGov: ruGovResults[domain] = checkResult.status
        case .unstable: unstableResults[domain] = checkResult.status
        }
    }

    func removeDomain(_ domain: String, from category: DomainCategory) async {
        switch category {
        case .blocked:
            blockedDomains.removeAll { $0 == domain }
            blockedResults.removeValue(forKey: domain)
        case .accessible:
            accessibleDomains.removeAll { $0 == domain }
            accessibleResults.removeValue(forKey: domain)
        case .ruGov:
            ruGovDomains.removeAll { $0 == domain }
            ruGovResults.removeValue(forKey: domain)
        case .unstable:
            unstableDomains.removeAll { $0 == domain }
            unstableResults.removeValue(forKey: domain)
        }
        await saveConfig()
    }

    func moveDomain(_ domain: String, from source: DomainCategory, to target: DomainCategory) async {
        guard source != target else { return }

        let status = results(for: source)[domain]

        // Remove from source
        await removeDomainFromList(domain, category: source)

        // Add to target
        switch target {
        case .blocked:
            blockedDomains.append(domain)
            if let status { blockedResults[domain] = status }
        case .accessible:
            accessibleDomains.append(domain)
            if let status { accessibleResults[domain] = status }
        case .ruGov:
            ruGovDomains.append(domain)
            if let status { ruGovResults[domain] = status }
        case .unstable:
            unstableDomains.append(domain)
            if let status { unstableResults[domain] = status }
        }

        await saveConfig()
    }

    func resetToDefaults() async {
        await ReferenceListUpdater.shared.clearUserConfig()
        await load(from: nil)
        await recheckAll()
    }

    // MARK: - Private

    private var allDomains: Set<String> {
        Set(blockedDomains + accessibleDomains + ruGovDomains + unstableDomains)
    }

    private func domains(for category: DomainCategory) -> [String] {
        switch category {
        case .blocked: return blockedDomains
        case .accessible: return accessibleDomains
        case .ruGov: return ruGovDomains
        case .unstable: return unstableDomains
        }
    }

    private func updateDomainsList(_ category: DomainCategory) {
        // This is needed because arrays are value types
        // The append in addDomain works on a copy, so we handle it directly there
    }

    private func results(for category: DomainCategory) -> [String: BlockStatus] {
        switch category {
        case .blocked: return blockedResults
        case .accessible: return accessibleResults
        case .ruGov: return ruGovResults
        case .unstable: return unstableResults
        }
    }

    private func removeDomainFromList(_ domain: String, category: DomainCategory) async {
        switch category {
        case .blocked:
            blockedDomains.removeAll { $0 == domain }
            blockedResults.removeValue(forKey: domain)
        case .accessible:
            accessibleDomains.removeAll { $0 == domain }
            accessibleResults.removeValue(forKey: domain)
        case .ruGov:
            ruGovDomains.removeAll { $0 == domain }
            ruGovResults.removeValue(forKey: domain)
        case .unstable:
            unstableDomains.removeAll { $0 == domain }
            unstableResults.removeValue(forKey: domain)
        }
    }

    private func saveConfig() async {
        let config = ReferenceDomainsConfig(
            version: configVersion,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            sourceUrl: nil,
            blocked: blockedDomains,
            accessible: accessibleDomains,
            ruGov: ruGovDomains,
            unstable: unstableDomains
        )
        await ReferenceListUpdater.shared.saveUserConfig(config)
    }
}
