import XCTest
@testable import CareVoiceCore

final class MobileParityTests: XCTestCase {
    func testPasswordPolicyMatchesMobileCharacterClasses() {
        XCTAssertTrue(PasswordPolicy.accepts("CareVoice2026!"))
        for password in ["Short1!", "lowercase1!", "UPPERCASE1!", "NoNumbers!", "NoSymbol12", "Abcdef1🙂"] {
            XCTAssertFalse(PasswordPolicy.accepts(password), password)
        }
        XCTAssertTrue(PasswordPolicy.accepts("Abc1234~"))
        XCTAssertTrue(PasswordPolicy.accepts("Abc1234\\"))
    }
    func testNewQuestionsPreserveSpecialOptionsAndSafety() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("CareVoice/Resources/questions.json"))
        let mobile = try Data(contentsOf: root.appendingPathComponent("mobile/src/questions.json"))
        XCTAssertEqual(bytes, mobile)
        let questions = try JSONDecoder().decode([Question].self, from: bytes)
        XCTAssertEqual(questions.map(\.id), Array(101...133))
        XCTAssertEqual(questions.first(where: { $0.id == 129 })?.options, [.varied, .limited, .unsure])
        XCTAssertEqual(questions.first(where: { $0.id == 131 })?.safety, "regression")
        var data = AppData(); data.answers = [132: .unsure]
        XCTAssertTrue(data.needsSafetyRouting); XCTAssertFalse(data.needsProfessionalFollowUp)
        data.answers = [131: .yes]
        XCTAssertTrue(data.needsProfessionalFollowUp); XCTAssertFalse(data.needsSafetyRouting)
        XCTAssertEqual(JourneyStage.onboarding.count, 7)
        XCTAssertFalse(JourneyStage.onboarding.contains(.diagnosed))
    }
    func testPortableBackupRoundTripAndLegacyCompatibility() throws {
        var data = AppData(); data.language = .simplifiedChinese
        data.profile = ChildProfile(nickname: "樂樂", ageMonths: 36, stage: .waitingSupport)
        data.records = [BehaviorRecord(text: "今天與媽媽一起玩遊戲。", context: "At home")]
        data.answers = [129: .varied, 131: .unsure, 29: .yes]
        data.regressionWhen = [131: "Last week"]
        let bytes = try BackupCodec.encode(data)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(object["language"] as? String, "zh-Hans")
        XCTAssertTrue((object["records"] as? [[String: Any]])?.first?["date"] is String)
        let restored = try BackupCodec.decode(bytes)
        XCTAssertEqual(restored.records[0].text, data.records[0].text)
        XCTAssertEqual(restored.answers, data.answers)
        XCTAssertEqual(restored.regressionWhen, data.regressionWhen)
        XCTAssertEqual(restored.profile?.nickname, "樂樂")
        XCTAssertEqual(try BackupCodec.decode(JSONEncoder().encode(data)), data)
    }
    func testBadBackupsAreRejectedBeforeReplacingData() throws {
        var data = AppData(); data.version = 2
        XCTAssertThrowsError(try BackupCodec.decode(JSONEncoder().encode(data)))
        data.version = 1; data.records = [BehaviorRecord(text: "record")]; data.records.append(data.records[0])
        XCTAssertThrowsError(try BackupCodec.decode(JSONEncoder().encode(data)))
        XCTAssertThrowsError(try BackupCodec.decode(Data("{}".utf8)))
    }
    func testBirthdayAgeChangesAndMissingBirthdayRemainsCompatible() throws {
        let birthday = Calendar.current.date(byAdding: .month, value: -42, to: Date())!
        let profile = ChildProfile(ageMonths: 36, birthDate: birthday)
        XCTAssertEqual(profile.currentAgeMonths, 42)
        XCTAssertEqual(try JSONDecoder().decode(ChildProfile.self, from: JSONEncoder().encode(ChildProfile(ageMonths: 36))).currentAgeMonths, 36)
    }
}
