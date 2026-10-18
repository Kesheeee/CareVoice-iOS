import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english, traditionalChinese, simplifiedChinese
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        }
    }
    var shortName: String {
        switch self {
        case .english: return "EN"
        case .traditionalChinese: return "繁"
        case .simplifiedChinese: return "简"
        }
    }
    var locale: Locale {
        switch self {
        case .english: return Locale(identifier: "en_HK")
        case .traditionalChinese: return Locale(identifier: "zh_Hant_HK")
        case .simplifiedChinese: return Locale(identifier: "zh_Hans_CN")
        }
    }
    var speechLocale: Locale {
        switch self {
        case .english: return Locale(identifier: "en-US")
        case .traditionalChinese: return Locale(identifier: "zh-HK")
        case .simplifiedChinese: return Locale(identifier: "zh-CN")
        }
    }
    // Convert app-owned copy at display time, never saved user text or source quotations.
    func chineseText(_ traditional: String) -> String {
        guard self == .simplifiedChinese else { return traditional }
        let simplified = traditional.applyingTransform(StringTransform("Traditional-Simplified"), reverse: false) ?? traditional
        return simplified.replacingOccurrences(of: "帐户", with: "账户")
    }
    func text(_ en: String, _ zh: String) -> String { self == .english ? en : chineseText(zh) }
}

enum JourneyStage: String, Codable, CaseIterable, Identifiable {
    case noticed, professionalFollowUp, awaitingAssessment, assessed, diagnosed, registered, waitingSupport, receivingServices
    static let onboarding: [JourneyStage] = [.noticed, .professionalFollowUp, .awaitingAssessment, .assessed, .registered, .waitingSupport, .receivingServices]
    var id: String { rawValue }
    func title(_ l: AppLanguage) -> String {
        switch self {
        case .noticed: return l.text("Just noticing differences", "剛留意到一些不同")
        case .professionalFollowUp: return l.text("Seeking a professional referral", "專業人士建議跟進")
        case .awaitingAssessment: return l.text("Referred / awaiting assessment", "已轉介／等候評估")
        case .assessed: return l.text("Assessment completed / discussing referral", "已完成評估並取得報告")
        case .diagnosed: return l.text("Already diagnosed", "已有診斷")
        case .waitingSupport: return l.text("Arranging support while waiting", "輪候期間安排過渡支援")
        case .receivingServices: return l.text("Allocated a service / changing services", "已獲編配服務／更改服務選擇")
        case .registered: return l.text("Registered in the central referral system", "已登記輪候服務")
        }
    }
    func nextStep(_ l: AppLanguage) -> String {
        switch self {
        case .noticed, .professionalFollowUp: return l.text("Discuss your observations with your family doctor or Maternal & Child Health Centre.", "與家庭醫生或母嬰健康院討論你觀察到的情況。")
        case .awaitingAssessment: return l.text("Check your referral and appointment details with your Child Assessment Centre. Bring your observations.", "向兒童體能智力測驗中心確認轉介及預約安排，並準備日常觀察記錄。")
        case .assessed, .diagnosed: return l.text("Discuss the report and suitable service referrals with your social worker or assessment team.", "與社工或評估團隊討論報告及合適的服務轉介。")
        case .registered, .waitingSupport, .receivingServices: return l.text("Keep your referring social worker updated and ask about support available while waiting.", "與轉介社工保持聯絡，了解輪候期間可用的支援。")
        }
    }
}

struct ChildProfile: Codable, Equatable {
    var nickname = ""
    var ageMonths = 36
    var birthDate: Date? = nil
    var supportGoals: [String]? = nil
    var currentAgeMonths: Int { birthDate.map { max(0, Calendar.current.dateComponents([.month], from: Calendar.current.startOfDay(for: $0), to: Calendar.current.startOfDay(for: Date())).month ?? ageMonths) } ?? ageMonths }
    var stage: JourneyStage = .noticed
    var firstConcernDate = Date()
    var concernNotes = ""
    func displayName(_ l: AppLanguage) -> String { nickname.isEmpty ? l.text("Your child", "你的孩子") : nickname }
    func age(_ l: AppLanguage) -> String { l.text("\(currentAgeMonths / 12)y \(currentAgeMonths % 12)m", "\(currentAgeMonths / 12) 歲 \(currentAgeMonths % 12) 個月") }
}

enum RecordCategory: String, Codable, CaseIterable, Identifiable {
    case observation, distress, progress, communication, sensory, play, eating
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .observation: return "text.bubble"
        case .distress: return "cloud.rain"
        case .progress: return "sparkles"
        case .communication: return "bubble.left.and.bubble.right"
        case .sensory: return "ear"
        case .play: return "puzzlepiece"
        case .eating: return "fork.knife"
        }
    }
    func title(_ l: AppLanguage) -> String {
        switch self {
        case .observation: return l.text("Observation", "日常觀察")
        case .distress: return l.text("Distress", "情緒困擾")
        case .progress: return l.text("Progress", "進步")
        case .communication: return l.text("Communication", "溝通")
        case .sensory: return l.text("Sensory", "感官")
        case .play: return l.text("Play", "遊戲")
        case .eating: return l.text("Eating", "飲食")
        }
    }
}

struct BehaviorRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var text: String
    var category: RecordCategory = .observation
    var location = ""
    var durationMinutes: Int? = nil
    var context = ""
    var helped = ""
}

