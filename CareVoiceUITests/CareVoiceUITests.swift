import XCTest

final class CareVoiceUITests: XCTestCase {
    func testOnboardingRecordingPersistenceAndReport() throws {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.buttons["getStarted"].waitForExistence(timeout: 10))
        snapshot(app, "01-Welcome")
        app.buttons["getStarted"].tap()
        let nickname = app.textFields["nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5)); nickname.tap(); nickname.typeText("Alex")
        app.buttons["saveProfile"].tap()
        XCTAssertTrue(app.buttons["captureMoment"].waitForExistence(timeout: 5))
        snapshot(app, "02-Home")
        app.buttons["captureMoment"].tap()
        let text = app.textFields["recordText"]
        XCTAssertTrue(text.waitForExistence(timeout: 5)); text.tap(); text.typeText("Waved hello at the park today.")
        app.buttons["saveRecord"].tap()
        app.tabBars.buttons["Records"].tap()
        XCTAssertTrue(app.staticTexts["Waved hello at the park today."].waitForExistence(timeout: 5))
        snapshot(app, "03-Records")
        app.terminate(); app.launchArguments = ["--ui-testing", "--preserve-ui-data"]; app.launch()
        XCTAssertTrue(app.buttons["captureMoment"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Records"].tap()
        XCTAssertTrue(app.staticTexts["Waved hello at the park today."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Reports"].tap()
        XCTAssertTrue(app.buttons["shareReport"].waitForExistence(timeout: 5))
        snapshot(app, "04-Report")
        app.buttons["shareReport"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.buttons["Copy"].exists || app.buttons["Close"].exists)
    }
    func testQuestionnaireAndTraditionalChinese() throws {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        app.buttons["getStarted"].tap(); app.buttons["saveProfile"].tap()
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Observation questionnaire"].tap()
        XCTAssertTrue(app.buttons["answer-often"].waitForExistence(timeout: 5))
        app.buttons["answer-often"].tap(); app.swipeUp()
        app.buttons["nextQuestion"].tap()
        XCTAssertTrue(app.staticTexts["Question 2 of 30"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Question 2 of 30"].isHittable)
        snapshot(app, "05-Questionnaire")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["languagePicker"].tap()
        app.buttons["繁體中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["首頁"].waitForExistence(timeout: 5))
        app.tabBars.buttons["首頁"].tap()
        snapshot(app, "06-TraditionalChinese")
    }
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
