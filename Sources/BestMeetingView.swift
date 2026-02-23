import SwiftUI

struct BestMeetingView: View {
    let people: [Person]
    let currentTime: Date
    private static let slotIncrementMinutes = 15

    private var utcDayStart: Date {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = utcCalendar.dateComponents([.year, .month, .day], from: currentTime)
        return utcCalendar.date(from: components) ?? currentTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if overlapSlots.isEmpty {
                noOverlapView
            } else {
                ForEach(overlapSlots, id: \.startMinuteUTC) { slot in
                    slotRow(slot)
                }
            }
        }
    }

    private var noOverlapView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text("No full overlap found for all members")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func slotRow(_ slot: OverlapSlot) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.green)
                .frame(width: 4, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.displayRange(utcDayStart: utcDayStart))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(slot.localTimes(for: people, utcDayStart: utcDayStart))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(slot.durationLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var overlapSlots: [OverlapSlot] {
        guard !people.isEmpty else { return [] }
        var slots: [OverlapSlot] = []
        var currentStart: Int?

        for utcMinute in stride(
            from: 0,
            to: ClockMath.minutesPerDay,
            by: Self.slotIncrementMinutes
        ) {
            let utcDate = utcDayStart.addingTimeInterval(TimeInterval(utcMinute * 60))
            let allWorking = people.allSatisfy { person in
                let localMinute = ClockMath.localMinute(for: utcDate, in: person.timeZone)
                let workHours = WorkHours(
                    startHour: person.workStartHour,
                    endHour: person.workEndHour
                )
                return workHours.contains(minuteOfDay: localMinute)
            }

            if allWorking {
                if currentStart == nil {
                    currentStart = utcMinute
                }
            } else {
                if let start = currentStart {
                    slots.append(
                        OverlapSlot(
                            startMinuteUTC: start,
                            endMinuteUTC: utcMinute
                        )
                    )
                    currentStart = nil
                }
            }
        }
        if let start = currentStart {
            slots.append(
                OverlapSlot(
                    startMinuteUTC: start,
                    endMinuteUTC: ClockMath.minutesPerDay
                )
            )
        }
        return slots
    }
}

struct OverlapSlot {
    let startMinuteUTC: Int
    let endMinuteUTC: Int

    var durationMinutes: Int {
        endMinuteUTC - startMinuteUTC
    }

    var durationLabel: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours == 0 {
            return "\(minutes)m"
        }
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    func displayRange(utcDayStart: Date) -> String {
        let utcStartDate = utcDayStart.addingTimeInterval(TimeInterval(startMinuteUTC * 60))
        let utcEndDate = utcDayStart.addingTimeInterval(TimeInterval(endMinuteUTC * 60))
        let localStart = ClockMath.localMinute(for: utcStartDate, in: .current)
        let localEnd = ClockMath.localMinute(for: utcEndDate, in: .current)
        return "\(ClockMath.formattedTime(from: localStart)) – \(ClockMath.formattedTime(from: localEnd))"
    }

    func localTimes(for people: [Person], utcDayStart: Date) -> String {
        let utcStartDate = utcDayStart.addingTimeInterval(TimeInterval(startMinuteUTC * 60))
        let utcEndDate = utcDayStart.addingTimeInterval(TimeInterval(endMinuteUTC * 60))

        return people.map { person -> String in
            let localStart = ClockMath.localMinute(for: utcStartDate, in: person.timeZone)
            let localEnd = ClockMath.localMinute(for: utcEndDate, in: person.timeZone)
            return "\(person.name): \(ClockMath.formattedTime(from: localStart))-\(ClockMath.formattedTime(from: localEnd))"
        }.joined(separator: " · ")
    }
}
