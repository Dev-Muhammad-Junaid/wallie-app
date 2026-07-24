import Foundation

enum MedicationAdherenceCalculator {
    /// Adherence over a period, respecting how many days the med was actually due.
    static func adherence(
        reminderHoursPerDay: Int,
        takenCount: Int,
        dueDaysInPeriod: Int? = nil,
        frequency: MedicationFrequency = .daily,
        periodDays: Int = 7
    ) -> Double {
        if frequency == .asNeeded {
            // As-needed has no expected dose count; show full adherence when unused.
            return 1.0
        }

        guard reminderHoursPerDay > 0 else { return 1.0 }

        let dueDays = dueDaysInPeriod ?? periodDays
        let expected = reminderHoursPerDay * max(dueDays, 0)
        guard expected > 0 else { return 1.0 }
        return min(1.0, Double(takenCount) / Double(expected))
    }
}
