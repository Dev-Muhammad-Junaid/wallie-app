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

    var referenceRangeDescription: String {
        switch self {
        case .bloodPressure: return "90–140 / 60–90 mmHg"
        case .weight: return "Varies by person"
        case .heartRate: return "60–100 bpm"
        case .bloodGlucose: return "70–140 mg/dL"
        }
    }

    func boundary(value: Double, secondaryValue: Double? = nil) -> AlertBoundary {
        switch self {
        case .bloodPressure:
            guard let diastolic = secondaryValue else { return .combinedOutOfRange }
            let sysHigh = value > 140
            let sysLow = value < 90
            let diaHigh = diastolic > 90
            let diaLow = diastolic < 60
            if sysHigh || diaHigh { return .aboveRange }
            if sysLow || diaLow { return .belowRange }
            return .combinedOutOfRange
        case .weight:
            return .combinedOutOfRange
        case .heartRate, .bloodGlucose:
            guard let range = normalRange else { return .combinedOutOfRange }
            if value > range.upperBound { return .aboveRange }
            if value < range.lowerBound { return .belowRange }
            return .combinedOutOfRange
        }
    }

    func severity(value: Double, secondaryValue: Double? = nil) -> AlertSeverity {
        switch self {
        case .bloodPressure:
            guard let diastolic = secondaryValue else { return .attention }
            if value >= 180 || diastolic >= 120 { return .critical }
            if value >= 160 || diastolic >= 100 { return .attention }
            if value < 90 || diastolic < 60 { return .attention }
            return .watch
        case .weight:
            return .watch
        case .heartRate:
            if value >= 120 || value < 50 { return .critical }
            if value > 100 || value < 60 { return .attention }
            return .watch
        case .bloodGlucose:
            if value >= 250 || value < 54 { return .critical }
            if value >= 180 || value < 70 { return .attention }
            return .watch
        }
    }

    func healthImpact(boundary: AlertBoundary, value: Double, secondaryValue: Double? = nil) -> String {
        switch self {
        case .bloodPressure:
            switch boundary {
            case .aboveRange:
                return "Sustained high blood pressure can strain the heart, kidneys, and blood vessels, raising stroke and heart attack risk over time."
            case .belowRange:
                return "Low blood pressure may cause dizziness, falls, or reduced blood flow to vital organs — especially important for older adults."
            case .combinedOutOfRange:
                return "Blood pressure outside the target range can affect cardiovascular health and daily energy levels."
            }
        case .weight:
            return "Weight changes over time can reflect fluid balance, nutrition, or underlying conditions worth tracking with a clinician."
        case .heartRate:
            switch boundary {
            case .aboveRange:
                return "A resting heart rate that is too high may reflect stress, dehydration, infection, or heart rhythm issues."
            case .belowRange:
                return "A very low heart rate can reduce circulation and cause fatigue or lightheadedness, especially if sudden."
            case .combinedOutOfRange:
                return "Heart rate outside the typical resting range may signal cardiovascular or metabolic stress."
            }
        case .bloodGlucose:
            switch boundary {
            case .aboveRange:
                return "High blood sugar over time can damage nerves, kidneys, eyes, and blood vessels — key concerns in diabetes management."
            case .belowRange:
                return "Low blood sugar can cause confusion, shakiness, or loss of consciousness and needs prompt attention if severe."
            case .combinedOutOfRange:
                return "Glucose outside target range affects energy metabolism and long-term organ health."
            }
        }
    }

    func careHint(for severity: AlertSeverity) -> String {
        switch severity {
        case .critical:
            return "Contact their doctor or care team promptly — especially if symptoms are present."
        case .attention:
            return "Log again soon and discuss with their physician at the next visit or sooner if symptoms worsen."
        case .watch:
            return "Keep monitoring and watch for patterns over the next few readings."
        }
    }
}
