import Foundation

enum CommunityTopic: String, Codable, CaseIterable, Identifiable {
    case everyday, assessment, school, waiting, celebrations
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .everyday: return language.text("Everyday care", "日常照顧")
        case .assessment: return language.text("Assessments", "評估安排")
        case .school: return language.text("School & learning", "學校與學習")
        case .waiting: return language.text("While waiting", "輪候期間")
        case .celebrations: return language.text("Small wins", "小小進步")
        }
    }
}

enum CommunityReason: String, CaseIterable, Identifiable {
    case privacy, harmful, harassment, spam, other
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .privacy: return language.text("Personal information", "個人資料")
        case .harmful: return language.text("Harmful advice or content", "有害建議或內容")
        case .harassment: return language.text("Harassment", "騷擾")
        case .spam: return language.text("Spam or promotion", "垃圾訊息或推廣")
        case .other: return language.text("Something else", "其他問題")
        }
    }
}

struct CommunityProfile: Codable, Identifiable {
    let userId: UUID
    let displayName: String
    var id: UUID { userId }
}
struct CommunityPost: Codable, Identifiable {
    let id: UUID
    let authorId: UUID
    let authorName: String
    let topic: CommunityTopic
    let title: String
    let body: String
    let status: String
    let createdAt: String
    let updatedAt: String
    let replyCount: Int
    var removed: Bool { status == "removed" }
}
struct CommunityReply: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let authorName: String
    let body: String
    let status: String
    let createdAt: String
    let updatedAt: String
}
struct CommunityReport: Codable, Identifiable {
    let id: UUID
    let targetKind: String
    let targetId: UUID
    let reason: String
    let detail: String
    let state: String
    let createdAt: String
}
struct CommunityBlock: Codable, Identifiable {
    let blockedId: UUID
    var id: UUID { blockedId }
}
struct CommunityUser: Codable { let id: UUID; let email: String? }
struct CommunitySession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Double
    let user: CommunityUser
    enum CodingKeys: String, CodingKey { case accessToken, refreshToken, expiresAt, expiresIn, user }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        refreshToken = try c.decode(String.self, forKey: .refreshToken)
        user = try c.decode(CommunityUser.self, forKey: .user)
        expiresAt = try c.decodeIfPresent(Double.self, forKey: .expiresAt)
            ?? (Date().timeIntervalSince1970 + c.decode(Double.self, forKey: .expiresIn))
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(accessToken, forKey: .accessToken); try c.encode(refreshToken, forKey: .refreshToken)
        try c.encode(expiresAt, forKey: .expiresAt); try c.encode(user, forKey: .user)
    }
}

enum CommunityValidation {
    static func clean(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    // PostgreSQL char_length counts Unicode scalars, so client and server agree on limits.
    static func length(_ text: String) -> Int { clean(text).unicodeScalars.count }
    static func validPost(title: String, body: String) -> Bool {
        (3...120).contains(length(title)) && (1...3000).contains(length(body))
    }
    static func validReply(_ body: String) -> Bool { (1...1500).contains(length(body)) }
    static func validNickname(_ name: String) -> Bool { (2...40).contains(length(name)) }
    static func date(_ timestamp: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
    }
}

enum CommunityFailure: Error {
    case unavailable, signIn, denied, rateLimit, conflict, invalid, network, storage
    case credentials, unconfirmed, weakPassword, emailLimit, emailUnavailable
    func message(_ language: AppLanguage) -> String {
        switch self {
        case .credentials: return language.text("The email or password is incorrect. Please try again.", "電郵或密碼不正確，請再試。")
        case .unconfirmed: return language.text("Check your inbox and confirm your email before signing in.", "請檢查收件箱並確認電郵後再登入。")
        case .weakPassword: return language.text("Use at least 8 characters with an uppercase letter, lowercase letter, number and symbol.", "請使用至少八個字元，包含大寫字母、小寫字母、數字及符號。")
        case .emailLimit: return language.text("Email delivery has reached its sending limit. This request could not be completed. Please try later or contact CareVoice support.", "電郵寄送已達上限，未能完成此要求。請稍後再試或聯絡 CareVoice 支援。")
        case .emailUnavailable: return language.text("Email delivery is not available for this address yet. Please contact CareVoice support.", "目前未能向此地址寄送電郵，請聯絡 CareVoice 支援。")
        case .unavailable: return language.text("Community connection is not configured yet.", "社區連接尚未設定。")
        case .signIn: return language.text("Please sign in again. Your text is still here.", "請重新登入，你的文字仍保留在此。")
        case .denied: return language.text("This action is not available for your account or this discussion.", "你的帳戶或此討論目前無法執行這項操作。")
        case .rateLimit: return language.text("Please wait a little before trying again.", "請稍候再試。")
        case .conflict: return language.text("This item already exists or was changed. Refresh and try again.", "此項目已存在或已變更，請重新整理後再試。")
        case .invalid: return language.text("Please check the details or verification code and try again.", "請檢查資料或驗證碼後再試。")
        case .network: return language.text("Could not connect. Check your connection and try again. Your text has been kept.", "未能連接，請檢查網絡後再試。你的文字已保留。")
        case .storage: return language.text("Your sign-in could not be saved securely. Unlock your device and try again.", "未能安全儲存登入資料，請解鎖裝置後再試。")
        }
    }
}
