import Foundation
import SwiftData

@Model
final class Team {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}
