import SwiftUI
import SwiftData
import WidgetKit

struct AddPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query(sort: \Team.sortOrder) private var teams: [Team]

    @State private var name = ""
    @State private var selectedTimezone = TimeZone.current.identifier
    @State private var workStart = 9
    @State private var workEnd = 17
    @State private var selectedTeamId: UUID?
    @State private var showingTimezonePicker = false

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                timezoneSection
                workHoursSection
                teamSection
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { savePerson() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .sheet(isPresented: $showingTimezonePicker) {
                TimezonePicker(selectedTimezone: $selectedTimezone)
            }
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Person or city name", text: $name)
        }
    }

    private var timezoneSection: some View {
        Section("Timezone") {
            Button {
                showingTimezonePicker = true
            } label: {
                HStack {
                    Text(displayTimezone)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private var workHoursSection: some View {
        Section("Working Hours") {
            Picker("Start", selection: $workStart) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
            Picker("End", selection: $workEnd) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
        }
    }

    private var teamSection: some View {
        Section("Team (Optional)") {
            Picker("Team", selection: $selectedTeamId) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(teams) { team in
                    Text(team.name).tag(Optional(team.id))
                }
            }
        }
    }

    private var displayTimezone: String {
        let tz = TimeZone(identifier: selectedTimezone) ?? .current
        return tz.localizedName(for: .shortGeneric, locale: .current) ?? selectedTimezone
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func savePerson() {
        let nextSortOrder = (people.map(\.sortOrder).max() ?? -1) + 1
        let person = Person(
            name: trimmedName,
            timezoneIdentifier: selectedTimezone,
            workStartHour: workStart,
            workEndHour: workEnd,
            teamId: selectedTeamId,
            sortOrder: nextSortOrder
        )
        modelContext.insert(person)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
