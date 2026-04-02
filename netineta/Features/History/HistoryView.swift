import SwiftUI
import SwiftData

struct HistoryView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DomainCheck.checkedAt, order: .reverse) private var allChecks: [DomainCheck]
    @State private var viewModel = HistoryViewModel()

    private var filteredChecks: [DomainCheck] {
        allChecks.filter { check in
            let matchesSearch = viewModel.searchText.isEmpty ||
                check.domain.localizedCaseInsensitiveContains(viewModel.searchText)
            let matchesStatus = viewModel.statusFilter == nil ||
                check.status == viewModel.statusFilter
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allChecks.isEmpty {
                    ContentUnavailableView(
                        "Нет истории",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Проверьте домен, чтобы начать")
                    )
                } else {
                    List {
                        let grouped = viewModel.groupedByDay(filteredChecks)
                        ForEach(grouped, id: \.date) { group in
                            Section(group.date) {
                                ForEach(group.checks, id: \.id) { check in
                                    checkRow(check)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        viewModel.deleteCheck(group.checks[index])
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Поиск по домену")
                }
            }
            .navigationTitle("История")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Все") { viewModel.statusFilter = nil }
                        ForEach(BlockStatus.allCases, id: \.self) { status in
                            Button(status.localizedDescription) {
                                viewModel.statusFilter = status
                            }
                        }
                    } label: {
                        Label("Фильтр", systemImage: viewModel.statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }

                if !allChecks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Очистить", role: .destructive) {
                            viewModel.showClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("Очистить всю историю?", isPresented: $viewModel.showClearConfirmation, titleVisibility: .visible) {
                Button("Очистить", role: .destructive) {
                    viewModel.clearAll()
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }

    @ViewBuilder
    private func checkRow(_ check: DomainCheck) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(check.domain)
                    .font(.body)
                Text(check.checkedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            StatusBadge(status: check.status)
        }
    }
}
