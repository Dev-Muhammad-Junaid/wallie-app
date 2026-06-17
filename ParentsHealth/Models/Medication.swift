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

    var parent: ParentProfile?

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.medication)
    var logs: [MedicationLog]

    init(
        name: String,
        dosage: String,
        frequency: String = "Daily",
        reminderHours: [Int] = [8, 20],
        isActive: Bool = true,
        parent: ParentProfile? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderHours = reminderHours
        self.isActive = isActive
        self.createdAt = Date()
        self.parent = parent
        self.logs = []
    }

    var todayLogs: [MedicationLog] {
        let start = Calendar.current.startOfDay(for: Date())
        return logs.filter { $0.takenAt >= start }
    }

    var adherenceThisWeek: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let expectedDoses = reminderHours.count * 7
        guard expectedDoses > 0 else { return 1.0 }
        let taken = logs.filter { $0.takenAt >= weekAgo && $0.status == .taken }.count
        return min(1.0, Double(taken) / Double(expectedDoses))
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
