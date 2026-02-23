import SwiftUI

struct PersonTimelineRow: View {
    let person: Person
    let currentTime: Date

    private var workHours: WorkHours {
        WorkHours(startHour: person.workStartHour, endHour: person.workEndHour)
    }

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
        ZStack(alignment: .leading) {
            ForEach(Array(workHours.ranges.enumerated()), id: \.offset) { _, range in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.3))
                    .frame(width: overlayWidth(for: range, totalWidth: width))
                    .offset(x: overlayOffset(for: range, totalWidth: width))
            }
        }
    }

    private func overlayWidth(for range: Range<Int>, totalWidth: CGFloat) -> CGFloat {
        let rangeMinutes = range.upperBound - range.lowerBound
        return CGFloat(rangeMinutes) / CGFloat(ClockMath.minutesPerDay) * totalWidth
    }

    private func overlayOffset(for range: Range<Int>, totalWidth: CGFloat) -> CGFloat {
        CGFloat(range.lowerBound) / CGFloat(ClockMath.minutesPerDay) * totalWidth
    }

    private func currentTimeIndicator(width: CGFloat) -> some View {
        let localMinute = ClockMath.currentLocalMinute(for: person.timeZone, at: currentTime)
        let fraction = Double(localMinute) / Double(ClockMath.minutesPerDay)

        return Circle()
            .fill(statusColor(localMinute: localMinute))
            .frame(width: 10, height: 10)
            .offset(x: fraction * width - 5)
    }

    private func statusColor(localMinute: Int) -> Color {
        let distanceToWorkWindow = workHours.distanceToRange(minutesFrom: localMinute)
        if distanceToWorkWindow == 0 {
            return .green
        } else if distanceToWorkWindow <= 120 {
            return .yellow
        }
        return .red
    }

    private var localTimeString: String {
        let localMinute = ClockMath.currentLocalMinute(for: person.timeZone, at: currentTime)
        return ClockMath.formattedTime(from: localMinute)
    }

    private var offsetLabel: String {
        ClockMath.utcOffsetLabel(for: person.timeZone, at: currentTime)
    }
}
