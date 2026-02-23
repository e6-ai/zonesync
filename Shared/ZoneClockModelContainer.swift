import Foundation
import SwiftData

enum ZoneClockModelContainerFactory {
    private static let appGroupIdentifier = "group.ai.e6.zonesync"

    static func makeSharedContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(
                groupContainer: .identifier(appGroupIdentifier)
            )
            return try ModelContainer(for: Person.self, Team.self, configurations: configuration)
        } catch {
            assertionFailure("Falling back to local store because shared store setup failed: \(error)")
            do {
                return try ModelContainer(for: Person.self, Team.self)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
}
