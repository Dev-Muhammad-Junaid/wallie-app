import Foundation
import SwiftData

enum SampleData {
    static let previewContainer: ModelContainer = {
        let schema = Schema([ParentProfile.self, HealthMetric.self, Medication.self, MedicationLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        seed(into: container.mainContext)
        return container
    }()

    static var previewParent: ParentProfile {
        let parent = ParentProfile(
            name: "Margaret Chen",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -72, to: Date())!,
            bloodType: "A+",
            conditions: ["Hypertension", "Type 2 Diabetes"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142"
        )
        return parent
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ParentProfile>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        seed(into: context)
    }

    @MainActor
    private static func seed(into context: ModelContext) {
        let mom = ParentProfile(
            name: "Margaret Chen",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -72, to: Date())!,
            bloodType: "A+",
            conditions: ["Hypertension", "Type 2 Diabetes"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142",
            notes: "Prefers morning walks. Allergic to penicillin.",
            avatarHue: 0.52
        )

        let dad = ParentProfile(
            name: "Robert Chen",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -75, to: Date())!,
            bloodType: "O+",
            conditions: ["Arthritis"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142",
            avatarHue: 0.62
        )

        context.insert(mom)
        context.insert(dad)

        let calendar = Calendar.current
        for dayOffset in stride(from: -30, through: 0, by: 2) {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!

            let momBP = HealthMetric(
                type: .bloodPressure,
                value: Double.random(in: 118...142),
                secondaryValue: Double.random(in: 72...88),
                recordedAt: date,
                parent: mom
            )
            let momWeight = HealthMetric(
                type: .weight,
                value: Double.random(in: 62...65),
                recordedAt: date,
                parent: mom
            )
            let momGlucose = HealthMetric(
                type: .bloodGlucose,
                value: Double.random(in: 95...165),
                recordedAt: date,
                parent: mom
            )

            context.insert(momBP)
            context.insert(momWeight)
            context.insert(momGlucose)

            let dadHR = HealthMetric(
                type: .heartRate,
                value: Double.random(in: 62...88),
                recordedAt: date,
                parent: dad
            )
            context.insert(dadHR)
        }

        let lisinopril = Medication(
            name: "Lisinopril",
            dosage: "10mg",
            frequency: "Daily",
            reminderHours: [8],
            parent: mom
        )
        let metformin = Medication(
            name: "Metformin",
            dosage: "500mg",
            frequency: "Twice daily",
            reminderHours: [8, 20],
            parent: mom
        )
        let aspirin = Medication(
            name: "Aspirin",
            dosage: "81mg",
            frequency: "Daily",
            reminderHours: [8],
            parent: dad
        )

        context.insert(lisinopril)
        context.insert(metformin)
        context.insert(aspirin)

        for _ in 0..<10 {
            let log = MedicationLog(status: .taken, takenAt: Date().addingTimeInterval(Double.random(in: -604800...0)), medication: lisinopril)
            context.insert(log)
        }
    }
}
