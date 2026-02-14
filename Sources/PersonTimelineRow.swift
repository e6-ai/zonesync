import SwiftUI

struct PersonTimelineRow: View {
    let person: Person
    let currentTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            timelineBar
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(person.timeZone.localizedName(for: .shortGeneric, locale: .current) ?? person.timezoneIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(localTimeString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(offsetLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timelineBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 24-hour background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))

                // Working hours overlay
                workingHoursOverlay(width: geo.size.width)

                // Current time indicator
                currentTimeIndicator(width: geo.size.width)
            }
        }
        .frame(height: 24)
    }

    private func workingHoursOverlay(width: CGFloat) -> some View {
        let startFraction = Double(person.workStartHour) / 24.0
        let endFraction = Double(person.workEndHour) / 24.0
        let barWidth = (endFraction - startFraction) * width

        return RoundedRectangle(cornerRadius: 4)
            .fill(Color.green.opacity(0.3))
            .frame(width: barWidth)
            .offset(x: startFraction * width)
    }

    private func currentTimeIndicator(width: CGFloat) -> some View {
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = person.timeZone
        let hour = cal.component(.hour, from: currentTime)
        let minute = cal.component(.minute, from: currentTime)
        let fraction = (Double(hour) + Double(minute) / 60.0) / 24.0

        return Circle()
            .fill(statusColor(hour: hour))
            .frame(width: 10, height: 10)
            .offset(x: fraction * width - 5)
    }

    private func statusColor(hour: Int) -> Color {
        if hour >= person.workStartHour && hour < person.workEndHour {
            return .green
        } else if hour >= (person.workStartHour - 2) && hour < (person.workEndHour + 2) {
            return .yellow
        }
        return .red
    }

    private var localTimeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = person.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var offsetLabel: String {
        let seconds = person.timeZone.secondsFromGMT(for: currentTime)
        let hours = seconds / 3600
        let mins = abs(seconds % 3600) / 60
        if mins == 0 {
            return String(format: "UTC%+d", hours)
        }
        return String(format: "UTC%+d:%02d", hours, mins)
    }
}
