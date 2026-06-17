import XCTest
@testable import ParentsHealth

final class HealthScoreCalculatorTests: XCTestCase {
    func testDefaultScoreWhenNoMetrics() {
        let score = HealthScoreCalculator.score(from: [])
        XCTAssertEqual(score, 75)
    }

    func testPerfectScoreWhenAllNormal() {
        let now = Date()
        let metrics = [
            HealthMetricSnapshot(type: .heartRate, value: 72, recordedAt: now),
            HealthMetricSnapshot(type: .bloodGlucose, value: 100, recordedAt: now),
            HealthMetricSnapshot(type: .bloodPressure, value: 120, secondaryValue: 80, recordedAt: now)
        ]
        XCTAssertEqual(HealthScoreCalculator.score(from: metrics, referenceDate: now), 100)
    }

    func testLowerScoreWhenAbnormal() {
        let now = Date()
        let metrics = [
            HealthMetricSnapshot(type: .heartRate, value: 120, recordedAt: now),
            HealthMetricSnapshot(type: .bloodGlucose, value: 200, recordedAt: now)
        ]
        let score = HealthScoreCalculator.score(from: metrics, referenceDate: now)
        XCTAssertEqual(score, 60)
    }

    func testIgnoresMetricsOutsideWindow() {
        let now = Date()
        let old = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let metrics = [
            HealthMetricSnapshot(type: .heartRate, value: 200, recordedAt: old),
            HealthMetricSnapshot(type: .bloodGlucose, value: 100, recordedAt: now)
        ]
        XCTAssertEqual(HealthScoreCalculator.score(from: metrics, referenceDate: now), 100)
    }
}
