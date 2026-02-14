import SwiftUI
import SwiftData

struct EditPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Team.sortOrder) private var teams: [Team]
    @Bindable var person: Person

    @State private var showingTimezonePicker = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            nameSection
            timezoneSection
            workHoursSection
            teamSection
            deleteSection
        }
        .navigationTitle("Edit Person")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimezonePicker) {
            TimezonePicker(selectedTimezone: $person.timezoneIdentifier)
        }
        .alert("Delete Person", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(person)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(person.name)?")
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Name", text: $person.name)
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
            Picker("Start", selection: $person.workStartHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
            Picker("End", selection: $person.workEndHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
        }
    }

    private var teamSection: some View {
        Section("Team") {
            Picker("Team", selection: $person.teamId) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(teams) { team in
                    Text(team.name).tag(Optional(team.id))
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Person", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
    }

    private var displayTimezone: String {
        let tz = TimeZone(identifier: person.timezoneIdentifier) ?? .current
        return tz.localizedName(for: .shortGeneric, locale: .current) ?? person.timezoneIdentifier
    }
}
