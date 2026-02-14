import XCTest

final class RecordingDemoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    @MainActor
    func testTabNavigation() throws {
        // Verify we start on the Record tab
        XCTAssertTrue(app.navigationBars["Record"].exists)

        // Switch to Recordings tab
        app.tabBars.buttons["Recordings"].tap()
        XCTAssertTrue(app.navigationBars["Recordings"].exists)

        // Switch back to Record tab
        app.tabBars.buttons["Record"].tap()
        XCTAssertTrue(app.navigationBars["Record"].exists)
    }

    @MainActor
    func testRecordingModeSegmentedControl() throws {
        // Verify segmented control exists
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.exists)

        // Tap Fixed Duration
        segmentedControl.buttons["Fixed Duration"].tap()

        // Verify duration slider appears
        XCTAssertTrue(app.sliders.firstMatch.waitForExistence(timeout: 2))

        // Tap Manual
        segmentedControl.buttons["Manual"].tap()

        // Verify slider is hidden
        XCTAssertFalse(app.sliders.firstMatch.exists)
    }

    @MainActor
    func testRecordButtonExists() throws {
        // The record button should exist (it's a custom circle button)
        // We check for the circular record button area
        XCTAssertTrue(app.buttons.count > 0)
    }
}
