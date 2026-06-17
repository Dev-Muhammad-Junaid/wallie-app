import Foundation
import SwiftData

@Model
final class LabReport {
    var id: UUID
    var title: String
    var rawText: String
    var importedAt: Date
    var labDate: Date?
    var summaryInsight: String
    var analysisProvider: String

    var parent: ParentProfile?

    @Relationship(deleteRule: .cascade, inverse: \LabResult.labReport)
    var results: [LabResult]

    init(
        title: String,
        rawText: String,
        importedAt: Date = Date(),
        labDate: Date? = nil,
        summaryInsight: String = "",
        analysisProvider: String = "On-Device",
        parent: ParentProfile? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.rawText = rawText
        self.importedAt = importedAt
        self.labDate = labDate
        self.summaryInsight = summaryInsight
        self.analysisProvider = analysisProvider
        self.parent = parent
        self.results = []
    }

    /// Date used for trend charts — prefers lab collection date over import date.
    var effectiveDate: Date {
        labDate ?? importedAt
    }

    var abnormalCount: Int {
        results.filter(\.isAbnormal).count
    }

    var abnormalResults: [LabResult] {
        results.filter(\.isAbnormal)
    }
}

@Model
final class LabResult {
    var id: UUID
    var testKey: String
    var testName: String
    var value: Double
    var unit: String
    var referenceRange: String
    var isAbnormal: Bool

    var labReport: LabReport?

    init(
        testKey: String,
        testName: String,
        value: Double,
        unit: String,
        referenceRange: String,
        isAbnormal: Bool,
        labReport: LabReport? = nil
    ) {
        self.id = UUID()
        self.testKey = testKey
        self.testName = testName
        self.value = value
        self.unit = unit
        self.referenceRange = referenceRange
        self.isAbnormal = isAbnormal
        self.labReport = labReport
    }

    var key: LabTestKey? {
        LabTestKey(rawValue: testKey)
    }

    var displayValue: String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
