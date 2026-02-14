import WidgetKit
import SwiftUI
import SwiftData

struct ZoneSyncWidgetEntry: TimelineEntry {
    let date: Date
    let people: [WidgetPerson]
}

struct WidgetPerson: Identifiable {
    let id = UUID()
    let name: String
    let timezoneIdentifier: String
    let workStartHour: Int
    let workEndHour: Int

    var timeZone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }
}

struct ZoneSyncWidgetProvider: TimelineProvider {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Person.self, Team.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    func placeholder(in context: Context) -> ZoneSyncWidgetEntry {
        ZoneSyncWidgetEntry(date: Date(), people: [
            WidgetPerson(name: "New York", timezoneIdentifier: "America/New_York", workStartHour: 9, workEndHour: 17),
            WidgetPerson(name: "London", timezoneIdentifier: "Europe/London", workStartHour: 9, workEndHour: 17),
            WidgetPerson(name: "Tokyo", timezoneIdentifier: "Asia/Tokyo", workStartHour: 9, workEndHour: 17)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ZoneSyncWidgetEntry) -> Void) {
        let entry = ZoneSyncWidgetEntry(date: Date(), people: fetchPeople())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZoneSyncWidgetEntry>) -> Void) {
        let entry = ZoneSyncWidgetEntry(date: Date(), people: fetchPeople())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    @MainActor
    private func fetchPeople() -> [WidgetPerson] {
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.sortOrder)])
        let results = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
        return results.map {
            WidgetPerson(name: $0.name, timezoneIdentifier: $0.timezoneIdentifier, workStartHour: $0.workStartHour, workEndHour: $0.workEndHour)
        }
    }
}

struct ZoneSyncWidgetView: View {
    let entry: ZoneSyncWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.people.isEmpty {
            emptyView
        } else {
            peopleList
        }
    }

    private var emptyView: some View {
        VStack {
            Image(systemName: "globe.americas")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Add people in ZoneSync")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.people.prefix(maxPeople)) { person in
                widgetPersonRow(person)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var maxPeople: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 6
        }
    }

    private func widgetPersonRow(_ person: WidgetPerson) -> some View {
        HStack {
            Circle()
                .fill(statusColor(for: person))
                .frame(width: 6, height: 6)
            Text(person.name)
                .font(.caption2)
                .lineLimit(1)
            Spacer()
            Text(timeString(for: person))
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func timeString(for person: WidgetPerson) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = person.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }

    private func statusColor(for person: WidgetPerson) -> Color {
        var cal = Calendar.current
        cal.timeZone = person.timeZone
        let hour = cal.component(.hour, from: entry.date)
        if hour >= person.workStartHour && hour < person.workEndHour {
            return .green
        } else if hour >= (person.workStartHour - 2) && hour < (person.workEndHour + 2) {
            return .yellow
        }
        return .red
    }
}

@main
struct ZoneSyncWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZoneSyncMainWidget()
    }
}

struct ZoneSyncMainWidget: Widget {
    let kind = "ZoneSyncWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZoneSyncWidgetProvider()) { entry in
            ZoneSyncWidgetView(entry: entry)
        }
        .configurationDisplayName("Zone Sync")
        .description("See all your team's local times at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
