import Foundation

actor SystemStatusService {

    static let shared = SystemStatusService()

    func checkStatus(timeout: TimeInterval = 15) async -> SystemStatusResult {
        let config = await ReferenceListUpdater.shared.loadConfig()
        let checkedAt = Date()

        let allBlocked = config.blocked
        let allAccessible = config.accessible
        let allRuGov = config.ruGov
        let allUnstable = config.unstable

        // Check all categories in parallel
        async let blockedCheck = checkDomains(allBlocked, timeout: timeout)
        async let accessibleCheck = checkDomains(allAccessible, timeout: timeout)
        async let ruGovCheck = checkDomains(allRuGov, timeout: timeout)
        async let unstableCheck = checkDomains(allUnstable, timeout: timeout)

        let blockedResults = await blockedCheck
        let accessibleResults = await accessibleCheck
        let ruGovResults = await ruGovCheck
        let unstableResultsList = await unstableCheck

        // Count matches
        let blockedCorrect = blockedResults.filter { $0.value != .accessible }.count
        let accessibleCorrect = accessibleResults.filter { $0.value == .accessible }.count
        let ruGovCorrect = ruGovResults.filter { $0.value == .accessible }.count

        // Determine status
        let status: SystemStatus

        let blockedRatio = allBlocked.isEmpty ? 0.0 : Double(blockedCorrect) / Double(allBlocked.count)
        let ruGovRatio = allRuGov.isEmpty ? 0.0 : Double(ruGovCorrect) / Double(allRuGov.count)
        let totalChecked = allBlocked.count + allAccessible.count
        let totalCorrect = blockedCorrect + accessibleCorrect
        let overallRatio = totalChecked > 0 ? Double(totalCorrect) / Double(totalChecked) : 0

        if totalChecked == 0 {
            status = .unknown
        } else if blockedRatio > 0.8 && ruGovRatio > 0.8 {
            // Blocked domains are blocked AND Russian gov sites work → whitelists active
            status = .whitelisted
        } else if overallRatio > 0.8 {
            status = .operational
        } else if overallRatio >= 0.5 {
            status = .degraded
        } else {
            status = .disrupted
        }

        var blockedResultsMap: [String: BlockStatus] = [:]
        for (domain, blockStatus) in blockedResults {
            blockedResultsMap[domain] = blockStatus
        }

        var accessibleResultsMap: [String: BlockStatus] = [:]
        for (domain, blockStatus) in accessibleResults {
            accessibleResultsMap[domain] = blockStatus
        }

        var ruGovResultsMap: [String: BlockStatus] = [:]
        for (domain, blockStatus) in ruGovResults {
            ruGovResultsMap[domain] = blockStatus
        }

        var unstableResultsMap: [String: BlockStatus] = [:]
        for (domain, blockStatus) in unstableResultsList {
            unstableResultsMap[domain] = blockStatus
        }

        return SystemStatusResult(
            status: status,
            checkedAt: checkedAt,
            blockedCorrect: blockedCorrect,
            blockedTotal: allBlocked.count,
            accessibleCorrect: accessibleCorrect,
            accessibleTotal: allAccessible.count,
            ruGovCorrect: ruGovCorrect,
            ruGovTotal: allRuGov.count,
            blockedResults: blockedResultsMap,
            accessibleResults: accessibleResultsMap,
            ruGovResults: ruGovResultsMap,
            unstableResults: unstableResultsMap
        )
    }

    private func checkDomains(_ domains: [String], timeout: TimeInterval) async -> [(domain: String, value: BlockStatus)] {
        await withTaskGroup(of: (String, BlockStatus).self) { group in
            for domain in domains {
                group.addTask {
                    let result = await DomainChecker.shared.check(domain, timeout: min(timeout, 5))
                    return (domain, result.status)
                }
            }

            var results: [(String, BlockStatus)] = []
            for await result in group {
                results.append(result)
            }
            return results.map { (domain: $0.0, value: $0.1) }
        }
    }
}
