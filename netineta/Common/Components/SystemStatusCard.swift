import SwiftUI

struct SystemStatusCard: View {

    let status: SystemStatus
    let blockedCorrect: Int
    let blockedTotal: Int
    let accessibleCorrect: Int
    let accessibleTotal: Int
    let ruGovCorrect: Int
    let ruGovTotal: Int
    let checkedAt: Date?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: status.iconName)
                    .foregroundStyle(statusColor)
                    .font(.title2)
                Text(status.localizedDescription)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onRefresh) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isLoading)
            }

            if status != .unknown {
                statsRow(
                    icon: "xmark.shield",
                    label: "Заблокировано",
                    correct: blockedCorrect,
                    total: blockedTotal
                )

                statsRow(
                    icon: "checkmark.circle",
                    label: "Доступно",
                    correct: accessibleCorrect,
                    total: accessibleTotal
                )

                if ruGovTotal > 0 {
                    statsRow(
                        icon: "building.columns",
                        label: "Гос. сервисы",
                        correct: ruGovCorrect,
                        total: ruGovTotal
                    )
                }
            }

            if let checkedAt {
                Text("Обновлено: \(checkedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Chevron hint
            HStack {
                Spacer()
                Text("Подробнее")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statsRow(icon: String, label: String, correct: Int, total: Int) -> some View {
        HStack {
            Label("\(label): \(correct)/\(total)", systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if correct == total && total > 0 {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .whitelisted: return .blue
        case .operational: return .green
        case .degraded: return .yellow
        case .disrupted: return .red
        case .unknown: return .gray
        }
    }
}
