import Foundation

enum ClockMath {
    static let minutesPerDay = 24 * 60

    static func localMinute(for utcDate: Date, in timeZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: utcDate)
        let minute = calendar.component(.minute, from: utcDate)
        return (hour * 60 + minute).positiveModulo(minutesPerDay)
    }

    static func currentLocalMinute(for timeZone: TimeZone, at date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour * 60 + minute).positiveModulo(minutesPerDay)
    }

    static func formattedTime(from minuteOfDay: Int) -> String {
        let minute = minuteOfDay.positiveModulo(minutesPerDay)
        return String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    static func utcOffsetLabel(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60
        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }
        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }
}

struct WorkHours {
    let startHour: Int
    let endHour: Int

    var startMinute: Int {
        startHour.positiveModulo(24) * 60
    }

    var endMinute: Int {
        endHour.positiveModulo(24) * 60
    }

    var ranges: [Range<Int>] {
        if startMinute == endMinute {
            return [0..<ClockMath.minutesPerDay]
        }
        if startMinute < endMinute {
            return [startMinute..<endMinute]
        }
        return [startMinute..<ClockMath.minutesPerDay, 0..<endMinute]
    }

    func contains(minuteOfDay: Int) -> Bool {
        let minute = minuteOfDay.positiveModulo(ClockMath.minutesPerDay)
        return ranges.contains { $0.contains(minute) }
    }

    func distanceToRange(minutesFrom minuteOfDay: Int) -> Int {
        let minute = minuteOfDay.positiveModulo(ClockMath.minutesPerDay)
        if contains(minuteOfDay: minute) {
            return 0
        }

        var bestDistance = ClockMath.minutesPerDay
        let probeMinutes = [minute, minute + ClockMath.minutesPerDay]
        let candidateRanges = ranges + ranges.map {
            ($0.lowerBound + ClockMath.minutesPerDay)..<($0.upperBound + ClockMath.minutesPerDay)
        }

        for probe in probeMinutes {
            for range in candidateRanges {
                if probe < range.lowerBound {
                    bestDistance = min(bestDistance, range.lowerBound - probe)
                } else if probe >= range.upperBound {
                    bestDistance = min(bestDistance, probe - range.upperBound)
                } else {
                    return 0
                }
            }
        }

        return bestDistance
    }
}

extension Int {
    func positiveModulo(_ divisor: Int) -> Int {
        precondition(divisor > 0, "Divisor must be positive")
        let remainder = self % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
