import XCTest
@testable import ParentsHealth

final class HealthAlertServiceTests: XCTestCase {
    func testLabAlertsForParentWithRisingGlucose() {
        let parent = SampleData.previewParent
        let report = makeLabReport(parent: parent, glucose: 142, hba1c: 6.2, date: Date())
        parent.labReports = [report]

        let alerts = HealthAlertService.alerts(for: parent)
        XCTAssertFalse(alerts.isEmpty)
        XCTAssertTrue(alerts.contains { $0.labTestKey == .glucose })
        XCTAssertEqual(alerts.first { $0.labTestKey == .glucose }?.boundary, .aboveRange)
    }

    func testVitalAlertForHighBloodPressure() {
        let parent = ParentProfile(name: "Test Parent")
        let metric = HealthMetric(
            type: .bloodPressure,
            value: 165,
            secondaryValue: 95,
            recordedAt: Date(),
            parent: parent
        )
        parent.metrics = [metric]

        let alerts = HealthAlertService.alerts(for: parent)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts[0].source, .vital)
        XCTAssertEqual(alerts[0].severity, .attention)
        XCTAssertFalse(alerts[0].healthImpact.isEmpty)
    }

    func testNoAlertsWhenAllNormal() {
        let parent = ParentProfile(name: "Healthy Parent")
        let metric = HealthMetric(
            type: .heartRate,
            value: 72,
            recordedAt: Date(),
            parent: parent
        )
        parent.metrics = [metric]

        XCTAssertTrue(HealthAlertService.alerts(for: parent).isEmpty)
    }

    func testLabTrendWorseningForGlucose() {
        let parent = SampleData.previewParent
        parent.labReports = [
            makeLabReport(parent: parent, glucose: 118, hba1c: 5.4, date: Date().addingTimeInterval(-60 * 60 * 24 * 90)),
            makeLabReport(parent: parent, glucose: 142, hba1c: 6.2, date: Date())
        ]

        let glucoseAlert = HealthAlertService.alerts(for: parent).first { $0.labTestKey == .glucose }
        XCTAssertEqual(glucoseAlert?.trend, .worsening)
    }

    func testAlertIfNeededReturnsNilForNormalVital() {
        let parent = ParentProfile(name: "Test")
        let metric = HealthMetric(type: .heartRate, value: 70, parent: parent)
        XCTAssertNil(HealthAlertService.alertIfNeeded(for: metric, parent: parent))
    }

    func testSummaryText() {
        let parent = ParentProfile(name: "Test")
        parent.metrics = [
            HealthMetric(type: .bloodGlucose, value: 220, recordedAt: Date(), parent: parent)
        ]
        let summary = HealthAlertService.summary(for: [parent])
        XCTAssertTrue(summary.contains("out-of-range"))
    }

    func testWeightChangeAlert() {
        let parent = ParentProfile(name: "Test")
        let prior = HealthMetric(type: .weight, value: 70, recordedAt: Date().addingTimeInterval(-86400 * 3), parent: parent)
        let current = HealthMetric(type: .weight, value: 77, recordedAt: Date(), parent: parent)
        parent.metrics = [prior, current]

        let alert = HealthAlertService.alertIfNeeded(for: current, parent: parent)
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.title, "Weight Change")
    }

    private func makeLabReport(
        parent: ParentProfile,
        glucose: Double,
        hba1c: Double,
        date: Date
    ) -> LabReport {
        let report = LabReport(
            title: "Lab",
            rawText: "sample",
            importedAt: date,
            labDate: date,
            parent: parent
        )
        report.results = [
            LabResult(
                testKey: LabTestKey.glucose.rawValue,
                testName: "Glucose",
                value: glucose,
                unit: "mg/dL",
                referenceRange: "70–100 mg/dL",
                isAbnormal: glucose > 100,
                labReport: report
            ),
            LabResult(
                testKey: LabTestKey.hba1c.rawValue,
                testName: "HbA1c",
                value: hba1c,
                unit: "%",
                referenceRange: "4.0–5.7 %",
                isAbnormal: hba1c > 5.7,
                labReport: report
            )
        ]
        return report
    }
}
