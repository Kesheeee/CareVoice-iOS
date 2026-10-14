import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english, traditionalChinese
    var id: String { rawValue }
    var locale: Locale { Locale(identifier: self == .english ? "en_HK" : "zh_Hant_HK") }
    func text(_ en: String, _ zh: String) -> String { self == .english ? en : zh }
}

enum JourneyStage: String, Codable, CaseIterable, Identifiable {
    case noticed, professionalFollowUp, awaitingAssessment, assessed, diagnosed, registered
    var id: String { rawValue }
    func title(_ l: AppLanguage) -> String {
        switch self {
        case .noticed: return l.text("Just noticing differences", "剛留意到一些不同")
        case .professionalFollowUp: return l.text("A professional suggested follow-up", "專業人士建議跟進")
        case .awaitingAssessment: return l.text("Referred / awaiting assessment", "已轉介／等候評估")
        case .assessed: return l.text("Assessed, with a report", "已完成評估並取得報告")
        case .diagnosed: return l.text("Already diagnosed", "已有診斷")
        case .registered: return l.text("Registered for services", "已登記輪候服務")
        }
    }
    func nextStep(_ l: AppLanguage) -> String {
        switch self {
        case .noticed, .professionalFollowUp: return l.text("Discuss your observations with your family doctor or Maternal & Child Health Centre.", "與家庭醫生或母嬰健康院討論你觀察到的情況。")
        case .awaitingAssessment: return l.text("Check your referral and appointment details with your Child Assessment Centre. Bring your observations.", "向兒童體能智力測驗中心確認轉介及預約安排，並準備日常觀察記錄。")
        case .assessed, .diagnosed: return l.text("Discuss the report and suitable service referrals with your social worker or assessment team.", "與社工或評估團隊討論報告及合適的服務轉介。")
        case .registered: return l.text("Keep your referring social worker updated and ask about support available while waiting.", "與轉介社工保持聯絡，了解輪候期間可用的支援。")
        }
    }
}

struct ChildProfile: Codable, Equatable {
    var nickname = ""
    var ageMonths = 36
    var stage: JourneyStage = .noticed
    var firstConcernDate = Date()
    var concernNotes = ""
    func displayName(_ l: AppLanguage) -> String { nickname.isEmpty ? l.text("Your child", "你的孩子") : nickname }
    func age(_ l: AppLanguage) -> String { l.text("\(ageMonths / 12)y \(ageMonths % 12)m", "\(ageMonths / 12) 歲 \(ageMonths % 12) 個月") }
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
    case never, rarely, sometimes, often, yes, no, unsure, skipped
    func title(_ l: AppLanguage) -> String {
        switch self {
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
    func text(_ l: AppLanguage) -> String { l.text(en, zh) }
    func category(_ l: AppLanguage) -> String { l.text(categoryEN, categoryZH) }
    var options: [Answer] { yesNo ? [.yes, .no, .unsure] : [.never, .rarely, .sometimes, .often, .unsure] }
}

struct AppData: Codable, Equatable {
    var version = 1
    var language: AppLanguage = .english
    var profile: ChildProfile? = nil
    var records: [BehaviorRecord] = []
    var answers: [Int: Answer] = [:]
    var completedSteps: Set<String> = []
    var answeredCount: Int { answers.values.filter { $0 != .skipped }.count }
    var reviewedCount: Int { answers.count }
    var needsProfessionalFollowUp: Bool {
        [29, 30].contains { answers[$0] == .yes || answers[$0] == .unsure }
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
