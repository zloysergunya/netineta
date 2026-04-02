import Foundation

actor ReferenceListUpdater {

    static let shared = ReferenceListUpdater()

    private let cacheKey = "cached_reference_domains"
    private let versionKey = "reference_domains_version"
    private let userConfigKey = "user_reference_domains"

    func loadConfig() -> ReferenceDomainsConfig {
        // User overrides take priority
        if let userConfig = loadUserConfig() {
            return userConfig
        }
        // Then cached remote version
        if let cached = loadCached() {
            return cached
        }
        // Fall back to bundled
        return loadBundled()
    }

    func saveUserConfig(_ config: ReferenceDomainsConfig) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config) {
            UserDefaults.standard.set(data, forKey: userConfigKey)
        }
    }

    func clearUserConfig() {
        UserDefaults.standard.removeObject(forKey: userConfigKey)
    }

    private func loadUserConfig() -> ReferenceDomainsConfig? {
        guard let data = UserDefaults.standard.data(forKey: userConfigKey) else {
            return nil
        }
        return try? JSONDecoder().decode(ReferenceDomainsConfig.self, from: data)
    }

    func updateIfNeeded() async -> ReferenceDomainsConfig {
        let current = loadConfig()

        guard let sourceUrlString = current.sourceUrl,
              let sourceUrl = URL(string: sourceUrlString) else {
            return current
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: sourceUrl)
            let remote = try JSONDecoder().decode(ReferenceDomainsConfig.self, from: data)

            if remote.version > current.version {
                saveToCache(data)
                UserDefaults.standard.set(remote.version, forKey: versionKey)
                return remote
            }
        } catch {
            // Network error — use current
        }

        return current
    }

    private func loadCached() -> ReferenceDomainsConfig? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(ReferenceDomainsConfig.self, from: data)
    }

    private func loadBundled() -> ReferenceDomainsConfig {
        guard let url = Bundle.main.url(forResource: "reference_domains", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(ReferenceDomainsConfig.self, from: data) else {
            return ReferenceDomainsConfig(
                version: 2,
                updatedAt: "2026-04-02",
                sourceUrl: nil,
                blocked: ["instagram.com", "facebook.com", "x.com", "twitter.com", "linkedin.com",
                           "tiktok.com", "discord.com", "twitch.tv", "reddit.com", "medium.com"],
                accessible: ["google.com", "apple.com", "stackoverflow.com", "github.com", "wikipedia.org"],
                ruGov: ["gosuslugi.ru", "mos.ru", "government.ru", "kremlin.ru", "nalog.gov.ru",
                         "pfr.gov.ru", "vk.com", "ok.ru", "mail.ru", "max.ru",
                         "yandex.ru", "sberbank.ru", "tinkoff.ru", "cbr.ru"],
                unstable: ["youtube.com", "telegram.org"]
            )
        }
        return config
    }

    private func saveToCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}
