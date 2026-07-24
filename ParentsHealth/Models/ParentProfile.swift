import Foundation
import SwiftData

@Model
final class ParentProfile {
    var id: UUID
    var name: String
    var dateOfBirth: Date
    var bloodType: String
    var conditions: [String]
    var emergencyContact: String
    var emergencyPhone: String
    var notes: String
    var avatarHue: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HealthMetric.parent)
    var metrics: [HealthMetric]

    @Relationship(deleteRule: .cascade, inverse: \Medication.parent)
    var medications: [Medication]

    @Relationship(deleteRule: .cascade, inverse: \LabReport.parent)
    var labReports: [LabReport]

    @Relationship(deleteRule: .cascade, inverse: \CareProvider.parent)
    var careProviders: [CareProvider]

    @Relationship(deleteRule: .cascade, inverse: \Appointment.parent)
    var appointments: [Appointment]

    init(
        name: String,
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -70, to: Date()) ?? Date(),
        bloodType: String = "O+",
        conditions: [String] = [],
        emergencyContact: String = "",
        emergencyPhone: String = "",
        notes: String = "",
        avatarHue: Double = Double.random(in: 0.45...0.65)
    ) {
        self.id = UUID()
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.conditions = conditions
        self.emergencyContact = emergencyContact
        self.emergencyPhone = emergencyPhone
        self.notes = notes
        self.avatarHue = avatarHue
        self.createdAt = Date()
        self.metrics = []
        self.medications = []
        self.labReports = []
        self.careProviders = []
        self.appointments = []
    }

    var upcomingAppointments: [Appointment] {
        appointments
            .filter(\.isUpcoming)
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var nextAppointment: Appointment? {
        upcomingAppointments.first
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var latestMetrics: [HealthMetric] {
        recentMetrics(withinDays: 7)
    }

    /// Latest reading per metric type within the given day window.
    func recentMetrics(withinDays days: Int, referenceDate: Date = Date()) -> [HealthMetric] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate
        var latest: [MetricType: HealthMetric] = [:]
        for metric in metrics
            .filter({ $0.recordedAt >= cutoff })
            .sorted(by: { $0.recordedAt > $1.recordedAt }) {
            if latest[metric.type] == nil {
                latest[metric.type] = metric
            }
        }
        return MetricType.allCases.compactMap { latest[$0] }
    }

    func healthScore(referenceDate: Date = Date()) -> Int {
        let snapshots = metrics.map(HealthMetricSnapshot.init)
        return HealthScoreCalculator.score(from: snapshots, referenceDate: referenceDate)
    }
}

extension ParentProfile {
    /// Snapshot for verifying imported and logged data in Settings.
    struct DataOverview {
        let vitalsTotal: Int
        let vitalsFromHealthKit: Int
        let vitalsLast14Days: Int
        let labReports: Int
        let labValues: Int
        let medications: Int
        let lastVitalDate: Date?
        let lastLabDate: Date?

        var lastVitalLabel: String {
            lastVitalDate?.formatted(date: .abbreviated, time: .shortened) ?? "None yet"
        }

        var lastLabLabel: String {
            lastLabDate?.formatted(date: .abbreviated, time: .omitted) ?? "None yet"
        }
    }

    var dataOverview: DataOverview {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let healthKitMetrics = metrics.filter { $0.notes.localizedCaseInsensitiveContains("HealthKit") }
        let recent = metrics.filter { $0.recordedAt >= cutoff }
        let labDates = labReports.map(\.effectiveDate)

        return DataOverview(
            vitalsTotal: metrics.count,
            vitalsFromHealthKit: healthKitMetrics.count,
            vitalsLast14Days: recent.count,
            labReports: labReports.count,
            labValues: labReports.reduce(0) { $0 + $1.results.count },
            medications: medications.count,
            lastVitalDate: metrics.map(\.recordedAt).max(),
            lastLabDate: labDates.max()
        )
    }
}
