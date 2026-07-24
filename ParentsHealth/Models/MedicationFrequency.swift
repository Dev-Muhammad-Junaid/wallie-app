import Foundation

/// Medication schedule cadence. Frequency string on Medication stays in sync with this.
enum MedicationFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case twiceDaily = "Twice daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case asNeeded = "As needed"

    var id: String { rawValue }

    static func resolve(from string: String) -> MedicationFrequency {
        MedicationFrequency(rawValue: string) ?? .daily
    }

    var showsDailyReminderToggles: Bool {
        switch self {
        case .daily, .twiceDaily, .weekly, .monthly:
            return true
        case .asNeeded:
            return false
        }
    }

    var needsWeekdayPicker: Bool {
        self == .weekly
    }

    var needsDayOfMonthPicker: Bool {
        self == .monthly
    }

    /// Default reminder hours when creating a med with this frequency.
    var defaultReminderHours: [Int] {
        switch self {
        case .twiceDaily: return [8, 20]
        case .asNeeded: return []
        case .daily, .weekly, .monthly: return [8]
        }
    }
}

enum MedicationSchedule {
    /// Whether a dose is expected on `date` for the given cadence.
    static func isDue(
        frequency: MedicationFrequency,
        on date: Date,
        weekday: Int,
        dayOfMonth: Int,
        calendar: Calendar = .current
    ) -> Bool {
        switch frequency {
        case .daily, .twiceDaily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: date) == weekday
        case .monthly:
            let day = calendar.component(.day, from: date)
            let lastDay = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
            let target = min(max(dayOfMonth, 1), lastDay)
            return day == target
        case .asNeeded:
            return false
        }
    }

    /// Count of due days in the last `periodDays` ending at `referenceDate`.
    static func dueDayCount(
        frequency: MedicationFrequency,
        weekday: Int,
        dayOfMonth: Int,
        periodDays: Int = 7,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard periodDays > 0 else { return 0 }
        var count = 0
        for offset in 0..<periodDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: referenceDate) else { continue }
            if isDue(
                frequency: frequency,
                on: day,
                weekday: weekday,
                dayOfMonth: dayOfMonth,
                calendar: calendar
            ) {
                count += 1
            }
        }
        return count
    }
}
