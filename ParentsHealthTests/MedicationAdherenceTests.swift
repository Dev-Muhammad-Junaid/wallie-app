import XCTest
@testable import ParentsHealth

final class MedicationAdherenceTests: XCTestCase {
    func testFullAdherence() {
        let result = MedicationAdherenceCalculator.adherence(reminderHoursPerDay: 2, takenCount: 14)
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testPartialAdherence() {
        let result = MedicationAdherenceCalculator.adherence(reminderHoursPerDay: 2, takenCount: 7)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func testZeroRemindersReturnsFullAdherence() {
        let result = MedicationAdherenceCalculator.adherence(reminderHoursPerDay: 0, takenCount: 0)
        XCTAssertEqual(result, 1.0)
    }

    func testCapsAtOne() {
        let result = MedicationAdherenceCalculator.adherence(reminderHoursPerDay: 1, takenCount: 20)
        XCTAssertEqual(result, 1.0)
    }

    func testWeeklyDueDaysAdherence() {
        // 2 reminder slots × 1 due day in the week = 2 expected
        let result = MedicationAdherenceCalculator.adherence(
            reminderHoursPerDay: 2,
            takenCount: 2,
            dueDaysInPeriod: 1,
            frequency: .weekly
        )
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testMonthlyPartialAdherence() {
        let result = MedicationAdherenceCalculator.adherence(
            reminderHoursPerDay: 1,
            takenCount: 0,
            dueDaysInPeriod: 1,
            frequency: .monthly
        )
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }
}
