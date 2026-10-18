import XCTest
@testable import CareVoiceCore

final class CommunityTests: XCTestCase {
    func testValidationMatchesServerLimits() {
        XCTAssertFalse(CommunityValidation.validPost(title: "  ", body: "hello"))
        XCTAssertTrue(CommunityValidation.validPost(title: "問題分享", body: "今天有一點進步。"))
        XCTAssertFalse(CommunityValidation.validPost(title: String(repeating: "A", count: 121), body: "hello"))
        XCTAssertFalse(CommunityValidation.validReply(String(repeating: "好", count: 1501)))
        XCTAssertFalse(CommunityValidation.validNickname(" "))
        XCTAssertEqual(CommunityValidation.length(" 👨‍👩‍👧 "), 5)
        XCTAssertNotNil(CommunityValidation.date("2026-10-18T10:30:00.123456+00:00"))
    }
    func testCommunityPostDecodesWithoutPrivateChildData() throws {
        let payload = #"{"id":"11111111-1111-1111-1111-111111111111","author_id":"22222222-2222-2222-2222-222222222222","author_name":"Parent","topic":"everyday","title":"A question","body":"My own words","status":"visible","created_at":"2026-10-18T00:00:00Z","updated_at":"2026-10-18T00:00:00Z","reply_count":2}"#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let post = try decoder.decode(CommunityPost.self, from: Data(payload.utf8))
        XCTAssertEqual(post.authorName,"Parent"); XCTAssertEqual(post.replyCount,2)
        XCTAssertEqual(post.topic,.everyday); XCTAssertFalse(post.removed)
        let encoded = String(decoding: try JSONEncoder().encode(post), as: UTF8.self)
        XCTAssertFalse(encoded.contains("birthDate")); XCTAssertFalse(encoded.contains("email"))
    }
    func testAuthSessionSupportsRelativeExpiry() throws {
        let payload = #"{"access_token":"test-only-access","refresh_token":"test-only-refresh","expires_in":3600,"user":{"id":"11111111-1111-1111-1111-111111111111","email":"test@example.invalid"}}"#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let session = try decoder.decode(CommunitySession.self, from: Data(payload.utf8))
        XCTAssertGreaterThan(session.expiresAt, Date().timeIntervalSince1970 + 3500)
        let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
        let saved = try decoder.decode(CommunitySession.self, from: encoder.encode(session))
        XCTAssertEqual(saved.expiresAt,session.expiresAt)
        XCTAssertEqual(saved.user.id,session.user.id)
    }
}
