import XCTest
@testable import ParentsHealth

final class ReportExportServiceTests: XCTestCase {
    @MainActor
    func testGenerateTextReportIncludesParentName() {
        let parent = ParentProfile(name: "Test Parent", bloodType: "A+")
        let report = ReportExportService.generateTextReport(parent: parent)
        XCTAssertTrue(report.contains("Test Parent"))
        XCTAssertTrue(report.contains("ParentsHealth Report"))
        XCTAssertTrue(report.localizedCaseInsensitiveContains("not medical advice"))
    }

    @MainActor
    func testGenerateTextReportIncludesAlertsSection() {
        let parent = ParentProfile(name: "Jane Doe")
        parent.metrics = [
            HealthMetric(type: .bloodGlucose, value: 220, recordedAt: Date(), parent: parent)
        ]
        let report = ReportExportService.generateTextReport(parent: parent)
        XCTAssertTrue(report.contains("Active Health Alerts"))
    }
}
