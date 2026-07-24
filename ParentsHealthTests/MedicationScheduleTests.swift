import XCTest
@testable import ParentsHealth

final class MedicationScheduleTests: XCTestCase {
    func testDailyIsAlwaysDue() {
        let date = Date()
        XCTAssertTrue(
            MedicationSchedule.isDue(frequency: .daily, on: date, weekday: 1, dayOfMonth: 1)
        )
    }

    func testWeeklyMatchesWeekday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let monday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))! // Monday
        XCTAssertEqual(calendar.component(.weekday, from: monday), 2)
        XCTAssertTrue(
            MedicationSchedule.isDue(
                frequency: .weekly,
                on: monday,
                weekday: 2,
                dayOfMonth: 1,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            MedicationSchedule.isDue(
                frequency: .weekly,
                on: monday,
                weekday: 3,
                dayOfMonth: 1,
                calendar: calendar
            )
        )
    }

    func testMonthlyMatchesDayOfMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let first = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        XCTAssertTrue(
            MedicationSchedule.isDue(
                frequency: .monthly,
                on: first,
                weekday: 1,
                dayOfMonth: 1,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            MedicationSchedule.isDue(
                frequency: .monthly,
                on: first,
                weekday: 1,
                dayOfMonth: 15,
                calendar: calendar
            )
        )
    }

    func testAsNeededNeverAutoDue() {
        XCTAssertFalse(
            MedicationSchedule.isDue(frequency: .asNeeded, on: Date(), weekday: 1, dayOfMonth: 1)
        )
    }

    func testDueDayCountForWeekly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        // Sunday Jul 26 2026 — look back 7 days should include one Monday (Jul 20)
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 26))!
        let count = MedicationSchedule.dueDayCount(
            frequency: .weekly,
            weekday: 2,
            dayOfMonth: 1,
            periodDays: 7,
            referenceDate: sunday,
            calendar: calendar
        )
        XCTAssertEqual(count, 1)
    }
}
