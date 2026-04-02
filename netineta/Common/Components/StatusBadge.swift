import SwiftUI

struct StatusBadge: View {

    let status: BlockStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(status.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
    }

    private var statusColor: Color {
        switch status {
        case .accessible: return .green
        case .blockedDNS: return .red
        case .blockedDPI: return .orange
        case .unknown: return .gray
        }
    }
}
