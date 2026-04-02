import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {

    @Query(sort: \DomainCheck.checkedAt, order: .reverse) private var allChecks: [DomainCheck]
    @Query(sort: \SystemStatusSnapshot.checkedAt, order: .reverse) private var snapshots: [SystemStatusSnapshot]
    @State private var viewModel = StatisticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Период", selection: $viewModel.selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if allChecks.isEmpty {
                        ContentUnavailableView(
                            "Нет данных",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Проверьте домены, чтобы увидеть статистику")
                        )
                    } else {
                        // Checks per day
                        checksPerDayChart

                        // Status ratio
                        statusRatioChart

                        // Domain timeline
                        domainTimelineSection

                        // Top domains
                        topDomainsSection

                        // System status history
                        systemStatusHistoryChart
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Статистика")
        }
    }

    @ViewBuilder
    private var checksPerDayChart: some View {
        let data = viewModel.dailyCounts(from: allChecks)
        if !data.isEmpty {
            VStack(alignment: .leading) {
                Text("Проверки по дням")
                    .font(.headline)
                    .padding(.horizontal)

                Chart(data) { item in
                    BarMark(
                        x: .value("Дата", item.date, unit: .day),
                        y: .value("Количество", item.count)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var statusRatioChart: some View {
        let data = viewModel.statusRatios(from: allChecks)
        if !data.isEmpty {
            VStack(alignment: .leading) {
                Text("Соотношение статусов")
                    .font(.headline)
                    .padding(.horizontal)

                Chart(data) { item in
                    SectorMark(
                        angle: .value("Количество", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(colorForStatus(item.status))
                    .annotation(position: .overlay) {
                        Text("\(item.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)

                // Legend
                HStack(spacing: 16) {
                    ForEach(data) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForStatus(item.status))
                                .frame(width: 8, height: 8)
                            Text(item.status.localizedDescription)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var domainTimelineSection: some View {
        let domains = viewModel.availableDomains(from: allChecks)
        if !domains.isEmpty {
            VStack(alignment: .leading) {
                Text("Доступность домена")
                    .font(.headline)
                    .padding(.horizontal)

                Picker("Домен", selection: $viewModel.selectedDomain) {
                    Text("Выберите домен").tag(nil as String?)
                    ForEach(domains, id: \.self) { domain in
                        Text(domain).tag(domain as String?)
                    }
                }
                .padding(.horizontal)

                if let domain = viewModel.selectedDomain {
                    let timeline = viewModel.domainTimeline(from: allChecks, domain: domain)
                    if !timeline.isEmpty {
                        Chart(timeline, id: \.id) { check in
                            PointMark(
                                x: .value("Время", check.checkedAt),
                                y: .value("Статус", statusNumericValue(check.status))
                            )
                            .foregroundStyle(colorForStatus(check.status))
                        }
                        .chartYAxis {
                            AxisMarks(values: [0, 1, 2, 3]) { value in
                                AxisValueLabel {
                                    if let v = value.as(Int.self) {
                                        Text(statusLabel(v))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var topDomainsSection: some View {
        let top = viewModel.topDomains(from: allChecks)
        if !top.isEmpty {
            VStack(alignment: .leading) {
                Text("Топ-5 доменов")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(top) { item in
                    HStack {
                        Text(item.domain)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count) проверок")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private var systemStatusHistoryChart: some View {
        if !snapshots.isEmpty {
            VStack(alignment: .leading) {
                Text("История статуса системы")
                    .font(.headline)
                    .padding(.horizontal)

                Chart(snapshots.prefix(30), id: \.id) { snapshot in
                    PointMark(
                        x: .value("Время", snapshot.checkedAt),
                        y: .value("Статус", systemStatusNumericValue(snapshot.status))
                    )
                    .foregroundStyle(systemStatusColor(snapshot.status))
                }
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(systemStatusLabel(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
            }
        }
    }

    private func colorForStatus(_ status: BlockStatus) -> Color {
        switch status {
        case .accessible: return .green
        case .blockedDNS: return .red
        case .blockedDPI: return .orange
        case .unknown: return .gray
        }
    }

    private func statusNumericValue(_ status: BlockStatus) -> Int {
        switch status {
        case .accessible: return 3
        case .blockedDPI: return 2
        case .blockedDNS: return 1
        case .unknown: return 0
        }
    }

    private func statusLabel(_ value: Int) -> String {
        switch value {
        case 3: return "OK"
        case 2: return "DPI"
        case 1: return "DNS"
        default: return "?"
        }
    }

    private func systemStatusNumericValue(_ status: SystemStatus) -> Int {
        switch status {
        case .whitelisted: return 4
        case .operational: return 3
        case .degraded: return 2
        case .disrupted: return 1
        case .unknown: return 0
        }
    }

    private func systemStatusColor(_ status: SystemStatus) -> Color {
        switch status {
        case .whitelisted: return .blue
        case .operational: return .green
        case .degraded: return .yellow
        case .disrupted: return .red
        case .unknown: return .gray
        }
    }

    private func systemStatusLabel(_ value: Int) -> String {
        switch value {
        case 4: return "БС"
        case 3: return "OK"
        case 2: return "~"
        case 1: return "!"
        default: return "?"
        }
    }
}
