import XCTest
@testable import ParentsHealth

final class ReportExportServiceTests: XCTestCase {
    @MainActor
    func testGenerateTextReportIncludesParentName() {
        let parent = ParentProfile(name: "Test Parent", bloodType: "A+")
        let report = ReportExportService.generateTextReport(parent: parent)
        XCTAssertTrue(report.contains("Test Parent"))
        XCTAssertTrue(report.contains("ParentsHealth Report"))
        XCTAssertTrue(report.contains("not medical advice"))
    }

    @MainActor
    func testGenerateTextReportIncludesHealthScore() {
        let parent = ParentProfile(name: "Jane Doe")
        let report = ReportExportService.generateTextReport(parent: parent)
        XCTAssertTrue(report.contains("Health Score"))
        XCTAssertTrue(report.contains("Jane Doe"))
    }
}
