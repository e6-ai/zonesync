import SwiftUI
import SwiftData
import WidgetKit

struct ManageTeamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query(sort: \Team.sortOrder) private var teams: [Team]
    @State private var newTeamName = ""

    var body: some View {
        NavigationStack {
            List {
                addSection
                if !teams.isEmpty {
                    teamsSection
                }
            }
            .navigationTitle("Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var addSection: some View {
        Section {
            HStack {
                TextField("New team name", text: $newTeamName)
                Button {
                    addTeam()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var teamsSection: some View {
        Section("Your Teams") {
            ForEach(teams) { team in
                Text(team.name)
            }
            .onDelete(perform: deleteTeams)
        }
    }

    private func addTeam() {
        let team = Team(name: newTeamName.trimmingCharacters(in: .whitespaces), sortOrder: teams.count)
        modelContext.insert(team)
        newTeamName = ""
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteTeams(at offsets: IndexSet) {
        for index in offsets {
            let team = teams[index]
            for person in people where person.teamId == team.id {
                person.teamId = nil
            }
            modelContext.delete(team)
        }
        if !offsets.isEmpty {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
