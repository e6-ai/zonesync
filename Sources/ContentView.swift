import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query(sort: \Team.sortOrder) private var teams: [Team]
    @State private var showingAddPerson = false
    @State private var showingManageTeams = false
    @State private var selectedTeamId: UUID?
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    currentTimeHeader
                    if !filteredPeople.isEmpty {
                        timelineSection
                        bestMeetingSection
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("ZoneClock")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView()
            }
            .sheet(isPresented: $showingManageTeams) {
                ManageTeamsView()
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .onChange(of: teams.map(\.id)) { _, teamIDs in
                if let selectedTeamId, !teamIDs.contains(selectedTeamId) {
                    self.selectedTeamId = nil
                }
            }
        }
    }

    private var filteredPeople: [Person] {
        if let teamId = selectedTeamId {
            return people.filter { $0.teamId == teamId }
        }
        return people
    }

    private var currentTimeHeader: some View {
        VStack(spacing: 8) {
            if !teams.isEmpty {
                teamPicker
            }
            Text(currentTime.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var teamPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                teamFilterChip(label: "All", teamId: nil)
                ForEach(teams) { team in
                    teamFilterChip(label: team.name, teamId: team.id)
                }
            }
        }
    }

    private func teamFilterChip(label: String, teamId: UUID?) -> some View {
        Button {
            selectedTeamId = teamId
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(selectedTeamId == teamId ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTeamId == teamId ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(selectedTeamId == teamId ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timelines")
                .font(.headline)
            ForEach(filteredPeople) { person in
                NavigationLink {
                    EditPersonView(person: person)
                } label: {
                    PersonTimelineRow(person: person, currentTime: currentTime)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bestMeetingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Meeting Times")
                .font(.headline)
            BestMeetingView(people: filteredPeople, currentTime: currentTime)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.americas")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Add people to see their timezones")
                .foregroundStyle(.secondary)
            Button("Add Person") {
                showingAddPerson = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingManageTeams = true
            } label: {
                Image(systemName: "folder")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddPerson = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
