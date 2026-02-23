import WidgetKit
import SwiftUI
import SwiftData

struct ZoneClockWidgetEntry: TimelineEntry {
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

struct ZoneClockWidgetProvider: TimelineProvider {
    let modelContainer: ModelContainer

    init() {
        modelContainer = ZoneClockModelContainerFactory.makeSharedContainer()
    }

    func placeholder(in context: Context) -> ZoneClockWidgetEntry {
        ZoneClockWidgetEntry(date: Date(), people: [
            WidgetPerson(name: "New York", timezoneIdentifier: "America/New_York", workStartHour: 9, workEndHour: 17),
            WidgetPerson(name: "London", timezoneIdentifier: "Europe/London", workStartHour: 9, workEndHour: 17),
            WidgetPerson(name: "Tokyo", timezoneIdentifier: "Asia/Tokyo", workStartHour: 9, workEndHour: 17)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ZoneClockWidgetEntry) -> Void) {
        let entry = ZoneClockWidgetEntry(date: Date(), people: fetchPeople())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZoneClockWidgetEntry>) -> Void) {
        let entry = ZoneClockWidgetEntry(date: Date(), people: fetchPeople())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchPeople() -> [WidgetPerson] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\Person.sortOrder)])
        let results = (try? context.fetch(descriptor)) ?? []

        return results.map {
            WidgetPerson(
                name: $0.name,
                timezoneIdentifier: $0.timezoneIdentifier,
                workStartHour: $0.workStartHour,
                workEndHour: $0.workEndHour
            )
        }
    }
}

struct ZoneClockWidgetView: View {
    let entry: ZoneClockWidgetEntry
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
            Text("Add people in ZoneClock")
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
        case .systemSmall:
            return 3
        case .systemMedium:
            return 4
        default:
            return 6
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
        let minute = ClockMath.currentLocalMinute(for: person.timeZone, at: entry.date)
        return ClockMath.formattedTime(from: minute)
    }

    private func statusColor(for person: WidgetPerson) -> Color {
        let workHours = WorkHours(startHour: person.workStartHour, endHour: person.workEndHour)
        let localMinute = ClockMath.currentLocalMinute(for: person.timeZone, at: entry.date)
        let distanceToWorkWindow = workHours.distanceToRange(minutesFrom: localMinute)
        if distanceToWorkWindow == 0 {
            return .green
        } else if distanceToWorkWindow <= 120 {
            return .yellow
        }
        return .red
    }
}

@main
struct ZoneClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZoneClockMainWidget()
    }
}

struct ZoneClockMainWidget: Widget {
    let kind = "ZoneClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZoneClockWidgetProvider()) { entry in
            ZoneClockWidgetView(entry: entry)
        }
        .configurationDisplayName("ZoneClock")
        .description("See all your team's local times at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
