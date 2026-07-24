import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: String
    var reminderHours: [Int]
    var isActive: Bool
    var createdAt: Date
    /// Calendar weekday (1 = Sunday … 7 = Saturday) used when frequency is Weekly.
    var scheduleWeekday: Int
    /// Day of month (1–28 recommended) used when frequency is Monthly.
    var scheduleDayOfMonth: Int

    var parent: ParentProfile?

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.medication)
    var logs: [MedicationLog]

    init(
        name: String,
        dosage: String,
        frequency: String = MedicationFrequency.daily.rawValue,
        reminderHours: [Int] = [8, 20],
        isActive: Bool = true,
        scheduleWeekday: Int = Calendar.current.component(.weekday, from: Date()),
        scheduleDayOfMonth: Int = min(Calendar.current.component(.day, from: Date()), 28),
        parent: ParentProfile? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderHours = reminderHours
        self.isActive = isActive
        self.createdAt = Date()
        self.scheduleWeekday = scheduleWeekday
        self.scheduleDayOfMonth = scheduleDayOfMonth
        self.parent = parent
        self.logs = []
    }

    var frequencyKind: MedicationFrequency {
        get { MedicationFrequency.resolve(from: frequency) }
        set { frequency = newValue.rawValue }
    }

    var isDueToday: Bool {
        MedicationSchedule.isDue(
            frequency: frequencyKind,
            on: Date(),
            weekday: scheduleWeekday,
            dayOfMonth: scheduleDayOfMonth
        )
    }

    /// As-needed meds can always be logged; scheduled meds only when due today.
    var allowsDoseLoggingToday: Bool {
        frequencyKind == .asNeeded || isDueToday
    }

    var todayLogs: [MedicationLog] {
        let start = Calendar.current.startOfDay(for: Date())
        return logs
            .filter { $0.takenAt >= start }
            .sorted { $0.takenAt < $1.takenAt }
    }

    /// Today's log for a specific reminder hour (slot), if any.
    func todayLog(forHour hour: Int) -> MedicationLog? {
        let calendar = Calendar.current
        return todayLogs.last { calendar.component(.hour, from: $0.takenAt) == hour }
    }

    /// Reminder slots that still need a dose log today.
    var pendingReminderHoursToday: [Int] {
        guard allowsDoseLoggingToday else { return [] }
        return reminderHours.filter { todayLog(forHour: $0) == nil }.sorted()
    }

    var takenSlotsToday: Int {
        reminderHours.filter { todayLog(forHour: $0)?.status == .taken }.count
    }

    var scheduleSummary: String {
        switch frequencyKind {
        case .weekly:
            let name = Calendar.current.weekdaySymbols[safe: scheduleWeekday - 1] ?? "Weekly"
            return "Weekly · \(name)"
        case .monthly:
            return "Monthly · day \(scheduleDayOfMonth)"
        case .daily, .twiceDaily, .asNeeded:
            return frequency
        }
    }

    var adherenceThisWeek: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let taken = logs.filter { $0.takenAt >= weekAgo && $0.status == .taken }.count
        let dueDays = MedicationSchedule.dueDayCount(
            frequency: frequencyKind,
            weekday: scheduleWeekday,
            dayOfMonth: scheduleDayOfMonth,
            periodDays: 7
        )
        return MedicationAdherenceCalculator.adherence(
            reminderHoursPerDay: max(reminderHours.count, frequencyKind == .asNeeded ? 0 : 1),
            takenCount: taken,
            dueDaysInPeriod: dueDays,
            frequency: frequencyKind
        )
    }
}

enum MedicationStatus: String, Codable {
    case taken
    case skipped
    case missed
}

@Model
final class MedicationLog {
    var id: UUID
    var statusRaw: String
    var takenAt: Date
    var notes: String

    var medication: Medication?

    var status: MedicationStatus {
        get { MedicationStatus(rawValue: statusRaw) ?? .missed }
        set { statusRaw = newValue.rawValue }
    }

    init(status: MedicationStatus, takenAt: Date = Date(), notes: String = "", medication: Medication? = nil) {
        self.id = UUID()
        self.statusRaw = status.rawValue
        self.takenAt = takenAt
        self.notes = notes
        self.medication = medication
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
