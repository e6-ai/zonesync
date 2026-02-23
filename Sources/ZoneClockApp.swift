import SwiftUI
import SwiftData

@main
struct ZoneClockApp: App {
    private let sharedModelContainer = ZoneClockModelContainerFactory.makeSharedContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
