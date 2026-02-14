import SwiftUI

struct BestMeetingView: View {
    let people: [Person]
    let currentTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if overlapSlots.isEmpty {
                noOverlapView
            } else {
                ForEach(overlapSlots, id: \.startHourUTC) { slot in
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
                Text(slot.displayRange(for: people, currentTime: currentTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(slot.localTimes(for: people, currentTime: currentTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%dh", slot.durationHours))
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

        for utcHour in 0..<24 {
            let allWorking = people.allSatisfy { person in
                let offset = person.timeZone.secondsFromGMT(for: currentTime) / 3600
                let localHour = (utcHour + offset + 24) % 24
                return localHour >= person.workStartHour && localHour < person.workEndHour
            }

            if allWorking {
                if currentStart == nil {
                    currentStart = utcHour
                }
            } else {
                if let start = currentStart {
                    slots.append(OverlapSlot(startHourUTC: start, endHourUTC: utcHour))
                    currentStart = nil
                }
            }
        }
        if let start = currentStart {
            slots.append(OverlapSlot(startHourUTC: start, endHourUTC: 24))
        }
        return slots
    }
}

struct OverlapSlot {
    let startHourUTC: Int
    let endHourUTC: Int

    var durationHours: Int { endHourUTC - startHourUTC }

    func displayRange(for people: [Person], currentTime: Date) -> String {
        let userTZ = TimeZone.current
        let offset = userTZ.secondsFromGMT(for: currentTime) / 3600
        let localStart = (startHourUTC + offset + 24) % 24
        let localEnd = (endHourUTC + offset + 24) % 24
        return String(format: "%02d:00 – %02d:00", localStart, localEnd)
    }

    func localTimes(for people: [Person], currentTime: Date) -> String {
        people.map { person in
            let offset = person.timeZone.secondsFromGMT(for: currentTime) / 3600
            let localStart = (startHourUTC + offset + 24) % 24
            return String(format: "%@: %02d:00", person.name, localStart)
        }.joined(separator: " · ")
    }
}
