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
        var latest: [MetricType: HealthMetric] = [:]
        for metric in metrics.sorted(by: { $0.recordedAt > $1.recordedAt }) {
            if latest[metric.type] == nil {
                latest[metric.type] = metric
            }
        }
        return Array(latest.values)
    }

    func healthScore(referenceDate: Date = Date()) -> Int {
        let snapshots = metrics.map(HealthMetricSnapshot.init)
        return HealthScoreCalculator.score(from: snapshots, referenceDate: referenceDate)
    }
}
