import SwiftUI
import SwiftData

struct ManageTeamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Team.sortOrder) private var teams: [Team]
    @State private var newTeamName = ""
    @State private var editingTeam: Team?

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
    }

    private func deleteTeams(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(teams[index])
        }
    }
}
