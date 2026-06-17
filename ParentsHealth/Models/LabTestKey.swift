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
        let lowered = name.lowercased()
        return LabTestKey.allCases.first { key in
            key.aliases.contains { lowered.contains($0) } || lowered == key.rawValue
        }
    }
}
