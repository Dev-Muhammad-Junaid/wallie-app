import XCTest

final class ParentsHealthUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsHomeTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        XCTAssertTrue(app.staticTexts["ParentsHealth"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Home"].exists)
        XCTAssertTrue(app.staticTexts["Parents"].exists)
        XCTAssertTrue(app.staticTexts["Charts"].exists)
        XCTAssertTrue(app.staticTexts["Labs"].exists)
        XCTAssertTrue(app.staticTexts["Meds"].exists)
    }

    func testNavigateToParentsTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        app.staticTexts["Parents"].tap()
        XCTAssertTrue(app.navigationBars["Parents"].waitForExistence(timeout: 3))
    }

    func testNavigateToChartsTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        app.staticTexts["Charts"].tap()
        XCTAssertTrue(app.navigationBars["Charts"].waitForExistence(timeout: 3))
    }

    func testNavigateToLabsTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        app.staticTexts["Labs"].tap()
        XCTAssertTrue(app.navigationBars["Lab Reports"].waitForExistence(timeout: 3))
    }

    func testOpenSettingsFromDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let settingsButton = app.buttons["settingsButton"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        }
    }

    func testOpenHealthAlertsFromDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        XCTAssertTrue(app.staticTexts["ParentsHealth"].waitForExistence(timeout: 5))
        let alertsButton = app.buttons["alertsHeaderButton"]
        if alertsButton.waitForExistence(timeout: 3) {
            alertsButton.tap()
            XCTAssertTrue(app.staticTexts["Health Alerts"].waitForExistence(timeout: 3))
        }
    }

    func testChartsLabTrendsSegmentExists() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        app.staticTexts["Charts"].tap()
        XCTAssertTrue(app.navigationBars["Charts"].waitForExistence(timeout: 3))
        app.staticTexts["Lab Trends"].tap()
        XCTAssertTrue(app.staticTexts["Lab Trends"].exists)
    }
}
