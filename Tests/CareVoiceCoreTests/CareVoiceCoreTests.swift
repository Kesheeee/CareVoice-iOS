import XCTest
@testable import CareVoiceCore

final class CareVoiceCoreTests: XCTestCase {
    func testCaregiverNameRemainsCompatibleWithExistingData() throws {
        var data = AppData()
        data.profile = ChildProfile(nickname: "Sam")
        data.caregiverName = "Alex"
        let encoded = try JSONEncoder().encode(data)
        XCTAssertEqual(try JSONDecoder().decode(AppData.self, from: encoded), data)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "caregiverName")
        let restored = try JSONDecoder().decode(AppData.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(restored.caregiverName)
        XCTAssertEqual(restored.profile, data.profile)
    }
    func testPersistenceRoundTrip() throws {
        var data = AppData(); data.profile = ChildProfile(nickname: "阿明"); data.language = .traditionalChinese
        data.records = [BehaviorRecord(text: "主動打招呼", category: .progress)]
        data.answers = [1: .often, 2: .skipped, 29: .unsure]
        data.completedSteps = ["noticed-0"]
        XCTAssertEqual(try JSONDecoder().decode(AppData.self, from: JSONEncoder().encode(data)), data)
    }
    func testSkipDoesNotCountAsAnswer() {
        var data = AppData(); data.answers = [1: .often, 2: .skipped, 3: .unsure]
        XCTAssertEqual(data.answeredCount, 2); XCTAssertEqual(data.reviewedCount, 3)
    }
    func testRegressionFollowUpDoesNotRequireQuestionnaireCompletion() {
        for answer in [Answer.yes, .unsure] {
            for id in [29, 30] {
                var data = AppData(); data.answers[id] = answer
                XCTAssertTrue(data.needsProfessionalFollowUp)
            }
        }
        var data = AppData(); data.answers = [29: .no, 30: .skipped, 1: .yes]
        XCTAssertFalse(data.needsProfessionalFollowUp)
    }
    func testAnswersNeverChangeParentSelectedStage() {
        var data = AppData(); data.profile = ChildProfile(stage: .registered)
        for i in 1...30 { data.answers[i] = .yes }
        XCTAssertEqual(data.profile?.stage, .registered)
    }
    func testRelatedRecordsExcludeSelfFutureAndOtherCategories() {
        let now = Date(timeIntervalSince1970: 1000)
        let record = BehaviorRecord(date: now, text: "Today", category: .progress)
        let old = BehaviorRecord(date: now.addingTimeInterval(-10), text: "Earlier", category: .progress)
        let future = BehaviorRecord(date: now.addingTimeInterval(10), text: "Later", category: .progress)
        let other = BehaviorRecord(date: now.addingTimeInterval(-20), text: "Other", category: .eating)
        var data = AppData(); data.records = [record, old, future, other]
        XCTAssertEqual(data.related(to: record).map(\.id), [old.id])
    }
    func testReportsPreserveObservedTextAndHaveNoScoring() {
        var data = AppData(); data.profile = ChildProfile(nickname: "Sam", stage: .awaitingAssessment)
        data.records = [BehaviorRecord(text: "Waved hello", category: .progress, context: "At the park", helped: "A quiet space")]
        data.answers = [1: .often, 29: .unsure]
        let question = Question(id: 1, categoryEN: "Social", categoryZH: "社交", en: "Response?", zh: "回應？", yesNo: false)
        let report = ReportBuilder.text(data: data, questions: [question], professional: true)
        XCTAssertTrue(report.contains("Waved hello")); XCTAssertTrue(report.contains("A quiet space"))
        XCTAssertTrue(report.contains("Often")); XCTAssertTrue(report.contains("Not sure"))
        XCTAssertFalse(report.contains("45/90")); XCTAssertFalse(report.contains("Level 2"))
        XCTAssertTrue(report.contains("Parent-selected stage"))
    }
    func testBilingualReportAndAge() {
        var data = AppData(); data.language = .traditionalChinese; data.profile = ChildProfile(ageMonths: 38)
        let report = ReportBuilder.text(data: data, questions: [], professional: false)
        XCTAssertTrue(report.contains("家庭觀察摘要")); XCTAssertTrue(report.contains("3 歲 2 個月"))
        XCTAssertTrue(report.contains("暫無記錄"))
    }
}
