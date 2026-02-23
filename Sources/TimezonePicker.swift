import SwiftUI

struct TimezonePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTimezone: String
    @State private var searchText = ""

    private var allTimezones: [(id: String, display: String, city: String)] {
        let referenceDate = Date()
        let timezones = TimeZone.knownTimeZoneIdentifiers.compactMap { id -> (id: String, display: String, city: String)? in
            guard let tz = TimeZone(identifier: id) else { return nil }
            let city = id.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? id
            let offsetStr = ClockMath.utcOffsetLabel(for: tz, at: referenceDate)
            let display = "\(city) (\(offsetStr))"
            return (id: id, display: display, city: city)
        }
        return timezones.sorted { lhs, rhs in lhs.city < rhs.city }
    }

    private var filteredTimezones: [(id: String, display: String, city: String)] {
        if searchText.isEmpty { return allTimezones }
        let query = searchText.lowercased()
        return allTimezones.filter {
            $0.id.lowercased().contains(query) ||
            $0.city.lowercased().contains(query) ||
            $0.display.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredTimezones, id: \.id) { tz in
                Button {
                    selectedTimezone = tz.id
                    dismiss()
                } label: {
                    HStack {
                        Text(tz.display)
                            .foregroundStyle(.primary)
                        Spacer()
                        if tz.id == selectedTimezone {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search city or timezone")
            .navigationTitle("Select Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
