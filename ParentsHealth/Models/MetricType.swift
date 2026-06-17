import Foundation

enum MetricType: String, Codable, CaseIterable, Identifiable {
    case bloodPressure
    case weight
    case heartRate
    case bloodGlucose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bloodPressure: return "Blood Pressure"
        case .weight: return "Weight"
        case .heartRate: return "Heart Rate"
        case .bloodGlucose: return "Blood Glucose"
        }
    }

    var unit: String {
        switch self {
        case .bloodPressure: return "mmHg"
        case .weight: return "kg"
        case .heartRate: return "bpm"
        case .bloodGlucose: return "mg/dL"
        }
    }

    var icon: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .heartRate: return "waveform.path.ecg"
        case .bloodGlucose: return "drop.fill"
        }
    }

    var accentColorName: String {
        switch self {
        case .bloodPressure: return "MetricBP"
        case .weight: return "MetricWeight"
        case .heartRate: return "MetricHeart"
        case .bloodGlucose: return "MetricGlucose"
        }
    }

    /// Normal range for single-value metrics (BP uses systolic/diastolic separately).
    var normalRange: ClosedRange<Double>? {
        switch self {
        case .bloodPressure: return nil
        case .weight: return nil
        case .heartRate: return 60...100
        case .bloodGlucose: return 70...140
        }
    }

    func isNormal(value: Double, secondaryValue: Double? = nil) -> Bool {
        switch self {
        case .bloodPressure:
            guard let diastolic = secondaryValue else { return false }
            return (90...140).contains(value) && (60...90).contains(diastolic)
        case .weight:
            return true
        case .heartRate, .bloodGlucose:
            guard let range = normalRange else { return true }
            return range.contains(value)
        }
    }
}
