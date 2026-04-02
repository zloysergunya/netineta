import SwiftUI

struct ReferenceDomainsView: View {

    let initialResult: SystemStatusResult?
    @State private var viewModel = ReferenceDomainsViewModel()

    var body: some View {
        List {
            domainSection(
                title: "Ожидаемо заблокированы",
                category: .blocked,
                domains: viewModel.blockedDomains,
                results: viewModel.blockedResults
            )

            domainSection(
                title: "Российские гос. сервисы",
                category: .ruGov,
                domains: viewModel.ruGovDomains,
                results: viewModel.ruGovResults,
                footer: "Если гос. сервисы доступны, а зарубежные заблокированы — белые списки включены"
            )

            domainSection(
                title: "Ожидаемо доступны",
                category: .accessible,
                domains: viewModel.accessibleDomains,
                results: viewModel.accessibleResults
            )

            domainSection(
                title: "Нестабильные",
                category: .unstable,
                domains: viewModel.unstableDomains,
                results: viewModel.unstableResults,
                footer: "Нестабильные домены проверяются, но не влияют на общий статус системы"
            )

            Section {
                Button("Сбросить к настройкам по умолчанию") {
                    Task { await viewModel.resetToDefaults() }
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Эталонные домены")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isChecking {
                    ProgressView()
                } else {
                    Button {
                        Task { await viewModel.recheckAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .refreshable {
            await viewModel.recheckAll()
        }
        .alert("Добавить домен", isPresented: $viewModel.showAddSheet) {
            TextField("example.com", text: $viewModel.newDomainInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Добавить") {
                Task { await viewModel.addDomain() }
            }
            Button("Отмена", role: .cancel) {
                viewModel.newDomainInput = ""
            }
        } message: {
            Text("Введите домен для категории «\(viewModel.addCategory.rawValue)»")
        }
        .task {
            await viewModel.load(from: initialResult)
            if initialResult == nil {
                await viewModel.recheckAll()
            }
        }
    }

    @ViewBuilder
    private func domainSection(
        title: String,
        category: DomainCategory,
        domains: [String],
        results: [String: BlockStatus],
        footer: String? = nil
    ) -> some View {
        Section {
            ForEach(domains, id: \.self) { domain in
                domainRow(domain: domain, category: category, status: results[domain])
            }
            .onDelete { offsets in
                let toDelete = offsets.map { domains[$0] }
                for domain in toDelete {
                    Task { await viewModel.removeDomain(domain, from: category) }
                }
            }
        } header: {
            HStack {
                Text("\(title) (\(domains.count))")
                Spacer()
                Button {
                    viewModel.addCategory = category
                    viewModel.showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                }
            }
        } footer: {
            if let footer {
                Text(footer)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func domainRow(domain: String, category: DomainCategory, status: BlockStatus?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(domain)
                    .font(.body)

                if let status {
                    HStack(spacing: 4) {
                        Text("Факт:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        StatusBadge(status: status)

                        if !matchesExpectation(status: status, category: category) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    Text("Не проверен")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .contextMenu {
            let otherCategories = DomainCategory.allCases.filter { $0 != category }
            ForEach(otherCategories, id: \.self) { target in
                Button {
                    Task { await viewModel.moveDomain(domain, from: category, to: target) }
                } label: {
                    Label("В «\(target.rawValue)»", systemImage: moveIcon(for: target))
                }
            }
        }
    }

    private func matchesExpectation(status: BlockStatus, category: DomainCategory) -> Bool {
        switch category {
        case .blocked:
            return status != .accessible
        case .accessible, .ruGov:
            return status == .accessible
        case .unstable:
            return true
        }
    }

    private func moveIcon(for category: DomainCategory) -> String {
        switch category {
        case .blocked: return "xmark.shield"
        case .accessible: return "checkmark.circle"
        case .ruGov: return "building.columns"
        case .unstable: return "questionmark.circle"
        }
    }
}
