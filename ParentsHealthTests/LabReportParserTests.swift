import XCTest
@testable import ParentsHealth

final class LabReportParserTests: XCTestCase {
    func testParsesGlucoseAndHbA1c() {
        let text = """
        Patient Lab Results
        Glucose: 142 mg/dL
        HbA1c: 6.8 %
        """
        let results = LabReportParser.parse(text: text)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.testName.lowercased().contains("glucose") })
        XCTAssertTrue(results.contains { $0.testName.lowercased().contains("a1c") || $0.testName.lowercased().contains("hba1c") })
    }

    func testFlagsAbnormalGlucose() {
        let text = "Glucose: 180 mg/dL"
        let results = LabReportParser.parse(text: text)
        let glucose = results.first { $0.testName.lowercased().contains("glucose") }
        XCTAssertEqual(glucose?.isAbnormal, true)
    }

    func testParsesLipidPanel() {
        let text = """
        Cholesterol: 215 mg/dL
        LDL: 130 mg/dL
        HDL: 45 mg/dL
        Triglycerides: 160 mg/dL
        """
        let results = LabReportParser.parse(text: text)
        XCTAssertGreaterThanOrEqual(results.count, 3)
    }

    func testGenerateInsightsMentionsAbnormal() {
        let results = [
            ParsedLabResult(testName: "Glucose", value: 180, unit: "mg/dL", referenceRange: "70–100 mg/dL", isAbnormal: true)
        ]
        let insight = LabReportParser.generateInsights(results: results, parentName: "Margaret")
        XCTAssertTrue(insight.contains("Margaret"))
        XCTAssertTrue(insight.contains("outside normal range") || insight.contains("1 of 1"))
    }

    func testExtractLabDateUSFormat() {
        let text = "Report Date: 03/15/2026\nGlucose: 95"
        let date = LabReportParser.extractLabDate(from: text)
        XCTAssertNotNil(date)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    func testEmptyTextReturnsNoResults() {
        XCTAssertTrue(LabReportParser.parse(text: "").isEmpty)
    }
}
