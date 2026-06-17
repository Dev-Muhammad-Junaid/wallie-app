import Foundation
import SwiftData

enum SampleData {
    static let previewContainer: ModelContainer = {
        let schema = Schema([
            ParentProfile.self, HealthMetric.self, Medication.self,
            MedicationLog.self, LabReport.self, LabResult.self
        ])
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
    static func seed(into context: ModelContext) {
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

        insertLabReport(
            context: context,
            parent: mom,
            title: "Annual Panel · Mar 2026",
            text: """
            Lab Report Date: 03/15/2026
            Glucose: 142 mg/dL
            HbA1c: 6.8 %
            Cholesterol: 215 mg/dL
            LDL: 130 mg/dL
            HDL: 45 mg/dL
            Creatinine: 1.0 mg/dL
            """,
            labDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        )

        insertLabReport(
            context: context,
            parent: mom,
            title: "Follow-up · Jan 2026",
            text: """
            Date: 01/10/2026
            Glucose: 128 mg/dL
            HbA1c: 6.4 %
            Cholesterol: 198 mg/dL
            LDL: 118 mg/dL
            """,
            labDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 10))!
        )

        insertLabReport(
            context: context,
            parent: mom,
            title: "Baseline · Sep 2025",
            text: """
            Date: 09/05/2025
            Glucose: 118 mg/dL
            HbA1c: 6.1 %
            Cholesterol: 190 mg/dL
            LDL: 110 mg/dL
            """,
            labDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 5))!
        )
    }

    @MainActor
    private static func insertLabReport(
        context: ModelContext,
        parent: ParentProfile,
        title: String,
        text: String,
        labDate: Date
    ) {
        let parsed = LabReportParser.parse(text: text)
        let report = LabReport(
            title: title,
            rawText: text,
            labDate: labDate,
            summaryInsight: LabReportParser.generateInsights(results: parsed, parentName: parent.name),
            analysisProvider: "On-Device",
            parent: parent
        )
        context.insert(report)
        for item in parsed {
            context.insert(LabResult(
                testKey: item.testKey.rawValue,
                testName: item.testName,
                value: item.value,
                unit: item.unit,
                referenceRange: item.referenceRange,
                isAbnormal: item.isAbnormal,
                labReport: report
            ))
        }
    }

    static var sampleLabReport: LabReport {
        let text = "Glucose: 142 mg/dL\nHbA1c: 6.8 %"
        let parsed = LabReportParser.parse(text: text)
        let report = LabReport(
            title: "Sample Panel",
            rawText: text,
            summaryInsight: LabReportParser.generateInsights(results: parsed, parentName: "Margaret")
        )
        for item in parsed {
            report.results.append(LabResult(
                testKey: item.testKey.rawValue,
                testName: item.testName,
                value: item.value,
                unit: item.unit,
                referenceRange: item.referenceRange,
                isAbnormal: item.isAbnormal,
                labReport: report
            ))
        }
        return report
    }
}
