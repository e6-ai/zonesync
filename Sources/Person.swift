import Foundation
import SwiftData

@Model
final class Person {
    var name: String
    var timezoneIdentifier: String
    var workStartHour: Int
    var workEndHour: Int
    var colorHex: String
    var teamId: UUID?
    var sortOrder: Int

    init(
        name: String,
        timezoneIdentifier: String,
        workStartHour: Int = 9,
        workEndHour: Int = 17,
        colorHex: String = "4A90D9",
        teamId: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.timezoneIdentifier = timezoneIdentifier
        self.workStartHour = workStartHour
        self.workEndHour = workEndHour
        self.colorHex = colorHex
        self.teamId = teamId
        self.sortOrder = sortOrder
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }
}
