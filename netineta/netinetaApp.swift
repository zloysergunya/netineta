import SwiftUI
import SwiftData

@main
struct netinetaApp: App {

    private let container: ModelContainer

    init() {
        do {
            container = try AppDatabase.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        BackgroundTaskManager.shared.registerTasks()
        BackgroundTaskManager.shared.scheduleRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
