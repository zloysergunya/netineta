import Foundation

enum SystemStatus: String, Codable, Sendable {
    case whitelisted
    case operational
    case degraded
    case disrupted
    case unknown

    var localizedDescription: String {
        switch self {
        case .whitelisted: return "Белые списки включены"
        case .operational: return "Блокировки работают"
        case .degraded: return "Частичные сбои"
        case .disrupted: return "Блокировки не обнаружены"
        case .unknown: return "Нет данных"
        }
    }

    var iconName: String {
        switch self {
        case .whitelisted: return "list.bullet.rectangle.portrait.fill"
        case .operational: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .disrupted: return "globe"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

struct SystemStatusResult: Codable, Sendable {
    let status: SystemStatus
    let checkedAt: Date
    let blockedCorrect: Int
    let blockedTotal: Int
    let accessibleCorrect: Int
    let accessibleTotal: Int
    let ruGovCorrect: Int
    let ruGovTotal: Int
    let blockedResults: [String: BlockStatus]
    let accessibleResults: [String: BlockStatus]
    let ruGovResults: [String: BlockStatus]
    let unstableResults: [String: BlockStatus]
}

struct ReferenceDomainsConfig: Codable, Sendable {
    let version: Int
    let updatedAt: String
    let sourceUrl: String?
    let blocked: [String]
    let accessible: [String]
    let ruGov: [String]
    let unstable: [String]
}
