import Foundation
import SwiftData

enum SampleData {
    private static let demoYearDays = 365

    @MainActor
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
        ParentProfile(
            name: "Margaret Chen",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -72, to: Date())!,
            bloodType: "A+",
            conditions: ["Hypertension", "Type 2 Diabetes"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142"
        )
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ParentProfile>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        seed(into: context)
    }

    /// Replaces all stored data with two parents and one full year of demo history.
    @MainActor
    static func loadYearDemo(into context: ModelContext) {
        if let parents = try? context.fetch(FetchDescriptor<ParentProfile>()) {
            for parent in parents {
                context.delete(parent)
            }
        }
        try? context.save()
        seed(into: context)
    }

    @MainActor
    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yearAgo = calendar.date(byAdding: .day, value: -demoYearDays, to: today)!

        let mom = ParentProfile(
            name: "Margaret Chen",
            dateOfBirth: calendar.date(byAdding: .year, value: -72, to: Date())!,
            bloodType: "A+",
            conditions: ["Hypertension", "Type 2 Diabetes", "Mild Anemia"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142",
            notes: "Prefers morning walks. Allergic to penicillin. Uses a home BP cuff daily.",
            avatarHue: 0.52
        )

        let dad = ParentProfile(
            name: "Robert Chen",
            dateOfBirth: calendar.date(byAdding: .year, value: -75, to: Date())!,
            bloodType: "O+",
            conditions: ["Arthritis", "Mild Hypertension"],
            emergencyContact: "David Chen",
            emergencyPhone: "+1 555-0142",
            notes: "Retired teacher. Daily walks with Margaret. Takes aspirin for heart health.",
            avatarHue: 0.62
        )

        context.insert(mom)
        context.insert(dad)

        seedMargaretVitals(for: mom, context: context, calendar: calendar, today: today)
        seedRobertVitals(for: dad, context: context, calendar: calendar, today: today)

        let momMeds = seedMargaretMedications(for: mom, yearAgo: yearAgo, calendar: calendar, today: today, context: context)
        let dadMeds = seedRobertMedications(for: dad, yearAgo: yearAgo, calendar: calendar, today: today, context: context)

        seedMedicationLogs(
            medications: momMeds + dadMeds,
            yearAgo: yearAgo,
            calendar: calendar,
            today: today,
            context: context
        )

        seedMargaretLabReports(for: mom, calendar: calendar, today: today, context: context)
        seedRobertLabReports(for: dad, calendar: calendar, today: today, context: context)

        seedCareNetwork(for: mom, dad: dad, calendar: calendar, today: today, context: context)

        try? context.save()
    }

    @MainActor
    private static func seedCareNetwork(
        for mom: ParentProfile,
        dad: ParentProfile,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) {
        let cardiologist = CareProvider(
            name: "Dr. Anita Patel",
            specialty: "Cardiology",
            phone: "+1 555-0188",
            email: "apatel@heartclinic.example",
            clinic: "Bay Heart Clinic",
            notes: "Sees Margaret every 3 months for BP and cholesterol.",
            parent: mom
        )
        let endocrinologist = CareProvider(
            name: "Dr. Marcus Lee",
            specialty: "Endocrinology",
            phone: "+1 555-0199",
            clinic: "Metabolic Care Center",
            parent: mom
        )
        let gp = CareProvider(
            name: "Dr. Helen Brooks",
            specialty: "Primary Care",
            phone: "+1 555-0177",
            clinic: "Neighborhood Family Practice",
            parent: dad
        )
        for provider in [cardiologist, endocrinologist, gp] {
            context.insert(provider)
        }

        let momVisit = Appointment(
            title: "Cardiology follow-up",
            scheduledAt: calendar.date(byAdding: .day, value: 18, to: today)!.addingTimeInterval(10 * 3600),
            location: "Bay Heart Clinic",
            notes: "Bring latest BP log and lab printout.",
            reminderMinutesBefore: 60 * 24,
            parent: mom,
            provider: cardiologist
        )
        let dadVisit = Appointment(
            title: "Annual checkup",
            scheduledAt: calendar.date(byAdding: .day, value: 32, to: today)!.addingTimeInterval(9.5 * 3600),
            location: "Neighborhood Family Practice",
            reminderMinutesBefore: 60 * 24 * 2,
            parent: dad,
            provider: gp
        )
        context.insert(momVisit)
        context.insert(dadVisit)
    }

    // MARK: - Vitals

    @MainActor
    private static func seedMargaretVitals(
        for parent: ParentProfile,
        context: ModelContext,
        calendar: Calendar,
        today: Date
    ) {
        for dayOffset in (-demoYearDays)...0 {
            let dayIndex = dayOffset + demoYearDays
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let fromHealthKit = dayIndex.isMultiple(of: 9)

            if dayIndex.isMultiple(of: 1) {
                let glucose = DemoTrends.glucose(dayIndex: dayIndex, totalDays: demoYearDays)
                insertMetric(
                    context: context,
                    type: .bloodGlucose,
                    value: glucose,
                    notes: fromHealthKit ? "Imported from HealthKit" : "",
                    date: timestamp(on: date, hour: 7, minute: 15 + (dayIndex % 20), calendar: calendar),
                    parent: parent
                )
            }

            if dayIndex.isMultiple(of: 2) {
                let systolic = DemoTrends.systolic(dayIndex: dayIndex, totalDays: demoYearDays)
                let diastolic = DemoTrends.diastolic(dayIndex: dayIndex, totalDays: demoYearDays)
                insertMetric(
                    context: context,
                    type: .bloodPressure,
                    value: systolic,
                    secondary: diastolic,
                    notes: fromHealthKit ? "Imported from HealthKit" : "",
                    date: timestamp(on: date, hour: 8, minute: 10 + (dayIndex % 25), calendar: calendar),
                    parent: parent
                )
            }

            if dayIndex.isMultiple(of: 3) {
                insertMetric(
                    context: context,
                    type: .heartRate,
                    value: DemoTrends.heartRate(dayIndex: dayIndex, base: 74, swing: 14),
                    date: timestamp(on: date, hour: 9, minute: dayIndex % 40, calendar: calendar),
                    parent: parent
                )
            }

            if dayIndex.isMultiple(of: 7) {
                insertMetric(
                    context: context,
                    type: .weight,
                    value: DemoTrends.margaretWeight(dayIndex: dayIndex, totalDays: demoYearDays),
                    date: timestamp(on: date, hour: 7, minute: 30, calendar: calendar),
                    parent: parent
                )
            }
        }
    }

    @MainActor
    private static func seedRobertVitals(
        for parent: ParentProfile,
        context: ModelContext,
        calendar: Calendar,
        today: Date
    ) {
        for dayOffset in (-demoYearDays)...0 {
            let dayIndex = dayOffset + demoYearDays
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!

            insertMetric(
                context: context,
                type: .heartRate,
                value: DemoTrends.heartRate(dayIndex: dayIndex, base: 68, swing: 10),
                notes: dayIndex.isMultiple(of: 14) ? "Imported from HealthKit" : "",
                date: timestamp(on: date, hour: 8, minute: dayIndex % 35, calendar: calendar),
                parent: parent
            )

            if dayIndex.isMultiple(of: 3) {
                let systolic = DemoTrends.systolic(dayIndex: dayIndex, totalDays: demoYearDays, base: 128, rise: 8)
                let diastolic = DemoTrends.diastolic(dayIndex: dayIndex, totalDays: demoYearDays, base: 78, rise: 4)
                insertMetric(
                    context: context,
                    type: .bloodPressure,
                    value: systolic,
                    secondary: diastolic,
                    date: timestamp(on: date, hour: 8, minute: 20, calendar: calendar),
                    parent: parent
                )
            }

            if dayIndex.isMultiple(of: 7) {
                insertMetric(
                    context: context,
                    type: .weight,
                    value: DemoTrends.robertWeight(dayIndex: dayIndex, totalDays: demoYearDays),
                    date: timestamp(on: date, hour: 7, minute: 45, calendar: calendar),
                    parent: parent
                )
            }

            if dayIndex.isMultiple(of: 30) {
                insertMetric(
                    context: context,
                    type: .bloodGlucose,
                    value: DemoTrends.glucose(dayIndex: dayIndex, totalDays: demoYearDays, base: 92, rise: 18),
                    date: timestamp(on: date, hour: 10, minute: 0, calendar: calendar),
                    parent: parent
                )
            }
        }
    }

    @MainActor
    private static func insertMetric(
        context: ModelContext,
        type: MetricType,
        value: Double,
        secondary: Double? = nil,
        notes: String = "",
        date: Date,
        parent: ParentProfile
    ) {
        let metric = HealthMetric(
            type: type,
            value: value,
            secondaryValue: secondary,
            notes: notes,
            recordedAt: date,
            parent: parent
        )
        context.insert(metric)
    }

    // MARK: - Medications

    private struct DemoMedication {
        let medication: Medication
        let activeUntilDayIndex: Int?
    }

    @MainActor
    private static func seedMargaretMedications(
        for parent: ParentProfile,
        yearAgo: Date,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) -> [DemoMedication] {
        let lisinopril = Medication(
            name: "Lisinopril",
            dosage: "10mg",
            frequency: "Daily",
            reminderHours: [8],
            parent: parent
        )
        lisinopril.createdAt = yearAgo

        let metformin = Medication(
            name: "Metformin",
            dosage: "500mg",
            frequency: "Twice daily",
            reminderHours: [8, 20],
            parent: parent
        )
        metformin.createdAt = yearAgo

        let atorvastatin = Medication(
            name: "Atorvastatin",
            dosage: "20mg",
            frequency: MedicationFrequency.monthly.rawValue,
            reminderHours: [21],
            scheduleDayOfMonth: 1,
            parent: parent
        )
        atorvastatin.createdAt = calendar.date(byAdding: .month, value: -10, to: today)!

        let b12 = Medication(
            name: "Vitamin B12",
            dosage: "1000 mcg",
            frequency: MedicationFrequency.weekly.rawValue,
            reminderHours: [9],
            scheduleWeekday: 2, // Monday
            parent: parent
        )
        b12.createdAt = calendar.date(byAdding: .month, value: -6, to: today)!

        let discontinued = Medication(
            name: "Low-Dose Aspirin",
            dosage: "81mg",
            frequency: MedicationFrequency.daily.rawValue,
            reminderHours: [8],
            isActive: false,
            parent: parent
        )
        discontinued.createdAt = yearAgo

        for med in [lisinopril, metformin, atorvastatin, b12, discontinued] {
            context.insert(med)
        }

        return [
            DemoMedication(medication: lisinopril, activeUntilDayIndex: nil),
            DemoMedication(medication: metformin, activeUntilDayIndex: nil),
            DemoMedication(medication: atorvastatin, activeUntilDayIndex: nil),
            DemoMedication(medication: b12, activeUntilDayIndex: nil),
            DemoMedication(medication: discontinued, activeUntilDayIndex: demoYearDays - 90)
        ]
    }

    @MainActor
    private static func seedRobertMedications(
        for parent: ParentProfile,
        yearAgo: Date,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) -> [DemoMedication] {
        let aspirin = Medication(
            name: "Aspirin",
            dosage: "81mg",
            frequency: "Daily",
            reminderHours: [8],
            parent: parent
        )
        aspirin.createdAt = yearAgo

        let vitaminD = Medication(
            name: "Vitamin D3",
            dosage: "2000 IU",
            frequency: "Daily",
            reminderHours: [12],
            parent: parent
        )
        vitaminD.createdAt = calendar.date(byAdding: .month, value: -8, to: today)!

        let ibuprofen = Medication(
            name: "Ibuprofen",
            dosage: "200mg",
            frequency: "As needed",
            reminderHours: [14, 22],
            parent: parent
        )
        ibuprofen.createdAt = yearAgo

        for med in [aspirin, vitaminD, ibuprofen] {
            context.insert(med)
        }

        return [
            DemoMedication(medication: aspirin, activeUntilDayIndex: nil),
            DemoMedication(medication: vitaminD, activeUntilDayIndex: nil),
            DemoMedication(medication: ibuprofen, activeUntilDayIndex: nil)
        ]
    }

    @MainActor
    private static func seedMedicationLogs(
        medications: [DemoMedication],
        yearAgo: Date,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) {
        for entry in medications {
            let med = entry.medication
            let endDayIndex = entry.activeUntilDayIndex ?? demoYearDays

            for dayOffset in (-demoYearDays)...0 {
                let dayIndex = dayOffset + demoYearDays
                guard dayIndex <= endDayIndex else { continue }
                if !med.isActive, let cutoff = entry.activeUntilDayIndex, dayIndex > cutoff {
                    continue
                }

                let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
                guard day >= calendar.startOfDay(for: med.createdAt) else { continue }
                guard MedicationSchedule.isDue(
                    frequency: med.frequencyKind,
                    on: day,
                    weekday: med.scheduleWeekday,
                    dayOfMonth: med.scheduleDayOfMonth,
                    calendar: calendar
                ) || med.frequencyKind == .asNeeded else { continue }

                for (slot, hour) in med.reminderHours.enumerated() {
                    let roll = (dayIndex * 13 + slot * 5 + med.name.count) % 100
                    let status: MedicationStatus
                    if roll < 84 {
                        status = .taken
                    } else if roll < 93 {
                        status = .skipped
                    } else {
                        status = .missed
                    }

                    // PRN ibuprofen — only log on ~30% of days
                    if med.frequencyKind == .asNeeded, roll % 3 != 0 { continue }

                    let takenAt = timestamp(on: day, hour: hour, minute: (roll % 45), calendar: calendar)
                    context.insert(MedicationLog(status: status, takenAt: takenAt, medication: med))
                }
            }
        }
    }

    // MARK: - Lab reports

    @MainActor
    private static func seedMargaretLabReports(
        for parent: ParentProfile,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) {
        let panels: [(monthsAgo: Int, title: String, values: DemoLabPanel)] = [
            (12, "Annual Panel · Jun 2025", DemoLabPanel(
                glucose: 108, hba1c: 5.9, cholesterol: 188, ldl: 108, hdl: 52,
                triglycerides: 138, creatinine: 0.92, hemoglobin: 13.2, wbc: 6.8,
                platelet: 245, tsh: 2.1, vitaminD: 34
            )),
            (9, "Quarterly Check · Sep 2025", DemoLabPanel(
                glucose: 118, hba1c: 6.2, cholesterol: 198, ldl: 118, hdl: 48,
                triglycerides: 152, creatinine: 0.96, hemoglobin: 12.8, wbc: 7.1,
                platelet: 238, tsh: 2.4, vitaminD: 31
            )),
            (6, "Diabetes Follow-up · Dec 2025", DemoLabPanel(
                glucose: 132, hba1c: 6.6, cholesterol: 208, ldl: 128, hdl: 45,
                triglycerides: 168, creatinine: 1.02, hemoglobin: 12.4, wbc: 7.4,
                platelet: 232, tsh: 2.6, vitaminD: 28
            )),
            (3, "Spring Panel · Mar 2026", DemoLabPanel(
                glucose: 142, hba1c: 6.9, cholesterol: 218, ldl: 138, hdl: 42,
                triglycerides: 182, creatinine: 1.08, hemoglobin: 11.9, wbc: 7.8,
                platelet: 228, tsh: 2.9, vitaminD: 26
            )),
            (0, "Recent Draw · Jun 2026", DemoLabPanel(
                glucose: 148, hba1c: 7.1, cholesterol: 224, ldl: 142, hdl: 40,
                triglycerides: 195, creatinine: 1.10, hemoglobin: 11.6, wbc: 8.0,
                platelet: 220, tsh: 3.1, vitaminD: 24
            ))
        ]

        for panel in panels {
            let labDate = calendar.date(byAdding: .month, value: -panel.monthsAgo, to: today)!
            insertLabPanel(
                context: context,
                parent: parent,
                title: panel.title,
                labDate: labDate,
                panel: panel.values
            )
        }
    }

    @MainActor
    private static func seedRobertLabReports(
        for parent: ParentProfile,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) {
        let panels: [(monthsAgo: Int, title: String, values: DemoLabPanel)] = [
            (11, "Annual Physical · Jul 2025", DemoLabPanel(
                glucose: 94, hba1c: 5.4, cholesterol: 192, ldl: 112, hdl: 55,
                triglycerides: 118, creatinine: 0.98, hemoglobin: 14.8, wbc: 6.2,
                platelet: 255, tsh: 1.8, vitaminD: 38
            )),
            (5, "Mid-Year Panel · Jan 2026", DemoLabPanel(
                glucose: 98, hba1c: 5.5, cholesterol: 198, ldl: 118, hdl: 52,
                triglycerides: 128, creatinine: 1.02, hemoglobin: 14.5, wbc: 6.5,
                platelet: 248, tsh: 2.0, vitaminD: 35
            )),
            (1, "Arthritis Follow-up · May 2026", DemoLabPanel(
                glucose: 102, hba1c: 5.6, cholesterol: 204, ldl: 122, hdl: 50,
                triglycerides: 136, creatinine: 1.04, hemoglobin: 14.2, wbc: 6.9,
                platelet: 242, tsh: 2.2, vitaminD: 32
            ))
        ]

        for panel in panels {
            let labDate = calendar.date(byAdding: .month, value: -panel.monthsAgo, to: today)!
            insertLabPanel(
                context: context,
                parent: parent,
                title: panel.title,
                labDate: labDate,
                panel: panel.values
            )
        }
    }

    @MainActor
    private static func insertLabPanel(
        context: ModelContext,
        parent: ParentProfile,
        title: String,
        labDate: Date,
        panel: DemoLabPanel
    ) {
        let entries: [(LabTestKey, Double)] = [
            (.glucose, panel.glucose),
            (.hba1c, panel.hba1c),
            (.cholesterol, panel.cholesterol),
            (.ldl, panel.ldl),
            (.hdl, panel.hdl),
            (.triglycerides, panel.triglycerides),
            (.creatinine, panel.creatinine),
            (.hemoglobin, panel.hemoglobin),
            (.wbc, panel.wbc),
            (.platelet, panel.platelet),
            (.tsh, panel.tsh),
            (.vitaminD, panel.vitaminD)
        ]

        let rawLines = entries.map { key, value in
            "\(key.title): \(formatLabValue(value)) \(key.unit)"
        }
        let rawText = "Lab Report Date: \(labDate.formatted(date: .abbreviated, time: .omitted))\n" + rawLines.joined(separator: "\n")

        let parsed = entries.map { key, value in
            ParsedLabResult(
                testKey: key,
                testName: key.title,
                value: value,
                unit: key.unit,
                referenceRange: key.referenceRangeDescription,
                isAbnormal: key.isAbnormal(value)
            )
        }

        let report = LabReport(
            title: title,
            rawText: rawText,
            importedAt: calendar.date(byAdding: .day, value: 1, to: labDate) ?? labDate,
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

    // MARK: - Helpers

    private static var calendar: Calendar { Calendar.current }

    private static func timestamp(on day: Date, hour: Int, minute: Int, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func formatLabValue(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}

// MARK: - Demo generators

private struct DemoLabPanel {
    let glucose: Double
    let hba1c: Double
    let cholesterol: Double
    let ldl: Double
    let hdl: Double
    let triglycerides: Double
    let creatinine: Double
    let hemoglobin: Double
    let wbc: Double
    let platelet: Double
    let tsh: Double
    let vitaminD: Double
}

private enum DemoTrends {
    static func glucose(dayIndex: Int, totalDays: Int, base: Double = 102, rise: Double = 38) -> Double {
        let progress = Double(dayIndex) / Double(max(totalDays, 1))
        let seasonal = sin(Double(dayIndex) / 18.0) * 10
        let weekly = cos(Double(dayIndex) / 3.5) * 6
        return clamp(base + progress * rise + seasonal + weekly, min: 82, max: 210)
    }

    static func systolic(dayIndex: Int, totalDays: Int, base: Double = 122, rise: Double = 18) -> Double {
        let progress = Double(dayIndex) / Double(max(totalDays, 1))
        let spike = dayIndex.isMultiple(of: 47) ? 22.0 : 0
        return clamp(base + progress * rise + sin(Double(dayIndex) / 12) * 8 + spike, min: 108, max: 178)
    }

    static func diastolic(dayIndex: Int, totalDays: Int, base: Double = 76, rise: Double = 10) -> Double {
        let progress = Double(dayIndex) / Double(max(totalDays, 1))
        return clamp(base + progress * rise + cos(Double(dayIndex) / 14) * 5, min: 62, max: 102)
    }

    static func heartRate(dayIndex: Int, base: Double, swing: Double) -> Double {
        clamp(base + sin(Double(dayIndex) / 5.5) * swing + cos(Double(dayIndex) / 11) * (swing / 2), min: 52, max: 112)
    }

    static func margaretWeight(dayIndex: Int, totalDays: Int) -> Double {
        let progress = Double(dayIndex) / Double(max(totalDays, 1))
        return clamp(63.8 + progress * 1.4 + sin(Double(dayIndex) / 30) * 0.6, min: 62.5, max: 66.5)
    }

    static func robertWeight(dayIndex: Int, totalDays: Int) -> Double {
        let progress = Double(dayIndex) / Double(max(totalDays, 1))
        return clamp(78.5 - progress * 0.8 + cos(Double(dayIndex) / 28) * 0.5, min: 76.5, max: 79.5)
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
