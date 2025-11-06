import SwiftUI
import SwiftData

@main
struct CircularTimelineApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Contact.self,
                Interaction.self,
                Location.self,
                Note.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}