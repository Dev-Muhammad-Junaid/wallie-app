import XCTest
import SwiftData
@testable import ParentsHealth

final class SiriCareActionsTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Persistence.schema
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: configuration)
        context = ModelContext(container)
    }

    func testLogDoseWhenDue() throws {
        let parent = ParentProfile(name: "Margaret Chen")
        context.insert(parent)
        let medication = Medication(
            name: "Lisinopril",
            dosage: "10 mg",
            frequency: MedicationFrequency.daily.rawValue,
            reminderHours: [8],
            parent: parent
        )
        context.insert(medication)

        let outcome = SiriCareActions.logDose(
            medication: medication,
            status: .taken,
            hour: 8,
            context: context
        )
        try context.save()

        guard case let .logged(name, parentName, status, hour) = outcome else {
            return XCTFail("Expected logged dose, got \(outcome)")
        }
        XCTAssertEqual(name, "Lisinopril")
        XCTAssertEqual(parentName, "Margaret Chen")
        XCTAssertEqual(status, .taken)
        XCTAssertEqual(hour, 8)
        XCTAssertEqual(medication.todayLog(forHour: 8)?.status, .taken)
    }

    func testLogDoseRejectedWhenNotDue() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let monday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let parent = ParentProfile(name: "Robert Chen")
        context.insert(parent)
        let medication = Medication(
            name: "Weekly vitamin",
            dosage: "1 tab",
            frequency: MedicationFrequency.weekly.rawValue,
            reminderHours: [8],
            scheduleWeekday: 1,
            parent: parent
        )
        context.insert(medication)

        XCTAssertFalse(
            MedicationSchedule.isDue(
                frequency: .weekly,
                on: monday,
                weekday: 1,
                dayOfMonth: 1,
                calendar: calendar
            )
        )
    }

    func testPendingSummaryEmpty() {
        let parent = ParentProfile(name: "Margaret Chen")
        context.insert(parent)
        let summary = SiriCareActions.pendingSummary(from: [parent])
        XCTAssertTrue(summary.contains("No medication doses"))
    }

    func testPendingDosesListsUntakenSlots() throws {
        let parent = ParentProfile(name: "Margaret Chen")
        context.insert(parent)
        let medication = Medication(
            name: "Metformin",
            dosage: "500 mg",
            frequency: MedicationFrequency.daily.rawValue,
            reminderHours: [8, 20],
            parent: parent
        )
        context.insert(medication)

        let pending = SiriCareActions.pendingDoses(from: [parent])
        XCTAssertEqual(pending.map(\.hour), [8, 20])

        _ = SiriCareActions.logDose(medication: medication, status: .taken, hour: 8, context: context)
        try context.save()

        let remaining = SiriCareActions.pendingDoses(from: [parent])
        XCTAssertEqual(remaining.map(\.hour), [20])
    }

    func testNextAppointmentPicksSoonestFuture() {
        let parent = ParentProfile(name: "Margaret Chen")
        context.insert(parent)
        let later = Appointment(
            title: "Cardiology",
            scheduledAt: Date().addingTimeInterval(86_400 * 10),
            parent: parent
        )
        let sooner = Appointment(
            title: "Lab draw",
            scheduledAt: Date().addingTimeInterval(86_400 * 2),
            parent: parent
        )
        context.insert(later)
        context.insert(sooner)

        let next = SiriCareActions.nextAppointment(from: [parent])
        XCTAssertEqual(next?.title, "Lab draw")
        XCTAssertTrue(SiriCareActions.appointmentSummaryText(next).contains("Lab draw"))
    }

    func testBloodPressureValidation() {
        let parent = ParentProfile(name: "Robert Chen")
        context.insert(parent)

        let invalid = SiriCareActions.logBloodPressure(
            parent: parent,
            systolic: 80,
            diastolic: 120,
            context: context
        )
        guard case .invalid = invalid else {
            return XCTFail("Expected invalid BP")
        }

        let saved = SiriCareActions.logBloodPressure(
            parent: parent,
            systolic: 128,
            diastolic: 82,
            context: context
        )
        guard case let .saved(display, name, inRange) = saved else {
            return XCTFail("Expected saved BP, got \(saved)")
        }
        XCTAssertEqual(display, "128/82")
        XCTAssertEqual(name, "Robert Chen")
        XCTAssertTrue(inRange)
    }

    func testDeepLinkParsing() {
        let id = UUID()
        XCTAssertEqual(AppDeepLink.parse(AppDeepLink.url(for: .parent(id))), .parent(id))
        XCTAssertEqual(AppDeepLink.parse(AppDeepLink.url(for: .medications(parentID: id))), .medications(parentID: id))
        XCTAssertEqual(AppDeepLink.parse(URL(string: "parentshealth://meds")!), .medications(parentID: nil))
        XCTAssertEqual(AppDeepLink.parse(AppDeepLink.url(for: .labs)), .labs)
        XCTAssertEqual(AppDeepLink.parse(AppDeepLink.url(for: .care)), .care)
        XCTAssertNil(AppDeepLink.parse(URL(string: "https://example.com")!))
    }

    func testSpotlightIdentifierRoundTrip() {
        let id = UUID()
        let identifier = AppDeepLink.spotlightIdentifier(kind: .parent, id: id)
        XCTAssertEqual(AppDeepLink.destination(fromSpotlightIdentifier: identifier), .parent(id))
        XCTAssertEqual(
            AppDeepLink.destination(fromSpotlightIdentifier: AppDeepLink.spotlightIdentifier(kind: .appointment, id: id)),
            .appointment(id)
        )
    }
}
