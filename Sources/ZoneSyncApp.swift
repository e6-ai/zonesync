import SwiftUI
import SwiftData

@main
struct ZoneSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Person.self, Team.self])
    }
}
