import XCTest
@testable import ParentsHealth

final class MetricTypeTests: XCTestCase {
    func testBloodPressureNormalRange() {
        XCTAssertTrue(MetricType.bloodPressure.isNormal(value: 120, secondaryValue: 80))
        XCTAssertFalse(MetricType.bloodPressure.isNormal(value: 160, secondaryValue: 80))
        XCTAssertFalse(MetricType.bloodPressure.isNormal(value: 120, secondaryValue: 100))
    }

    func testHeartRateNormalRange() {
        XCTAssertTrue(MetricType.heartRate.isNormal(value: 72))
        XCTAssertFalse(MetricType.heartRate.isNormal(value: 120))
        XCTAssertFalse(MetricType.heartRate.isNormal(value: 50))
    }

    func testBloodGlucoseNormalRange() {
        XCTAssertTrue(MetricType.bloodGlucose.isNormal(value: 100))
        XCTAssertFalse(MetricType.bloodGlucose.isNormal(value: 200))
    }

    func testAllCasesHaveTitlesAndUnits() {
        for type in MetricType.allCases {
            XCTAssertFalse(type.title.isEmpty)
            XCTAssertFalse(type.unit.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
}
