import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class FavoritesViewModel {
    var isRefreshing: Bool = false
    private var lastRefresh: Date?
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func refreshAll(favorites: [FavoriteDomain]) async {
        guard !isRefreshing else { return }

        // Throttle: 1 minute
        if let last = lastRefresh, Date().timeIntervalSince(last) < 60 {
            return
        }

        isRefreshing = true
        lastRefresh = Date()

        await withTaskGroup(of: (String, DomainCheckResult).self) { group in
            for fav in favorites {
                let domain = fav.domain
                group.addTask {
                    let result = await DomainChecker.shared.check(domain)
                    return (domain, result)
                }
            }

            for await (domain, result) in group {
                if let fav = favorites.first(where: { $0.domain == domain }) {
                    let previousStatus = fav.lastStatus
                    fav.lastStatus = result.status
                    fav.lastCheckedAt = result.checkedAt

                    // Notify if changed
                    if fav.notifyOnChange && previousStatus != result.status {
                        await NotificationManager.shared.notifyDomainStatusChanged(
                            domain: domain, newStatus: result.status
                        )
                    }

                    // Save check to history
                    if let context = modelContext {
                        let check = DomainCheck(
                            domain: result.domain,
                            status: result.status,
                            checkedAt: result.checkedAt,
                            dnsResponseIP: result.yandexIPs.first,
                            resolverUsed: result.resolverUsed,
                            isVPNActive: result.isVPNActive
                        )
                        context.insert(check)
                    }
                }
            }
        }

        try? modelContext?.save()
        isRefreshing = false
    }

    func delete(_ favorite: FavoriteDomain) {
        modelContext?.delete(favorite)
        try? modelContext?.save()
    }
}
