import Foundation
import SwiftData
import SwiftUI

enum AppMediaMode {
    private enum Flag {
        static let enabled = "-media-mode"
        static let tab = "-media-tab"
        static let video = "-media-video"
        static let reset = "-media-reset"
    }

    enum Screen: Equatable {
        case home
        case addPerson
        case teams
        case editPerson
        case timezone
    }

    static var enabled: Bool {
        ProcessInfo.processInfo.arguments.contains(Flag.enabled)
    }

    static var videoAutoplay: Bool {
        ProcessInfo.processInfo.arguments.contains(Flag.video)
    }

    static var resetStore: Bool {
        ProcessInfo.processInfo.arguments.contains(Flag.reset)
    }

    static var requestedScreen: Screen {
        guard let value = value(after: Flag.tab),
              let screen = screen(from: value) else {
            return .home
        }
        return screen
    }

    static var referenceDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        return calendar.date(from: components) ?? Date()
    }

    private static func screen(from rawValue: String) -> Screen? {
        switch rawValue.lowercased() {
        case "home", "timeline", "main":
            return .home
        case "add", "add-person", "person-add":
            return .addPerson
        case "teams", "manage-teams":
            return .teams
        case "edit", "edit-person", "person-edit":
            return .editPerson
        case "timezone", "timezone-picker":
            return .timezone
        default:
            return nil
        }
    }

    private static func value(after flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag),
              args.indices.contains(index + 1) else {
            return nil
        }
        return args[index + 1]
    }
}

@MainActor
enum AppMediaSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        guard AppMediaMode.enabled else { return }

        if AppMediaMode.resetStore {
            clearStore(modelContext: modelContext)
        }

        let existingPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
        let existingTeams = (try? modelContext.fetch(FetchDescriptor<Team>())) ?? []
        guard existingPeople.isEmpty && existingTeams.isEmpty else { return }

        let teams = [
            Team(name: "Engineering", sortOrder: 0),
            Team(name: "Product", sortOrder: 1),
            Team(name: "Support", sortOrder: 2),
        ]

        for team in teams {
            modelContext.insert(team)
        }

        let teamByName = Dictionary(uniqueKeysWithValues: teams.map { ($0.name, $0.id) })
        let samplePeople: [(name: String, timezone: String, startHour: Int, endHour: Int, team: String)] = [
            ("Maya", "America/Los_Angeles", 8, 16, "Engineering"),
            ("Jordan", "America/New_York", 9, 17, "Product"),
            ("Alex", "Europe/London", 9, 18, "Engineering"),
            ("Priya", "Asia/Kolkata", 10, 19, "Support"),
            ("Kenji", "Asia/Tokyo", 9, 18, "Product"),
        ]

        for (index, sample) in samplePeople.enumerated() {
            let person = Person(
                name: sample.name,
                timezoneIdentifier: sample.timezone,
                workStartHour: sample.startHour,
                workEndHour: sample.endHour,
                teamId: teamByName[sample.team],
                sortOrder: index
            )
            modelContext.insert(person)
        }

        try? modelContext.save()
    }

    private static func clearStore(modelContext: ModelContext) {
        let people = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
        for person in people {
            modelContext.delete(person)
        }

        let teams = (try? modelContext.fetch(FetchDescriptor<Team>())) ?? []
        for team in teams {
            modelContext.delete(team)
        }

        try? modelContext.save()
    }
}

struct MediaRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @State private var hasSeededMediaData = false
    @State private var autoplayScreen: AppMediaMode.Screen = AppMediaMode.requestedScreen
    @State private var mediaTimezoneSelection = "Europe/London"

    private var activeScreen: AppMediaMode.Screen {
        AppMediaMode.videoAutoplay ? autoplayScreen : AppMediaMode.requestedScreen
    }

    var body: some View {
        Group {
            switch activeScreen {
            case .home:
                ContentView(initialTime: AppMediaMode.referenceDate, usesLiveClock: false)
            case .addPerson:
                AddPersonView()
            case .teams:
                ManageTeamsView()
            case .editPerson:
                editPersonScreen
            case .timezone:
                TimezonePicker(selectedTimezone: $mediaTimezoneSelection)
            }
        }
        .onAppear {
            guard !hasSeededMediaData else { return }
            hasSeededMediaData = true
            AppMediaSeeder.seedIfNeeded(modelContext: modelContext)
        }
        .task(id: AppMediaMode.videoAutoplay) {
            guard AppMediaMode.videoAutoplay else { return }
            await runAutoplayLoop()
        }
    }

    @ViewBuilder
    private var editPersonScreen: some View {
        if let person = people.first {
            NavigationStack {
                EditPersonView(person: person)
            }
        } else {
            ContentUnavailableView("Preparing Media Data", systemImage: "hourglass")
        }
    }

    @MainActor
    private func runAutoplayLoop() async {
        let sequence: [AppMediaMode.Screen] = [.home, .teams, .addPerson, .editPerson, .timezone, .home]
        var index = 0
        autoplayScreen = sequence[index]

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            if Task.isCancelled { return }
            index = (index + 1) % sequence.count
            withAnimation(.easeInOut(duration: 0.8)) {
                autoplayScreen = sequence[index]
            }
        }
    }
}
