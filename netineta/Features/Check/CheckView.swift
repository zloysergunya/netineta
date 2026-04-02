import SwiftUI
import SwiftData

struct CheckView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CheckViewModel()
    @State private var vpnDetector = VPNDetector.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // VPN Warning
                    if vpnDetector.isVPNActive {
                        VPNWarningBanner()
                    }

                    // System Status Card
                    NavigationLink {
                        ReferenceDomainsView(initialResult: viewModel.systemStatusResult)
                    } label: {
                        SystemStatusCard(
                            status: viewModel.systemStatusResult?.status ?? .unknown,
                            blockedCorrect: viewModel.systemStatusResult?.blockedCorrect ?? 0,
                            blockedTotal: viewModel.systemStatusResult?.blockedTotal ?? 0,
                            accessibleCorrect: viewModel.systemStatusResult?.accessibleCorrect ?? 0,
                            accessibleTotal: viewModel.systemStatusResult?.accessibleTotal ?? 0,
                            ruGovCorrect: viewModel.systemStatusResult?.ruGovCorrect ?? 0,
                            ruGovTotal: viewModel.systemStatusResult?.ruGovTotal ?? 0,
                            checkedAt: viewModel.systemStatusResult?.checkedAt,
                            isLoading: viewModel.isLoadingStatus,
                            onRefresh: {
                                Task { await viewModel.refreshSystemStatus() }
                            }
                        )
                    }
                    .buttonStyle(.plain)

                    // Domain Input
                    VStack(spacing: 12) {
                        VStack {
                            TextField("Введите домен (например, youtube.com)", text: $viewModel.domainInput)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .onSubmit {
                                    Task { await viewModel.checkDomain() }
                                }

                            Button {
                                Task { await viewModel.checkDomain() }
                            } label: {
                                if viewModel.isChecking {
                                    ProgressView()
                                        .frame(width: 44, height: 36)
                                } else {
                                    Text("Проверить")
                                        .frame(height: 36)
                                }
                            }
                            .padding(.top, 8)
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isChecking || !viewModel.isValidInput)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    // Result
                    if let result = viewModel.lastResult {
                        resultCard(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Проверка")
            .task {
                viewModel.setModelContext(modelContext)
                await viewModel.refreshSystemStatus()
            }
        }
    }

    @ViewBuilder
    private func resultCard(_ result: DomainCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.domain)
                    .font(.title3.bold())
                Spacer()
                StatusBadge(status: result.status)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Яндекс DNS: \(result.yandexIPs.isEmpty ? "нет ответа" : result.yandexIPs.joined(separator: ", "))",
                      systemImage: "server.rack")
                .font(.caption)
                .foregroundStyle(.secondary)

                Label("Cloudflare: \(result.cloudflareIPs.isEmpty ? "нет ответа" : result.cloudflareIPs.joined(separator: ", "))",
                      systemImage: "server.rack")
                .font(.caption)
                .foregroundStyle(.secondary)

                if result.isVPNActive {
                    Label("VPN был активен", systemImage: "shield.checkered")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Label(result.checkedAt.formatted(), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.addToFavorites()
                } label: {
                    Label(viewModel.isFavorite() ? "В избранном" : "В избранное",
                          systemImage: viewModel.isFavorite() ? "star.fill" : "star")
                }
                .disabled(viewModel.isFavorite())

                ShareLink(item: viewModel.shareText) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