enum Answer: String, Codable, CaseIterable {
    case varied, limited, never, rarely, sometimes, often, yes, no, unsure, skipped
    func title(_ l: AppLanguage) -> String {
        switch self {
        case .varied: return l.text("Several kinds", "幾種都玩")
        case .limited: return l.text("Only one or two", "淨係一兩樣")
        case .never: return l.text("Never", "從不")
        case .rarely: return l.text("Rarely", "少見")
        case .sometimes: return l.text("Sometimes", "有時")
        case .often: return l.text("Often", "經常")
        case .yes: return l.text("Yes", "是")
        case .no: return l.text("No", "否")
        case .unsure: return l.text("Not sure", "不確定")
        case .skipped: return l.text("Skipped", "已略過")
        }
    }
}

struct Question: Codable, Identifiable {
    let id: Int
    let categoryEN: String
    let categoryZH: String
    let en: String
    let zh: String
    let yesNo: Bool
    var customOptions: [Answer]? = nil
    var safety: String? = nil
    enum CodingKeys: String, CodingKey { case id, categoryEN, categoryZH, en, zh, yesNo, safety; case customOptions = "options" }
    func text(_ l: AppLanguage) -> String { l.text(en, zh) }
    func category(_ l: AppLanguage) -> String { l.text(categoryEN, categoryZH) }
    var options: [Answer] { customOptions ?? (yesNo ? [.yes, .no, .unsure] : [.never, .rarely, .sometimes, .often, .unsure]) }
}

struct AppData: Codable, Equatable {
    var version = 1
    var language: AppLanguage = .english
    var caregiverName: String? = nil
    var profile: ChildProfile? = nil
    var records: [BehaviorRecord] = []
    var answers: [Int: Answer] = [:]
    var completedSteps: Set<String> = []
    var regressionWhen: [Int: String]? = nil
    var answeredCount: Int { answers.filter { (101...133).contains($0.key) && $0.value != .skipped }.count }
    var reviewedCount: Int { answers.keys.filter { (101...133).contains($0) }.count }
    var needsSafetyRouting: Bool { [132, 133].contains { answers[$0] == .yes || answers[$0] == .unsure } }
    var needsProfessionalFollowUp: Bool {
        [29, 30, 131].contains { answers[$0] == .yes || answers[$0] == .unsure }
    }
    func related(to record: BehaviorRecord) -> [BehaviorRecord] {
        records.filter { $0.id != record.id && $0.date <= record.date && $0.category == record.category }
            .sorted { $0.date > $1.date }.prefix(3).map { $0 }
    }
}

/// Human-entered observations only. No score, diagnosis, severity or inferred cause is generated.
enum ReportBuilder {
    static func text(data: AppData, questions: [Question], professional: Bool, now: Date = Date()) -> String {
        let l = data.language
        let formatter = DateFormatter(); formatter.locale = l.locale; formatter.dateStyle = .medium; formatter.timeStyle = .short
        var lines = ["CareVoice", professional ? l.text("Appointment preparation report", "會面準備報告") : l.text("Family observation summary", "家庭觀察摘要"), formatter.string(from: now), ""]
        if let p = data.profile {
            lines += ["\(p.displayName(l)) · \(p.age(l))", l.text("Parent-selected stage: ", "家長選擇的階段：") + p.stage.title(l)]
            if professional {
                lines += [l.text("First noticed: ", "首次留意日期：") + formatter.string(from: p.firstConcernDate)]
                if !p.concernNotes.isEmpty { lines += [p.concernNotes] }
            }
        }
        lines += ["", l.text("Parent observations — not a diagnosis or clinical assessment.", "家長觀察記錄，並非診斷或臨床評估。"), "", l.text("Questionnaire responses", "問卷回答")]
        for q in questions {
            if let a = data.answers[q.id], a != .skipped { lines += ["\(q.id). \(q.text(l))", "   \(a.title(l))"] }
        }
        if let bytes = ContentData.load("legacy-questions"), let legacy = try? JSONDecoder().decode([Question].self, from: bytes), data.answers.keys.contains(where: { $0 < 101 }), !questions.contains(where: { $0.id < 101 }) {
            lines += ["", l.text("Earlier questionnaire responses", "舊版問卷回答")]
            for q in legacy { if let a = data.answers[q.id], a != .skipped { lines += [q.text(l), a.title(l)] } }
        }
        if let when = data.regressionWhen?[131], !when.isEmpty { lines += [l.text("When the change was noticed: ", "何時留意到變化：") + when] }
        if data.needsSafetyRouting { lines += [l.text("A seizure or self-injury response was Yes or Not sure. Discuss these observations promptly with a doctor. Seek emergency medical help for immediate danger.", "抽搐或傷害自己的題目回答為有或不確定，請盡快與醫生討論。如有即時危險，請尋求緊急醫療協助。")] }
        if data.needsProfessionalFollowUp { lines += ["", l.text("A loss-of-skills response was Yes or Not sure. Discuss this observation promptly with a qualified professional.", "技能退步題目回答為「是」或「不確定」，請盡快與合資格專業人士討論。") ] }
        lines += ["", l.text("Behavior records", "行為記錄")]
        for r in data.records.sorted(by: { $0.date < $1.date }) {
            lines += ["", "\(formatter.string(from: r.date)) · \(r.category.title(l))", r.text]
            if !r.location.isEmpty { lines += [l.text("Place: ", "地點：") + r.location] }
            if let duration = r.durationMinutes { lines += [l.text("Duration: \(duration) min", "持續：\(duration) 分鐘")] }
            if !r.context.isEmpty { lines += [l.text("What happened before: ", "之前發生了甚麼：") + r.context] }
            if !r.helped.isEmpty { lines += [l.text("What helped: ", "有幫助的方法：") + r.helped] }
        }
        if data.records.isEmpty { lines += [l.text("No records yet.", "暫無記錄。") ] }
        if professional { lines += ["", l.text("Questions to discuss at the appointment", "會面時希望討論的問題"), "• ______________________________", "• ______________________________"] }
        return lines.joined(separator: "\n")
    }
}
