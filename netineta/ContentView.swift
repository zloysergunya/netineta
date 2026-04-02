import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {
            CheckView()
                .tabItem {
                    Label("Проверка", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("Избранное", systemImage: "star.fill")
                }

            HistoryView()
                .tabItem {
                    Label("История", systemImage: "clock.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
        }
    }
}
