import Foundation

enum BlockStatus: String, Codable, CaseIterable, Sendable {
    case accessible
    case blockedDNS
    case blockedDPI
    case unknown

    var localizedDescription: String {
        switch self {
        case .accessible: return "Доступен"
        case .blockedDNS: return "Заблокирован (DNS)"
        case .blockedDPI: return "Заблокирован (DPI)"
        case .unknown: return "Неизвестно"
        }
    }

    var iconName: String {
        switch self {
        case .accessible: return "checkmark.circle.fill"
        case .blockedDNS: return "xmark.shield.fill"
        case .blockedDPI: return "network.slash"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .accessible: return "green"
        case .blockedDNS: return "red"
        case .blockedDPI: return "orange"
        case .unknown: return "gray"
        }
    }
}
