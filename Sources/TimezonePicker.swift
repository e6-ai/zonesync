import SwiftUI

struct TimezonePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTimezone: String
    @State private var searchText = ""

    private var allTimezones: [(id: String, display: String, city: String)] {
        TimeZone.knownTimeZoneIdentifiers.compactMap { id in
            guard let tz = TimeZone(identifier: id) else { return nil }
            let city = id.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? id
            let offset = tz.secondsFromGMT(for: Date())
            let hours = offset / 3600
            let mins = abs(offset % 3600) / 60
            let offsetStr: String
            if mins == 0 {
                offsetStr = String(format: "UTC%+d", hours)
            } else {
                offsetStr = String(format: "UTC%+d:%02d", hours, mins)
            }
            let display = "\(city) (\(offsetStr))"
            return (id: id, display: display, city: city)
        }
        .sorted { $0.city < $1.city }
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
