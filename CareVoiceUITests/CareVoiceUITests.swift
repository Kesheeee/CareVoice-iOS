import XCTest

final class CareVoiceUITests: XCTestCase {
    private func launch(_ arguments: [String] = ["--seed-profile"]) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"] + arguments; app.launch(); return app
    }
    func testSurveyBirthdayAndAllSevenChoices() {
        let app = launch([])
        XCTAssertTrue(app.buttons["surveyContinue"].waitForExistence(timeout: 10)); app.buttons["surveyContinue"].tap()
        for (part, value) in [("Day", "15"), ("Month", "6"), ("Year", String(Calendar.current.component(.year, from: Date()) - 3))] {
            app.buttons["birthday-" + part].tap()
            app.buttons[value].tap()
        }
        XCTAssertTrue(app.buttons["surveyContinue"].isEnabled); app.buttons["surveyContinue"].tap()
        for stage in ["noticed", "professionalFollowUp", "awaitingAssessment", "assessed", "registered", "waitingSupport", "receivingServices"] {
            XCTAssertTrue(app.buttons["survey-" + stage].isHittable, stage)
        }
        XCTAssertTrue(app.buttons["surveyContinue"].isHittable)
        snapshot(app, "Survey-Seven-Stages")
        app.buttons["survey-waitingSupport"].tap(); app.buttons["surveyContinue"].tap()
        XCTAssertTrue(app.buttons["survey-nextSteps"].waitForExistence(timeout: 5))
        snapshot(app, "Survey-Support-Goals")
        app.buttons["survey-nextSteps"].tap(); app.buttons["surveyContinue"].tap(); app.buttons["surveyContinue"].tap()
        XCTAssertTrue(app.buttons["captureMoment"].waitForExistence(timeout: 5))
    }
    func testSettingsNavigationAndPreferences() {
        let app = launch()
        XCTAssertTrue(app.buttons["tab-3"].waitForExistence(timeout: 10)); app.buttons["tab-3"].tap()
        XCTAssertTrue(app.buttons["languagePicker"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Your child"].exists)
        app.buttons["settings-preferences"].tap()
        XCTAssertTrue(app.textFields["nickname"].waitForExistence(timeout: 5))
        app.buttons["saveProfile"].tap()
        app.buttons["openReports"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["sharePDF"].waitForExistence(timeout: 5))
        snapshot(app, "Settings-Report")
    }
    func testLanguageSelectionAndPersistence() {
        let app = launch(); app.buttons["tab-3"].tap()
        for language in ["traditionalChinese", "english", "simplifiedChinese"] {
            app.buttons["languagePicker"].tap()
            let option = app.buttons["language-" + language]
            XCTAssertTrue(option.waitForExistence(timeout: 5)); option.tap()
            app.buttons["saveLanguage"].tap()
        }
        snapshot(app, "Settings-SimplifiedChinese")
        app.terminate(); app.launchArguments = ["--ui-testing", "--preserve-ui-data"]; app.launch()
        app.buttons["tab-3"].tap()
        XCTAssertTrue(app.staticTexts["简体中文"].waitForExistence(timeout: 5))
    }
    func testParentsCommunitySetupAndAccountNavigation() {
        let app = launch(); app.buttons["tab-2"].tap()
        XCTAssertTrue(app.staticTexts["Official resources & support"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Child Assessment Service (CAS)")).firstMatch.exists)
        snapshot(app, "Community-Resources")
        app.buttons["openParentCommunity"].tap()
        XCTAssertTrue(app.staticTexts["Community setup is pending"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Send sign-in code"].exists)
    }
    func testCommunityReusesSignedInAccountForNicknameSetup() {
        let app = launch(["--seed-profile", "--community-member-preview"])
        app.buttons["tab-2"].tap(); app.buttons["openParentCommunity"].tap()
        let nickname = app.textFields["communityNickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["authEmail"].exists)
        XCTAssertFalse(app.buttons["Send sign-in code"].exists)
        let join = app.buttons["saveCommunityProfile"]
        XCTAssertFalse(join.isEnabled)
        nickname.tap(); nickname.typeText("Parent\n")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertFalse(join.isEnabled)
        app.swipeUp()
        let agreement = app.switches["acceptCommunityGuidelines"]
        XCTAssertTrue(agreement.waitForExistence(timeout: 5)); agreement.tap()
        XCTAssertTrue(join.isEnabled)
        snapshot(app, "Community-Shared-Account")
    }
    func testReturningCommunityMemberOpensFeedWithoutLogin() {
        let app = launch(["--seed-profile", "--community-member-preview", "--community-existing-profile"])
        app.buttons["tab-2"].tap(); app.buttons["openParentCommunity"].tap()
        XCTAssertTrue(app.buttons["Create a post"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["communityNickname"].exists)
        XCTAssertFalse(app.textFields["authEmail"].exists)
        XCTAssertFalse(app.buttons["Send sign-in code"].exists)
        snapshot(app, "Community-Returning-Member")
    }
    func testQuickRecordTabsSaveAndPersistence() {
        let app = launch(); app.buttons["tab-1"].tap(); app.buttons["addRecord"].tap()
        XCTAssertTrue(app.buttons["Start recording"].waitForExistence(timeout: 5))
        app.buttons["Text record"].tap()
        let text = app.textViews["recordText"].waitForExistence(timeout: 5) ? app.textViews["recordText"] : app.textFields["recordText"]
        XCTAssertTrue(text.waitForExistence(timeout: 5)); text.tap(); text.typeText("Waved hello at the park.")
        app.buttons["saveRecord"].tap()
        XCTAssertTrue(app.staticTexts["Waved hello at the park."].waitForExistence(timeout: 5))
        app.terminate(); app.launchArguments = ["--ui-testing", "--preserve-ui-data"]; app.launch()
        app.buttons["tab-1"].tap()
        XCTAssertTrue(app.staticTexts["Waved hello at the park."].waitForExistence(timeout: 5))
        snapshot(app, "Records-Saved")
    }
    func testRevisedQuestionnaireAndSummaryNavigation() {
        let app = launch(); app.buttons["openQuestionnaire"].tap()
        XCTAssertTrue(app.staticTexts["Question 1 of 33"].waitForExistence(timeout: 5))
        app.buttons["answer-often"].tap(); app.swipeUp(); app.buttons["nextQuestion"].tap()
        XCTAssertTrue(app.staticTexts["Question 2 of 33"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Review"].tap()
        app.swipeUp()
        app.buttons.containing(.staticText, identifier: "Does your child respond when they hear their name?").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Question 1 of 33"].waitForExistence(timeout: 5))
    }
    func testSignupRejectsWeakPasswordsWithoutNetwork() {
        let app = launch(["--auth-preview"])
        app.buttons["getStarted"].tap(); app.buttons["Continue with email"].tap()
        let email = app.textFields["authEmail"]; XCTAssertTrue(email.waitForExistence(timeout: 5)); email.tap(); email.typeText("preview@example.com")
        app.buttons["authSubmit"].tap()
        let password = app.secureTextFields["authPassword"]; password.tap(); password.typeText("weak")
        app.swipeUp(); app.buttons["authSubmit"].tap()
        XCTAssertTrue(app.staticTexts["authError"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["authError"].label.contains("8 characters"))
        snapshot(app, "Account-Password-Validation")
    }
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
