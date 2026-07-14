import Foundation
import UIKit

enum ReportExportService {
    static func generateTextReport(parent: ParentProfile) -> String {
        var lines: [String] = []
        lines.append("ParentsHealth Report")
        lines.append("Generated: \(Date().formatted(date: .long, time: .shortened))")
        lines.append("")
        lines.append("Patient: \(parent.name)")
        lines.append("Age: \(parent.age) · Blood Type: \(parent.bloodType)")
        if !parent.conditions.isEmpty {
            lines.append("Conditions: \(parent.conditions.joined(separator: ", "))")
        }
        lines.append("Health Score: \(parent.healthScore())/100")
        lines.append("")

        let alerts = HealthAlertService.alerts(for: parent)
        lines.append("── Active Health Alerts ──")
        if alerts.isEmpty {
            lines.append("All tracked vitals and labs within range.")
        } else {
            for alert in alerts {
                lines.append("! \(alert.title): \(alert.valueText) — \(alert.severity.title)")
            }
        }
        lines.append("")

        lines.append("── Recent Vitals (last 30 days) ──")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentMetrics = parent.metrics
            .filter { $0.recordedAt >= thirtyDaysAgo }
            .sorted { $0.recordedAt > $1.recordedAt }

        if recentMetrics.isEmpty {
            lines.append("No vitals recorded.")
        } else {
            for metric in recentMetrics.prefix(20) {
                let status = metric.isInNormalRange ? "✓" : "!"
                lines.append("\(status) \(metric.recordedAt.formatted(date: .abbreviated, time: .omitted)) — \(metric.type.title): \(metric.displayValue) \(metric.type.unit)")
            }
            if recentMetrics.count > 20 {
                lines.append("… \(recentMetrics.count - 20) more readings not shown")
            }
        }

        lines.append("")
        lines.append("── Medications ──")
        if parent.medications.isEmpty {
            lines.append("None recorded.")
        } else {
            for med in parent.medications {
                let adherence = Int(med.adherenceThisWeek * 100)
                lines.append("• \(med.name) \(med.dosage) — \(med.frequency) — \(adherence)% adherence")
            }
        }

        lines.append("")
        lines.append("── Lab Reports ──")
        if parent.labReports.isEmpty {
            lines.append("None imported.")
        } else {
            for report in parent.labReports.sorted(by: { $0.importedAt > $1.importedAt }).prefix(3) {
                lines.append("• \(report.title) (\(report.importedAt.formatted(date: .abbreviated, time: .omitted)))")
                if !report.summaryInsight.isEmpty {
                    lines.append("  \(report.summaryInsight.replacingOccurrences(of: "\n", with: "\n  "))")
                }
            }
        }

        lines.append("")
        lines.append("This report is for personal tracking only. Not medical advice.")
        return lines.joined(separator: "\n")
    }

    static func shareItems(for parent: ParentProfile) -> [Any] {
        [generateTextReport(parent: parent)]
    }
}
