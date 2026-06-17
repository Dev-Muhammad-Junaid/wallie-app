import Foundation

struct LabTrendPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
    let reportID: UUID
    let reportTitle: String
    let isAbnormal: Bool

    init(result: LabResult, report: LabReport) {
        self.id = result.id
        self.date = report.effectiveDate
        self.value = result.value
        self.reportID = report.id
        self.reportTitle = report.title
        self.isAbnormal = result.isAbnormal
    }
}

enum LabTrendService {
    /// All trend points for a given test key, sorted oldest → newest.
    static func trendPoints(for parent: ParentProfile, testKey: LabTestKey) -> [LabTrendPoint] {
        parent.labReports
            .sorted { $0.effectiveDate < $1.effectiveDate }
            .flatMap { report in
                report.results
                    .filter { $0.testKey == testKey.rawValue }
                    .map { LabTrendPoint(result: $0, report: report) }
            }
    }

    /// Test keys that have at least one saved result for this parent.
    static func availableTestKeys(for parent: ParentProfile) -> [LabTestKey] {
        let keys = Set(parent.labReports.flatMap { $0.results.map(\.testKey) })
        return LabTestKey.allCases.filter { keys.contains($0.rawValue) }
    }

    static func latestValue(for parent: ParentProfile, testKey: LabTestKey) -> LabTrendPoint? {
        trendPoints(for: parent, testKey: testKey).last
    }

    static func delta(from previous: LabTrendPoint?, to current: LabTrendPoint) -> Double? {
        guard let previous else { return nil }
        return current.value - previous.value
    }

    static func summaryStats(for points: [LabTrendPoint]) -> (min: Double, max: Double, avg: Double)? {
        guard !points.isEmpty else { return nil }
        let values = points.map(\.value)
        let sum = values.reduce(0, +)
        return (values.min()!, values.max()!, sum / Double(values.count))
    }
}
