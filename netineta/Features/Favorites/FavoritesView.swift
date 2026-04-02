import SwiftUI
import SwiftData

struct FavoritesView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteDomain.domain) private var favorites: [FavoriteDomain]
    @State private var viewModel = FavoritesViewModel()

    private var blocked: [FavoriteDomain] {
        favorites.filter { $0.lastStatus == .blockedDNS || $0.lastStatus == .blockedDPI }
    }

    private var accessible: [FavoriteDomain] {
        favorites.filter { $0.lastStatus == .accessible }
    }

    private var unknown: [FavoriteDomain] {
        favorites.filter { $0.lastStatus == .unknown }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "Нет избранных",
                        systemImage: "star.slash",
                        description: Text("Добавьте домены из вкладки «Проверка»")
                    )
                } else {
                    List {
                        if !blocked.isEmpty {
                            Section("Заблокированы") {
                                ForEach(blocked, id: \.id) { fav in
                                    favoriteRow(fav)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        viewModel.delete(blocked[index])
                                    }
                                }
                            }
                        }

                        if !accessible.isEmpty {
                            Section("Доступны") {
                                ForEach(accessible, id: \.id) { fav in
                                    favoriteRow(fav)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        viewModel.delete(accessible[index])
                                    }
                                }
                            }
                        }

                        if !unknown.isEmpty {
                            Section("Неизвестно") {
                                ForEach(unknown, id: \.id) { fav in
                                    favoriteRow(fav)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        viewModel.delete(unknown[index])
                                    }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refreshAll(favorites: favorites)
                    }
                }
            }
            .navigationTitle("Избранное")
            .toolbar {
                if viewModel.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }

    @ViewBuilder
    private func favoriteRow(_ fav: FavoriteDomain) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(fav.domain)
                    .font(.body.bold())
                Spacer()
                StatusBadge(status: fav.lastStatus)
            }

            if let checkedAt = fav.lastCheckedAt {
                Text("Проверено: \(checkedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Toggle("Мониторинг", isOn: Binding(
                    get: { fav.monitoringEnabled },
                    set: { fav.monitoringEnabled = $0; try? modelContext.save() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                Text("Мониторинг")
                    .font(.caption)

                Spacer()

                Toggle("Уведомления", isOn: Binding(
                    get: { fav.notifyOnChange },
                    set: { fav.notifyOnChange = $0; try? modelContext.save() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                Text("Уведомления")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
