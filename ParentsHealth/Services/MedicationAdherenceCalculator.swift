import Foundation

enum MedicationAdherenceCalculator {
    static func adherence(
        reminderHoursPerDay: Int,
        takenCount: Int,
        periodDays: Int = 7
    ) -> Double {
        let expected = reminderHoursPerDay * periodDays
        guard expected > 0 else { return 1.0 }
        return min(1.0, Double(takenCount) / Double(expected))
    }
}
