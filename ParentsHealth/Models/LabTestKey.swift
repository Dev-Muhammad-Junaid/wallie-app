import Foundation
import SwiftUI

/// Canonical lab test identifiers used for charting across multiple reports.
enum LabTestKey: String, CaseIterable, Identifiable, Codable {
    case glucose
    case hba1c
    case cholesterol
    case ldl
    case hdl
    case triglycerides
    case creatinine
    case hemoglobin
    case wbc
    case platelet
    case tsh
    case vitaminD

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glucose: return "Glucose"
        case .hba1c: return "HbA1c"
        case .cholesterol: return "Cholesterol"
        case .ldl: return "LDL"
        case .hdl: return "HDL"
        case .triglycerides: return "Triglycerides"
        case .creatinine: return "Creatinine"
        case .hemoglobin: return "Hemoglobin"
        case .wbc: return "WBC"
        case .platelet: return "Platelets"
        case .tsh: return "TSH"
        case .vitaminD: return "Vitamin D"
        }
    }

    var unit: String {
        switch self {
        case .glucose, .cholesterol, .ldl, .hdl, .triglycerides: return "mg/dL"
        case .hba1c: return "%"
        case .creatinine: return "mg/dL"
        case .hemoglobin: return "g/dL"
        case .wbc, .platelet: return "K/uL"
        case .tsh: return "mIU/L"
        case .vitaminD: return "ng/mL"
        }
    }

    var icon: String {
        switch self {
        case .glucose: return "drop.fill"
        case .hba1c: return "percent"
        case .cholesterol, .ldl, .hdl, .triglycerides: return "heart.fill"
        case .creatinine: return "kidneys"
        case .hemoglobin: return "cross.vial.fill"
        case .wbc, .platelet: return "circle.hexagongrid.fill"
        case .tsh: return "bolt.heart.fill"
        case .vitaminD: return "sun.max.fill"
        }
    }

    var chartColor: Color {
        switch self {
        case .glucose: return AppTheme.metricGlucose
        case .hba1c: return AppTheme.warmCoral
        case .cholesterol: return Color.purple.opacity(0.85)
        case .ldl: return AppTheme.metricBP
        case .hdl: return AppTheme.softMint
        case .triglycerides: return Color.orange
        case .creatinine: return Color.cyan
        case .hemoglobin: return Color.red.opacity(0.8)
        case .wbc, .platelet: return Color.indigo.opacity(0.8)
        case .tsh: return Color.yellow.opacity(0.9)
        case .vitaminD: return Color.orange.opacity(0.85)
        }
    }

    /// Aliases used when matching OCR / API result names.
    var aliases: [String] {
        switch self {
        case .glucose: return ["glucose", "fasting glucose", "blood glucose"]
        case .hba1c: return ["hba1c", "a1c", "hemoglobin a1c"]
        case .cholesterol: return ["cholesterol", "total cholesterol"]
        case .ldl: return ["ldl", "ldl cholesterol"]
        case .hdl: return ["hdl", "hdl cholesterol"]
        case .triglycerides: return ["triglycerides"]
        case .creatinine: return ["creatinine"]
        case .hemoglobin: return ["hemoglobin", "hgb"]
        case .wbc: return ["wbc", "white blood cell"]
        case .platelet: return ["platelet", "plt"]
        case .tsh: return ["tsh"]
        case .vitaminD: return ["vitamin d", "25-oh vitamin d"]
        }
    }

    static func resolve(from name: String) -> LabTestKey? {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var bestMatch: (key: LabTestKey, aliasLength: Int)?

        for key in LabTestKey.allCases {
            if lowered == key.rawValue {
                return key
            }
            for alias in key.aliases where lowered.contains(alias) {
                if bestMatch == nil || alias.count > bestMatch!.aliasLength {
                    bestMatch = (key, alias.count)
                }
            }
        }

        return bestMatch?.key
    }

    var defaultRange: ClosedRange<Double> {
        switch self {
        case .glucose: return 70...100
        case .hba1c: return 4.0...5.7
        case .cholesterol: return 0...200
        case .ldl: return 0...100
        case .hdl: return 40...100
        case .triglycerides: return 0...150
        case .creatinine: return 0.6...1.2
        case .hemoglobin: return 12.0...17.5
        case .wbc: return 4.5...11.0
        case .platelet: return 150...400
        case .tsh: return 0.4...4.0
        case .vitaminD: return 30...100
        }
    }

    /// When true, values above the upper bound are the primary concern (e.g. LDL). When false, low values are bad (e.g. HDL).
    var highIsBad: Bool {
        switch self {
        case .hdl, .hemoglobin, .vitaminD: return false
        default: return true
        }
    }

    var referenceRangeDescription: String {
        let range = defaultRange
        let lower = formatBound(range.lowerBound)
        let upper = formatBound(range.upperBound)
        return "\(lower)–\(upper) \(unit)"
    }

    /// Shared abnormal check used by parser, seeder, import, and UI.
    func isAbnormal(_ value: Double) -> Bool {
        let range = defaultRange
        if highIsBad {
            return value > range.upperBound || value < range.lowerBound
        }
        return value < range.lowerBound || value > range.upperBound
    }

    /// Whether an increase is concerning for this marker (false for HDL, hemoglobin, vitamin D).
    func isWorseningDelta(_ delta: Double) -> Bool {
        if abs(delta) < 0.0001 { return false }
        return highIsBad ? delta > 0 : delta < 0
    }

    func deltaColor(for delta: Double) -> Color {
        if abs(delta) < 0.0001 { return .white.opacity(0.55) }
        return isWorseningDelta(delta) ? AppTheme.warmCoral.opacity(0.9) : AppTheme.softMint
    }

    func boundary(for value: Double) -> AlertBoundary {
        let range = defaultRange
        if highIsBad {
            if value > range.upperBound { return .aboveRange }
            if value < range.lowerBound { return .belowRange }
        } else if value < range.lowerBound {
            return .belowRange
        } else if value > range.upperBound {
            return .aboveRange
        }
        return .combinedOutOfRange
    }

    func severity(for value: Double) -> AlertSeverity {
        let range = defaultRange
        let span = max(range.upperBound - range.lowerBound, 1)

        if highIsBad {
            if value > range.upperBound + span * 0.5 || value < range.lowerBound - span * 0.3 {
                return .critical
            }
            if value > range.upperBound + span * 0.15 || value < range.lowerBound {
                return .attention
            }
        } else if value < range.lowerBound {
            let deficit = (range.lowerBound - value) / span
            if deficit > 0.35 { return .critical }
            if deficit > 0.1 { return .attention }
        } else if value > range.upperBound {
            return .watch
        }

        return .watch
    }

    func healthImpact(for boundary: AlertBoundary) -> String {
        switch self {
        case .glucose:
            return boundary == .aboveRange
                ? "Elevated glucose suggests reduced blood sugar control and can affect kidneys, nerves, and cardiovascular health over time."
                : "Low glucose can cause weakness, confusion, or fainting and may need dietary or medication review."
        case .hba1c:
            return "HbA1c reflects average blood sugar over ~3 months. Higher values are linked to diabetes complications affecting eyes, kidneys, and heart."
        case .cholesterol, .ldl:
            return "High LDL or total cholesterol contributes to artery plaque buildup, increasing heart attack and stroke risk."
        case .hdl:
            return "Low HDL ('good' cholesterol) reduces the body's ability to clear artery plaque and is associated with higher cardiovascular risk."
        case .triglycerides:
            return "High triglycerides are tied to pancreatitis risk and often accompany insulin resistance and heart disease."
        case .creatinine:
            return "Elevated creatinine may indicate reduced kidney filtration — important to review with medications and hydration."
        case .hemoglobin:
            return boundary == .belowRange
                ? "Low hemoglobin (anemia) can cause fatigue, shortness of breath, and reduced oxygen delivery to tissues."
                : "Very high hemoglobin may reflect dehydration or other conditions affecting blood thickness."
        case .wbc:
            return boundary == .aboveRange
                ? "High white blood cell count may signal infection, inflammation, or immune system activation."
                : "Low WBC can weaken infection defenses — especially relevant during illness or certain treatments."
        case .platelet:
            return boundary == .belowRange
                ? "Low platelets increase bruising and bleeding risk."
                : "High platelets can raise clotting risk and may need clinical follow-up."
        case .tsh:
            return boundary == .aboveRange
                ? "High TSH often suggests an underactive thyroid, which can affect energy, weight, mood, and heart rate."
                : "Low TSH may indicate an overactive thyroid, affecting metabolism, bone health, and heart rhythm."
        case .vitaminD:
            return "Low vitamin D is linked to bone weakness, muscle pain, and immune function — common in older adults with limited sun exposure."
        }
    }

    func careHint(for severity: AlertSeverity) -> String {
        switch severity {
        case .critical:
            return "Share this lab result with their doctor soon — do not wait for the next routine visit if they feel unwell."
        case .attention:
            return "Compare with prior labs in Charts and discuss lifestyle or medication adjustments with their care team."
        case .watch:
            return "Track the next lab draw to see if this is a one-time fluctuation or a pattern."
        }
    }

    private func formatBound(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}
