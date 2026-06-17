import Foundation
import SwiftData

@Model
final class HealthMetric {
    var id: UUID
    var typeRaw: String
    var value: Double
    var secondaryValue: Double?
    var notes: String
    var recordedAt: Date

    var parent: ParentProfile?

    var type: MetricType {
        get { MetricType(rawValue: typeRaw) ?? .heartRate }
        set { typeRaw = newValue.rawValue }
    }

    init(
        type: MetricType,
        value: Double,
        secondaryValue: Double? = nil,
        notes: String = "",
        recordedAt: Date = Date(),
        parent: ParentProfile? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.value = value
        self.secondaryValue = secondaryValue
        self.notes = notes
        self.recordedAt = recordedAt
        self.parent = parent
    }

    var displayValue: String {
        switch type {
        case .bloodPressure:
            let diastolic = Int(secondaryValue ?? 0)
            return "\(Int(value))/\(diastolic)"
        case .weight:
            return String(format: "%.1f", value)
        default:
            return "\(Int(value))"
        }
    }

    var isInNormalRange: Bool {
        type.isNormal(value: value, secondaryValue: secondaryValue)
    }
}
