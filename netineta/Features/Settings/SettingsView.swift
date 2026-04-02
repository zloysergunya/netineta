import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("DNS") {
                    Picker("Таймаут запроса", selection: $viewModel.dnsTimeout) {
                        ForEach(DNSTimeout.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                }

                Section("Мониторинг") {
                    Picker("Интервал проверки", selection: $viewModel.monitoringInterval) {
                        ForEach(MonitoringInterval.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                }

                Section("Уведомления") {
                    Toggle("Включены", isOn: $viewModel.notificationsEnabled)

                    if viewModel.notificationsEnabled {
                        Toggle("Изменение статуса домена", isOn: $viewModel.notifyDomainChanges)
                        Toggle("Изменение статуса системы", isOn: $viewModel.notifySystemStatus)
                        Toggle("Ежедневная сводка", isOn: $viewModel.notifyDailySummary)

                        Button("Запросить разрешение") {
                            Task { await viewModel.requestNotificationPermission() }
                        }
                    }
                }

                Section("Хранение данных") {
                    Picker("Хранить историю", selection: $viewModel.historyRetention) {
                        ForEach(HistoryRetention.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                }

                Section("Эталонные домены") {
                    Button {
                        Task { await viewModel.updateReferenceList() }
                    } label: {
                        HStack {
                            Text("Обновить список")
                            Spacer()
                            if viewModel.isUpdatingReferenceList {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isUpdatingReferenceList)
                }

                Section("Экспорт данных") {
                    Button("Экспорт JSON") {
                        Task { await viewModel.exportJSON() }
                    }
                    .disabled(viewModel.isExporting)

                    Button("Экспорт CSV") {
                        Task { await viewModel.exportCSV() }
                    }
                    .disabled(viewModel.isExporting)
                }

                Section {
                    Button("Очистить всю историю", role: .destructive) {
                        viewModel.showClearConfirmation = true
                    }
                }
            }
            .navigationTitle("Настройки")
            .confirmationDialog("Очистить всю историю проверок?", isPresented: $viewModel.showClearConfirmation, titleVisibility: .visible) {
                Button("Очистить", role: .destructive) {
                    viewModel.clearHistory()
                }
            }
            .sheet(item: $viewModel.exportURL) { url in
                ShareSheetView(items: [url])
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
