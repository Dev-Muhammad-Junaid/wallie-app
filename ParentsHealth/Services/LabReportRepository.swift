import Foundation
import SwiftData

/// Persists analyzed lab data in a consistent format for charts and history.
enum LabReportRepository {
    @MainActor
    static func save(
        analysis: LabAnalysisResult,
        parent: ParentProfile,
        title: String?,
        context: ModelContext
    ) -> LabReport {
        let reportTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? title!.trimmingCharacters(in: .whitespacesAndNewlines)
            : defaultTitle(for: analysis.labDate)

        let report = LabReport(
            title: reportTitle,
            rawText: analysis.rawText,
            labDate: analysis.labDate,
            summaryInsight: analysis.insights,
            analysisProvider: analysis.providerName,
            parent: parent
        )
        context.insert(report)

        for item in analysis.results {
            let result = LabResult(
                testKey: item.testKey.rawValue,
                testName: item.testName,
                value: item.value,
                unit: item.unit,
                referenceRange: item.referenceRange,
                isAbnormal: item.isAbnormal,
                labReport: report
            )
            context.insert(result)
        }

        return report
    }

    static func defaultTitle(for labDate: Date?) -> String {
        if let labDate {
            return "Lab Report · \(labDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Lab Report · \(Date().formatted(date: .abbreviated, time: .omitted))"
    }
}
