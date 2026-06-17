import XCTest
@testable import ParentsHealth

final class LabTrendServiceTests: XCTestCase {
    @MainActor
    func testTrendPointsSortedByDate() {
        let parent = ParentProfile(name: "Test")
        let older = makeReport(parent: parent, date: Date(timeIntervalSince1970: 1_000_000), glucose: 110)
        let newer = makeReport(parent: parent, date: Date(timeIntervalSince1970: 2_000_000), glucose: 125)
        parent.labReports = [newer, older]

        let points = LabTrendService.trendPoints(for: parent, testKey: .glucose)
        XCTAssertEqual(points.count, 2)
        XCTAssertLessThan(points[0].date, points[1].date)
        XCTAssertEqual(points[1].value, 125)
    }

    @MainActor
    func testAvailableTestKeys() {
        let parent = ParentProfile(name: "Test")
        parent.labReports = [makeReport(parent: parent, date: Date(), glucose: 100, hba1c: 5.9)]
        let keys = LabTrendService.availableTestKeys(for: parent)
        XCTAssertTrue(keys.contains(.glucose))
        XCTAssertTrue(keys.contains(.hba1c))
    }

    @MainActor
    func testDeltaCalculation() {
        let previous = LabTrendPoint(
            id: UUID(),
            date: Date(),
            value: 110,
            reportID: UUID(),
            reportTitle: "A",
            isAbnormal: false
        )
        let current = LabTrendPoint(
            id: UUID(),
            date: Date(),
            value: 125,
            reportID: UUID(),
            reportTitle: "B",
            isAbnormal: true
        )
        XCTAssertEqual(LabTrendService.delta(from: previous, to: current), 15)
    }

    @MainActor
    private func makeReport(parent: ParentProfile, date: Date, glucose: Double? = nil, hba1c: Double? = nil) -> LabReport {
        let report = LabReport(title: "Test", rawText: "", labDate: date, parent: parent)
        if let glucose {
            report.results.append(LabResult(
                testKey: LabTestKey.glucose.rawValue,
                testName: "Glucose",
                value: glucose,
                unit: "mg/dL",
                referenceRange: "70–100",
                isAbnormal: glucose > 100,
                labReport: report
            ))
        }
        if let hba1c {
            report.results.append(LabResult(
                testKey: LabTestKey.hba1c.rawValue,
                testName: "HbA1c",
                value: hba1c,
                unit: "%",
                referenceRange: "4–5.7",
                isAbnormal: hba1c > 5.7,
                labReport: report
            ))
        }
        return report
    }
}
