// CareVoice — single-file native review edition (iOS 17+, Xcode 15+).
// CREATE A NEW iOS App target, remove its generated App/ContentView files, and
// add ONLY this Swift file. Do not compile alongside the original CareVoice files:
// this file intentionally includes their models, store, views and @main entry.
// In Info.plist add NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription
// before using voice input. Speech recognition availability depends on iOS permissions.
// Optional: add mobile/public/media/carevoice-family-hd.mp4 and .jpg to Copy Bundle
// Resources. A native illustration is shown when these media files are absent.
// Includes local protected JSON storage, records, questionnaire, reports/PDF sharing,
// official-resource community, journey checklist, settings, backup/restore and survey.
// Auth is an explicit preview. No account service, cloud sync or community backend.
// Review scope: native adaptation of the approved phone design; simulator visual QA pending. Retains
// the native 30-question questionnaire (embedded below), not the web's revised 33.
// No Xcode compiler is available on the Windows authoring host; build on macOS.
// No asset catalog, external package, or external questionnaire JSON is required.

import SwiftUI
import Foundation
import UIKit
import CoreText
import AVFoundation
import AVKit
import Speech
import UniformTypeIdentifiers

// MARK: - CareVoice/Core/Models.swift

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english, traditionalChinese
    var id: String { rawValue }
    var locale: Locale { Locale(identifier: self == .english ? "en_HK" : "zh_Hant_HK") }
    func text(_ en: String, _ zh: String) -> String { self == .english ? en : zh }
}

enum JourneyStage: String, Codable, CaseIterable, Identifiable {
    case noticed, professionalFollowUp, awaitingAssessment, assessed, diagnosed, registered, waitingSupport, receivingServices
    var id: String { rawValue }
    func title(_ l: AppLanguage) -> String {
        switch self {
        case .noticed: return l.text("Just noticing differences", "剛留意到一些不同")
        case .professionalFollowUp: return l.text("A professional suggested follow-up", "專業人士建議跟進")
        case .awaitingAssessment: return l.text("Referred / awaiting assessment", "已轉介／等候評估")
        case .assessed: return l.text("Assessed, with a report", "已完成評估並取得報告")
        case .diagnosed: return l.text("Already diagnosed", "已有診斷")
        case .registered: return l.text("Registered in the central queue", "已登記中央輪候")
        case .waitingSupport: return l.text("Support while waiting", "輪候期間支援")
        case .receivingServices: return l.text("Allocated a service", "已獲編配服務")
        }
    }
    func nextStep(_ l: AppLanguage) -> String {
        switch self {
        case .noticed, .professionalFollowUp: return l.text("Discuss your observations with your family doctor or Maternal & Child Health Centre.", "與家庭醫生或母嬰健康院討論你觀察到的情況。")
        case .awaitingAssessment: return l.text("Check your referral and appointment details with your Child Assessment Centre. Bring your observations.", "向兒童體能智力測驗中心確認轉介及預約安排，並準備日常觀察記錄。")
        case .assessed, .diagnosed: return l.text("Discuss the report and suitable service referrals with your social worker or assessment team.", "與社工或評估團隊討論報告及合適的服務轉介。")
        case .receivingServices: return l.text("Keep your service team’s contact details and record questions for your next appointment.", "保留服務團隊嘅聯絡資料，記低下次會面想問嘅問題。")
        case .registered, .waitingSupport: return l.text("Keep your referring social worker updated and ask about support available while waiting.", "與轉介社工保持聯絡，了解輪候期間可用的支援。")
        }
    }
}

struct ChildProfile: Codable, Equatable {
    var nickname = ""
    var ageMonths = 36
    var birthDate: Date? = nil
    var supportGoals: [String]? = nil
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
    var caregiverName: String? = nil
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

// MARK: - CareVoice/AppStore.swift

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data = AppData()
    @Published var errorMessage: String?
    @Published private(set) var storageUnavailable = false
    let questions: [Question]
    let content = GovernmentContent.load()
    private let fileURL: URL
    private let isUITest: Bool
    var language: AppLanguage { data.language }
    func t(_ en: String, _ zh: String) -> String { language.text(en, zh) }

    init() {
        isUITest = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CareVoice", isDirectory: true)
        fileURL = directory.appendingPathComponent(isUITest ? "ui-test-data.json" : "family-data.json")
        do {
            questions = try JSONDecoder().decode([Question].self, from: Data(EmbeddedQuestionnaire.json.utf8))
        } catch {
            questions = []
            errorMessage = "The questionnaire could not be loaded. Please reinstall the app."
        }
        if (!isUITest || ProcessInfo.processInfo.arguments.contains("--preserve-ui-data")), FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                data = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: fileURL))
                guard data.version == 1 else { throw CocoaError(.coderReadCorrupt) }
            } catch {
                storageUnavailable = true
                errorMessage = "Your saved data could not be read. It has been preserved. Restart the app after unlocking your device."
            }
        }
    }

    /// Write first, then publish. A failed disk write must never appear to succeed.
    @discardableResult
    func update(_ edit: (inout AppData) -> Void) -> Bool {
        guard !storageUnavailable else { return false }
        var candidate = data
        edit(&candidate)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoded = try JSONEncoder().encode(candidate)
            try encoded.write(to: fileURL, options: [.atomic, .completeFileProtection])
            var directory = fileURL.deletingLastPathComponent()
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
            data = candidate
            return true
        } catch {
            errorMessage = t("Changes could not be saved. Please check available device storage and try again.", "未能儲存變更，請檢查裝置儲存空間後再試。")
            return false
        }
    }
    func setLanguage(_ language: AppLanguage) { update { $0.language = language } }
    func saveProfile(_ profile: ChildProfile) -> Bool { update { $0.profile = profile } }
    func saveRecord(_ record: BehaviorRecord) -> Bool {
        update { data in
            if let i = data.records.firstIndex(where: { $0.id == record.id }) { data.records[i] = record }
            else { data.records.insert(record, at: 0) }
        }
    }
    func deleteRecord(_ id: UUID) { update { $0.records.removeAll { $0.id == id } } }
    func answer(_ question: Question, _ answer: Answer) { update { $0.answers[question.id] = answer } }
    func erase() { update { let l = $0.language; $0 = AppData(); $0.language = l } }
}

// MARK: - CareVoice/SpeechRecorder.swift

@MainActor
final class SpeechRecorder: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isStarting = false
    @Published var seconds = 0
    @Published var error: String?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Task<Void, Never>?
    private var tapInstalled = false
    private var generation = UUID()

    func start(language: AppLanguage) async {
        guard !isRecording && !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        error = nil
        let sessionID = UUID(); generation = sessionID
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language == .english ? "en-US" : "zh-HK")), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            error = language.text("On-device speech recognition is unavailable for this language on this device. Please type your observation.", "此裝置暫不支援這個語言的裝置端語音辨識，請使用文字輸入。")
            return
        }
        let speechStatus = await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) } }
        guard speechStatus == .authorized else {
            error = language.text("Speech access is off. You can enable it in Settings or type instead.", "語音辨識權限未開啟，可於設定啟用，或改用文字輸入。")
            return
        }
        guard generation == sessionID else { return }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard microphone else {
            error = language.text("Microphone access is off. You can enable it in Settings or type instead.", "咪高峰權限未開啟，可於設定啟用，或改用文字輸入。")
            return
        }
        guard !Task.isCancelled, generation == sessionID else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            self.request = request
            let node = engine.inputNode
            let format = node.outputFormat(forBus: 0)
            guard format.sampleRate > 0 && format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            transcript = ""; seconds = 0
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, failure in
                let text = result?.bestTranscription.formattedString
                let finished = result?.isFinal == true
                Task { @MainActor [weak self] in
                    guard let self, self.generation == sessionID else { return }
                    if let text { self.transcript = text }
                    if finished || failure != nil {
                        if failure != nil && self.transcript.isEmpty { self.error = language.text("No speech was recognised. Please try again or type your observation.", "未能辨識語音，請再試或使用文字輸入。") }
                        self.stop()
                    }
                }
            }
            engine.prepare(); try engine.start(); isRecording = true
            timer = Task { [weak self] in
                for second in 1...60 {
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                    guard let self, self.isRecording else { return }
                    self.seconds = second
                }
                self?.stop()
            }
        } catch {
            stop()
            self.error = language.text("Recording could not start. Please try again or type your observation.", "未能開始錄音，請再試或使用文字輸入。")
        }
    }
    func stop() {
        generation = UUID()
        timer?.cancel(); timer = nil
        if engine.isRunning { engine.stop() }
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); recognitionTask?.cancel()
        request = nil; recognitionTask = nil; isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - CareVoice/CareVoiceApp.swift

@main
struct CareVoiceApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            Group {
                if store.storageUnavailable {
                    ContentUnavailableView("Saved data unavailable", systemImage: "lock.shield", description: Text("Your data is preserved. Unlock your device and restart CareVoice."))
                } else if store.data.profile == nil {
                    CompleteWelcomeView()
                } else {
                    MainView()
                }
            }
            .environmentObject(store)
            .environment(\.locale, store.language.locale)
            .tint(Brand.blue)
            .alert(store.t("Unable to complete action", "未能完成操作"), isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button(store.t("OK", "確定"), role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }
}

enum Brand {
    static let blue = Color(red: 0.082, green: 0.396, blue: 0.753)
    static let teal = Color(red: 0.04, green: 0.52, blue: 0.48)
    static let background = Color(red: 0.965, green: 0.973, blue: 0.985)
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol) }
                .padding(18).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 18))
    }
}

struct SectionHeading: View {
    let title: String
    var body: some View { Text(title).font(.title3.weight(.bold)).foregroundStyle(.primary) }
}

struct MainView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection = 0
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selection {
                case 0: NavigationStack { HomeView() }
                case 1: NavigationStack { RecordsView() }
                case 2: NavigationStack { ResourcesView() }
                default: NavigationStack { ProfileView() }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                tab(0, "house", store.t("Home", "首頁"))
                tab(1, "text.book.closed", store.t("Records", "記錄"))
                tab(2, "person.2", store.t("Community", "社區"))
                tab(3, "person.crop.circle", store.t("Profile", "我的檔案"))
            }.padding(.horizontal).background(.bar)
        }
    }
    private func tab(_ index: Int, _ symbol: String, _ label: String) -> some View {
        Button { selection = index } label: {
            Image(systemName: symbol).font(.title3).frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(selection == index ? Brand.blue : Color.secondary)
        }.accessibilityLabel(label).accessibilityAddTraits(selection == index ? .isSelected : [])
    }
}

// MARK: - CareVoice/Features/Onboarding.swift

struct WelcomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var showProfile = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        Label("CareVoice", systemImage: "bubble.left.and.bubble.right.fill").font(.headline).foregroundStyle(Brand.blue)
                        Spacer()
                        Menu { ForEach(AppLanguage.allCases) { l in Button(l == .english ? "English" : "繁體中文") { store.setLanguage(l) } } } label: {
                            Label(store.language == .english ? "EN" : "繁", systemImage: "globe")
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 40).fill(Brand.blue.opacity(0.07))
                        Circle().fill(Brand.teal.opacity(0.12)).frame(width: 160, height: 160).offset(x: 45, y: -10)
                        Image(systemName: "hands.sparkles.fill").font(.system(size: 88)).foregroundStyle(Brand.blue.gradient).symbolRenderingMode(.hierarchical)
                    }.frame(height: 220).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.t("Small observations.\nMeaningful next steps.", "記下小小觀察\n一起踏出下一步"))
                            .font(.system(.largeTitle, design: .rounded).bold())
                        Text(store.t("A little support for your family’s journey. Capture everyday moments and find your way to care in Hong Kong.", "為香港家庭的成長旅程提供支援，記下日常點滴，了解下一步的服務選擇。"))
                            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        feature("mic", store.t("Capture", "記錄"))
                        feature("safari", store.t("Navigate", "導航"))
                        feature("doc.text", store.t("Prepare", "準備"))
                    }
                    PrimaryButton(title: store.t("Get started", "開始使用")) { showProfile = true }.accessibilityIdentifier("getStarted")
                    Text(store.t("For caregivers of children aged 0–6. CareVoice organises your observations; it does not diagnose or assess your child. Your records stay on this device unless you choose to share a report.", "適合 0–6 歲兒童的照顧者。CareVoice 協助整理觀察，並不提供診斷或評估。除非你選擇分享報告，記錄只會保留在此裝置。"))
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: 600)
            }.background(Brand.background)
                .sheet(isPresented: $showProfile) { NavigationStack { ProfileEditor(isOnboarding: true) } }
        }
    }
    private func feature(_ symbol: String, _ title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Brand.blue)
            Text(title).font(.subheadline.weight(.medium))
        }.frame(maxWidth: .infinity).padding(.vertical, 16).background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ProfileEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var isOnboarding = false
    @State private var profile = ChildProfile()
    var body: some View {
        Form {
            Section {
                TextField(store.t("Nickname (optional)", "暱稱（選填）"), text: $profile.nickname).textContentType(.nickname).accessibilityIdentifier("nickname")
                DatePicker(store.t("Birthday", "生日"), selection: Binding(get: { profile.birthDate ?? Calendar.current.date(byAdding: .month, value: -profile.ageMonths, to: Date())! }, set: { profile.birthDate = $0; profile.ageMonths = Calendar.current.dateComponents([.month], from: $0, to: Date()).month ?? 0 }), in: Calendar.current.date(byAdding: .year, value: -7, to: Date())!...Date(), displayedComponents: .date)
            } header: { Text(store.t("About your child", "關於你的孩子")) }
            footer: { Text(store.t("Use a nickname. A full name and photo are not needed.", "使用暱稱即可，無須提供全名或相片。")) }
            Section {
                ForEach(JourneyStage.allCases) { stage in
                    Button { profile.stage = stage } label: {
                        HStack {
                            Text(stage.title(store.language)).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: profile.stage == stage ? "checkmark.circle.fill" : "circle").foregroundStyle(profile.stage == stage ? Brand.blue : .secondary)
                        }.padding(.vertical, 6)
                    }.accessibilityAddTraits(profile.stage == stage ? .isSelected : [])
                }
            } header: { Text(store.t("Where are you now?", "你目前在哪個階段？")) }
            footer: { Text(store.t("Choose your current situation. You can change it any time. This is not a clinical level.", "選擇目前的情況，之後可隨時更改。這不是臨床嚴重程度。")) }
            Section(store.t("Your first observations", "最初的觀察")) {
                DatePicker(store.t("First noticed", "首次留意日期"), selection: $profile.firstConcernDate, in: ...Date(), displayedComponents: .date)
                TextField(store.t("What prompted you? (optional)", "甚麼令你開始留意？（選填）"), text: $profile.concernNotes, axis: .vertical).lineLimit(3...6)
            }
        }
        .navigationTitle(store.t(isOnboarding ? "Create a profile" : "Edit profile", isOnboarding ? "建立檔案" : "編輯檔案"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(store.t("Cancel", "取消")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(store.t("Save", "儲存")) {
                    profile.nickname = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    if store.saveProfile(profile) { dismiss() }
                }.bold().accessibilityIdentifier("saveProfile")
            }
        }
        .onAppear { profile = store.data.profile ?? ChildProfile() }
    }
}

// MARK: - CareVoice/Features/Home.swift

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var recording = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(store.t("Hello, \(store.data.profile?.displayName(store.language) ?? "there")", "你好，\(store.data.profile?.displayName(store.language) ?? "")"))
                    .font(.title.bold())
                if let p = store.data.profile {
                    Card {
                        HStack(spacing: 14) {
                            Text(String(p.displayName(store.language).prefix(1))).font(.title2.bold()).foregroundStyle(.white)
                                .frame(width: 54, height: 54).background(Brand.blue.gradient, in: RoundedRectangle(cornerRadius: 18))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.displayName(store.language)).font(.title3.bold())
                                Text(p.age(store.language)).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "leaf.fill").foregroundStyle(Brand.teal)
                        }
                        Divider()
                        Text(p.stage.title(store.language)).font(.subheadline.weight(.medium))

                    }
                }
                PrimaryButton(title: store.t("Record a moment", "記錄這一刻"), symbol: "plus") { recording = true }
                HStack(spacing: 12) {
                    NavigationLink { NavigatorView() } label: {
                        VStack(spacing: 12) { Image(systemName: "safari"); Text(store.t("Next step", "下一步")) }
                            .frame(maxWidth: .infinity, minHeight: 96).background(Brand.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    NavigationLink { ReportsView() } label: {
                        VStack(spacing: 12) { Image(systemName: "doc.text"); Text(store.t("Reports", "報告")) }
                            .frame(maxWidth: .infinity, minHeight: 96).background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                }.buttonStyle(.plain).foregroundStyle(Brand.blue)
                NavigationLink { QuestionnaireView() } label: {
                    HStack { Image(systemName: "book"); Text(store.t("Observation questions", "觀察問卷")); Spacer(); Text("\(store.data.answeredCount)/\(store.questions.count)"); Image(systemName: "chevron.right") }.font(.subheadline).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
                SectionHeading(title: store.t("Recent moments", "最近的點滴"))
                if store.data.records.isEmpty {
                    Card {
                        Image(systemName: "text.bubble").font(.title).foregroundStyle(Brand.blue)
                        Text(store.t("Every little moment matters", "每個小片段都值得記下")).font(.headline)
                        Text(store.t("Something new, something difficult, a small win. Your first record can be just a sentence.", "新嘗試、困難時刻或小小進步，第一則記錄可以只有一句話。"))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.data.records.sorted { $0.date > $1.date }.prefix(3)) { r in
                        NavigationLink { RecordDetail(recordID: r.id) } label: { RecordCard(record: r) }.buttonStyle(.plain)
                    }
                }
            }.padding(20).frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
        }.background(Brand.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $recording) { NavigationStack { RecordEditor() } }
    }
    private func stat(_ value: String, _ title: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(value).font(.system(.title, design: .rounded).bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }
    private func feature(_ icon: String, _ title: String, _ subtitle: String, _ color: Color) -> some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 44, height: 44).background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
        }
    }
}

struct QuestionnaireView: View {
    @EnvironmentObject var store: AppStore
    @State private var index = 0
    @State private var summary = false
    @State private var followUp = false
    var body: some View {
        ScrollViewReader { scroll in
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if store.questions.isEmpty {
                    ContentUnavailableView(store.t("Questionnaire unavailable", "問卷暫時無法使用"), systemImage: "exclamationmark.triangle")
                } else if summary {
                    Image(systemName: "checkmark.bubble").font(.system(size: 48)).foregroundStyle(Brand.teal)
                    Text(store.t("Your observations,\nall in one place.", "將你的觀察\n好好整理。"))
                        .font(.system(.largeTitle, design: .rounded).bold())
                    Text(store.t("\(store.data.answeredCount) answered · \(store.data.reviewedCount - store.data.answeredCount) skipped. There is no score or clinical result. You can return to any question.", "已回答 \(store.data.answeredCount) 題・略過 \(store.data.reviewedCount - store.data.answeredCount) 題。問卷不會產生分數或臨床結果，你可以隨時修改答案。"))
                    if store.data.needsProfessionalFollowUp { FollowUpCard() }
                    ForEach(store.questions) { q in
                        Button { index = q.id - 1; summary = false } label: {
                            Card {
                                Text(q.text(store.language)).font(.subheadline).foregroundStyle(.primary)
                                Text(store.data.answers[q.id]?.title(store.language) ?? store.t("Not answered", "尚未回答")).font(.caption.bold()).foregroundStyle(Brand.blue)
                            }
                        }.buttonStyle(.plain)
                    }
                    NavigationLink(store.t("Explore next steps", "查看下一步")) { NavigatorView() }.buttonStyle(.borderedProminent)
                } else {
                    let q = store.questions[index]
                    HStack {
                        Text(store.t("Question \(index + 1) of \(store.questions.count)", "第 \(index + 1) 題，共 \(store.questions.count) 題")).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(store.t("Saved automatically", "自動儲存")).font(.caption).foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(store.data.reviewedCount), total: Double(store.questions.count)).tint(Brand.teal)
                    Text(q.category(store.language)).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.teal)
                    Text(q.text(store.language)).font(.system(.title2, design: .rounded).bold()).fixedSize(horizontal: false, vertical: true)
                    Text(store.t("Think about everyday situations. There are no right or wrong answers.", "想想日常生活中的情況，答案沒有對錯。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    VStack(spacing: 12) {
                        ForEach(q.options, id: \.self) { answer in
                            Button {
                                store.answer(q, answer)
                                if q.id >= 29 && (answer == .yes || answer == .unsure) { followUp = true }
                            } label: {
                                HStack {
                                    Text(answer.title(store.language)).fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: store.data.answers[q.id] == answer ? "checkmark.circle.fill" : "circle")
                                }.padding(18)
                                    .background(store.data.answers[q.id] == answer ? Brand.blue.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            }.accessibilityIdentifier("answer-\(answer.rawValue)")
                        }
                    }
                    HStack {
                        Button(store.t("Previous", "上一題")) { index -= 1 }.disabled(index == 0)
                        Spacer()
                        Button(store.t("Skip", "略過")) { store.answer(q, .skipped); advance() }.accessibilityIdentifier("skipQuestion")
                    }.padding(.vertical, 8)
                    PrimaryButton(title: store.t(index == store.questions.count - 1 ? "Review observations" : "Next question", index == store.questions.count - 1 ? "查看觀察摘要" : "下一題")) { advance() }
                        .disabled(store.data.answers[q.id] == nil).accessibilityIdentifier("nextQuestion")
                    Text(store.t("This questionnaire organises observations. It is not a validated screening or diagnostic tool.", "這份問卷用於整理觀察，並非經驗證的篩查或診斷工具。"))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity).id("questionTop")
        }
        .background(Brand.background).navigationTitle(store.t("Observations", "情況問卷")).navigationBarTitleDisplayMode(.inline)
        .toolbar { Button(store.t("Review", "查看")) { summary = true } }
        .onAppear { index = store.questions.firstIndex { store.data.answers[$0.id] == nil } ?? 0 }
        .sheet(isPresented: $followUp) { NavigationStack { ScrollView { FollowUpCard().padding(24) }.toolbar { Button(store.t("Done", "完成")) { followUp = false } } }.presentationDetents([.medium, .large]) }
        .onChange(of: index) { _, _ in scroll.scrollTo("questionTop", anchor: .top) }
        .onChange(of: summary) { _, _ in scroll.scrollTo("questionTop", anchor: .top) }
        }
    }
    private func advance() { if index < store.questions.count - 1 { index += 1 } else { summary = true } }
}

struct FollowUpCard: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Card {
            Label(store.t("Talk to a professional soon", "請盡快諮詢專業人士"), systemImage: "person.crop.circle.badge.exclamationmark").font(.headline).foregroundStyle(Brand.blue)
            Text(store.t("You reported a possible loss of previously learned skills. Share what changed and when with your family doctor or Maternal & Child Health Centre. CareVoice does not interpret the cause.", "你表示孩子可能失去了已學會的技能。請向家庭醫生或母嬰健康院說明出現了甚麼變化，以及何時發生。CareVoice 不會判斷原因。"))
            Link(store.t("Official CAS guidance", "兒童體能智力測驗服務官方指引"), destination: URL(string: "https://www.dhcas.gov.hk/en/faq.html")!)
        }
    }
}

// MARK: - CareVoice/Features/Records.swift

struct RecordsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var category: RecordCategory?
    @State private var adding = false
    private var filtered: [BehaviorRecord] {
        store.data.records.filter { r in
            (category == nil || r.category == category) && (search.isEmpty || r.text.localizedCaseInsensitiveContains(search) || r.location.localizedCaseInsensitiveContains(search))
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.t("The everyday moments tell a story.", "日常的點滴，訴說成長的故事。"))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterButton(store.t("All", "全部"), value: nil)
                        ForEach(RecordCategory.allCases) { c in filterButton(c.title(store.language), value: c) }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView(store.t(search.isEmpty ? "A fresh page" : "No matching moments", search.isEmpty ? "從第一則記錄開始" : "找不到相關記錄"), systemImage: "text.book.closed", description: Text(store.t("Tap + to capture an observation, a challenge or a little win.", "點按 + 記下觀察、困難或小小進步。")))
                }
                ForEach(filtered) { r in
                    NavigationLink { RecordDetail(recordID: r.id) } label: { RecordCard(record: r) }.buttonStyle(.plain)
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background)
            .navigationTitle(store.t("Your moments", "日常記錄"))
            .searchable(text: $search, prompt: store.t("Search observations", "搜尋記錄"))
            .toolbar { Button { adding = true } label: { Label(store.t("New record", "新增記錄"), systemImage: "plus") }.accessibilityIdentifier("addRecord") }
            .sheet(isPresented: $adding) { NavigationStack { RecordEditor() } }
    }
    private func filterButton(_ title: String, value: RecordCategory?) -> some View {
        Button { category = value } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 10)
                .background(category == value ? Brand.blue : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(category == value ? Color.white : .primary)
        }.buttonStyle(.plain).accessibilityAddTraits(category == value ? .isSelected : [])
    }
}

struct RecordCard: View {
    @EnvironmentObject var store: AppStore
    let record: BehaviorRecord
    var body: some View {
        Card {
            HStack {
                Label(record.category.title(store.language), systemImage: record.category.symbol).font(.caption.weight(.semibold)).foregroundStyle(record.category == .progress ? Brand.teal : Brand.blue)
                Spacer()
                Text(record.date, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary)
            }
            Text(record.text).font(.body).lineLimit(4).foregroundStyle(.primary)
            if !record.location.isEmpty { Label(record.location, systemImage: "mappin").font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct RecordDetail: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @State private var editing = false
    @State private var deleting = false
    var body: some View {
        Group {
            if let record = store.data.records.first(where: { $0.id == recordID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Card {
                            Label(record.category.title(store.language), systemImage: record.category.symbol).foregroundStyle(Brand.blue).font(.headline)
                            Text(record.date, format: .dateTime.year().month().day().hour().minute()).font(.subheadline).foregroundStyle(.secondary)
                            Text(record.text).textSelection(.enabled)
                            if !record.location.isEmpty { Label(record.location, systemImage: "mappin") }
                            if let n = record.durationMinutes { Label(store.t("\(n) minutes", "\(n) 分鐘"), systemImage: "clock") }
                        }
                        if !record.context.isEmpty { Card { SectionHeading(title: store.t("What happened before", "之前發生了甚麼")); Text(record.context) } }
                        if !record.helped.isEmpty { Card { SectionHeading(title: store.t("What helped", "有幫助的方法")); Text(record.helped) } }
                        let related = store.data.related(to: record)
                        if !related.isEmpty {
                            SectionHeading(title: store.t("Earlier moments in this category", "同類別的過往記錄"))
                            Text(store.t("Grouped by your chosen category, not an inferred connection.", "按你選擇的類別分組，並非推斷因果關係。"))
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(related) { earlier in RecordCard(record: earlier) }
                        }
                        Button(store.t("Delete record", "刪除記錄"), role: .destructive) { deleting = true }
                    }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
                }.background(Brand.background)
                    .toolbar { Button(store.t("Edit", "編輯")) { editing = true } }
                    .sheet(isPresented: $editing) { NavigationStack { RecordEditor(existing: record) } }
            }
        }
        .navigationTitle(store.t("Moment details", "記錄詳情")).navigationBarTitleDisplayMode(.inline)
        .alert(store.t("Delete this record?", "刪除此記錄？"), isPresented: $deleting) {
            Button(store.t("Cancel", "取消"), role: .cancel) { }
            Button(store.t("Delete", "刪除"), role: .destructive) { store.deleteRecord(recordID); if !store.data.records.contains(where: { $0.id == recordID }) { dismiss() } }
        } message: { Text(store.t("This cannot be undone.", "此操作無法復原。")) }
    }
}

struct RecordEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var existing: BehaviorRecord?
    @State private var record = BehaviorRecord(text: "")
    @StateObject private var speech = SpeechRecorder()
    @State private var beforeSpeech = ""
    @State private var duration = ""
    @State private var confirmDiscard = false
    private var valid: Bool {
        !record.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (duration.isEmpty || (Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false))
    }
    var body: some View {
        Form {
            Section {
                TextField(store.t("What did you notice?", "你留意到甚麼？"), text: $record.text, axis: .vertical).lineLimit(5...12).accessibilityIdentifier("recordText")
                Button {
                    if speech.isRecording { speech.stop() }
                    else {
                        beforeSpeech = record.text
                        Task { await speech.start(language: store.language) }
                    }
                } label: {
                    Label(speech.isRecording ? store.t("Stop · \(speech.seconds)s", "停止・\(speech.seconds)秒") : store.t("Use voice · up to 60 seconds", "語音輸入・最多 60 秒"), systemImage: speech.isRecording ? "stop.circle.fill" : "mic.fill")
                        .foregroundStyle(speech.isRecording ? .red : Brand.blue)
                }.disabled(speech.isStarting)
                if let message = speech.error { Text(message).font(.caption).foregroundStyle(.secondary) }
            } header: { Text(store.t("A moment worth remembering", "值得記下的片段")) }
            footer: { Text(store.t("Voice transcription runs on supported devices using Apple’s on-device speech recognition. Review the text before saving. Audio is not saved.", "語音轉文字使用 Apple 裝置端辨識，需裝置支援。儲存前請檢查文字，錄音不會被保留。")) }
            Section(store.t("Details", "詳情")) {
                Picker(store.t("Category", "類別"), selection: $record.category) { ForEach(RecordCategory.allCases) { c in Text(c.title(store.language)).tag(c) } }
                DatePicker(store.t("When", "時間"), selection: $record.date, in: ...Date())
                TextField(store.t("Place (optional)", "地點（選填）"), text: $record.location)
                TextField(store.t("Duration in minutes (optional)", "持續分鐘（選填）"), text: $duration).keyboardType(.numberPad)
                if !duration.isEmpty && !(Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false) {
                    Text(store.t("Enter a whole number from 0 to 1440.", "請輸入 0 至 1440 的整數。" )).foregroundStyle(.red).font(.caption)
                }
            }
            Section(store.t("A little more context (optional)", "補充情況（選填）")) {
                TextField(store.t("What happened before?", "之前發生了甚麼？"), text: $record.context, axis: .vertical).lineLimit(2...5)
                TextField(store.t("What helped?", "甚麼方法有幫助？"), text: $record.helped, axis: .vertical).lineLimit(2...5)
            }
        }
        .navigationTitle(store.t(existing == nil ? "Capture a moment" : "Edit moment", existing == nil ? "記下這一刻" : "編輯記錄"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(store.t("Cancel", "取消")) { speech.stop(); confirmDiscard = true } }
            ToolbarItem(placement: .confirmationAction) {
                Button(store.t("Save", "儲存")) {
                    speech.stop()
                    record.text = record.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    record.durationMinutes = Int(duration)
                    if store.saveRecord(record) { dismiss() }
                }.bold().disabled(!valid || speech.isRecording || speech.isStarting).accessibilityIdentifier("saveRecord")
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(store.t("Discard this draft?", "放棄此草稿？"), isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button(store.t("Discard", "放棄"), role: .destructive) { dismiss() }
            Button(store.t("Keep editing", "繼續編輯"), role: .cancel) { }
        }
        .onAppear { if let existing { record = existing; duration = existing.durationMinutes.map(String.init) ?? "" } }
        .onChange(of: speech.transcript) { _, value in record.text = beforeSpeech + (beforeSpeech.isEmpty ? "" : "\n") + value }
        .onChange(of: scenePhase) { _, phase in if phase != .active { speech.stop() } }
        .onDisappear { speech.stop() }
    }
}

// MARK: - CareVoice/Features/ReportsAndProfile.swift

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @State private var professional = false
    @State private var export: ExportFile?
    @State private var lastURL: URL?
    private var report: String { ReportBuilder.text(data: store.data, questions: store.questions, professional: professional) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(store.t("Make the conversation easier.", "讓溝通更容易。"))
                    .font(.system(.title, design: .rounded).bold())
                Picker(store.t("Report format", "報告格式"), selection: $professional) {
                    Text(store.t("Family", "家庭版")).tag(false)
                    Text(store.t("Appointment", "會面版")).tag(true)
                }.pickerStyle(.segmented)
                Text(store.t("Review your report before sharing. It contains your child’s observations and will leave this device only through the destination you choose.", "分享前請檢查報告，當中包含孩子的觀察記錄。報告只會透過你選擇的方式分享。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                PrimaryButton(title: store.t("Share PDF report", "分享 PDF 報告"), symbol: "square.and.arrow.up") {
                    do {
                        let url = try PDFReport.make(text: report)
                        lastURL = url; export = ExportFile(url: url)
                    } catch { store.errorMessage = store.t("The report could not be created. Please try again.", "未能建立報告，請再試。") }
                }.accessibilityIdentifier("shareReport")
                Card { Text(report).font(.subheadline).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Reports", "報告")).navigationBarTitleDisplayMode(.inline)
            .sheet(item: $export, onDismiss: cleanup) { item in ShareSheet(url: item.url) }
    }
    private func cleanup() { if let lastURL { try? FileManager.default.removeItem(at: lastURL) }; lastURL = nil }
}

struct ExportFile: Identifiable { let id = UUID(); let url: URL }

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

@MainActor
enum PDFReport {
    static func make(text: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-\(UUID().uuidString).pdf")
        let style = NSMutableParagraphStyle(); style.lineSpacing = 5; style.paragraphSpacing = 8
        let attributed = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black, .paragraphStyle: style])
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let bytes = renderer.pdfData { context in
            var offset = 0
            var page = 1
            while offset < attributed.length {
                context.beginPage()
                let cg = context.cgContext
                cg.saveGState()
                cg.textMatrix = .identity
                cg.translateBy(x: 0, y: bounds.height)
                cg.scaleBy(x: 1, y: -1)
                let path = CGPath(rect: CGRect(x: 42, y: 50, width: 511, height: 750), transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
                CTFrameDraw(frame, cg)
                let visible = CTFrameGetVisibleStringRange(frame)
                cg.restoreGState()
                ("CareVoice · \(page)" as NSString).draw(at: CGPoint(x: 42, y: 812), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
                guard visible.length > 0 else { break }
                offset += visible.length; page += 1
            }
        }
        try bytes.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing = false

    var body: some View {
        List {
            if let p = store.data.profile {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 48)).foregroundStyle(Brand.blue)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(p.displayName(store.language)).font(.headline)
                            if let birthday = p.birthDate { Text(birthday, style: .date).font(.subheadline).foregroundStyle(.secondary) }
                            Text(p.age(store.language)).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 10).listRowBackground(Brand.blue.opacity(0.08))
                    Button(store.t("Edit profile", "編輯檔案")) { editing = true }
                    LabeledContent(store.t("Current stage", "目前階段")) { Text(p.stage.title(store.language)).multilineTextAlignment(.trailing) }
                }
            }
            Section(store.t("Your care tools", "你的照顧工具")) {
                NavigationLink(store.t("Observation questionnaire", "情況問卷")) { QuestionnaireView() }
                NavigationLink(store.t("Reports", "報告")) { ReportsView() }
            }
        }
        .navigationTitle(store.t("Profile", "我的檔案"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(store.t("Settings", "設定"))
                .accessibilityIdentifier("openSettings")
            }
        }
        .sheet(isPresented: $editing) { NavigationStack { ProfileEditor() } }
    }
}


// Hallmark · pre-emit critique: P4 H5 E4 S5 R5 V4
// Shared settings layout: native type sizing, semantic surfaces, existing brand blue.
enum SettingsPage: String, CaseIterable, Identifiable {
    case preferences, security, community, data, notifications, help
    case privacy, guidelines, terms, about
    var id: String { rawValue }
    static let main: [Self] = [.preferences, .security, .community, .data, .notifications, .help]
    static let footer: [Self] = [.privacy, .guidelines, .terms, .about]
    var title: (String, String) {
        switch self {
        case .preferences: return ("Account preferences", "帳戶偏好")
        case .security: return ("Sign-in & security", "登入與安全")
        case .community: return ("Community privacy", "社區私隱")
        case .data: return ("Data & privacy", "資料與私隱")
        case .notifications: return ("Notifications", "通知")
        case .help: return ("Help & support", "幫助與支援")
        case .privacy: return ("Privacy Policy", "私隱政策")
        case .guidelines: return ("Community Guidelines", "社區守則")
        case .terms: return ("Terms", "使用條款")
        case .about: return ("About CareVoice", "關於 CareVoice")
        }
    }
    var icon: String {
        switch self {
        case .preferences: return "person.crop.circle"
        case .security: return "lock"
        case .community: return "eye"
        case .data, .privacy: return "hand.raised"
        case .notifications: return "bell"
        case .help: return "questionmark.bubble"
        case .guidelines: return "person.2"
        case .terms: return "doc.text"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 48)).foregroundStyle(Brand.blue)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.t("Settings", "設定")).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        if let name = store.data.caregiverName, !name.isEmpty {
                            Text(name).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }.padding(.top, 8).padding(.bottom, 8)
                VStack(spacing: 0) {
                    ForEach(SettingsPage.main) { page in
                        NavigationLink { SettingsDetailView(page: page) } label: {
                            HStack(spacing: 18) {
                                Image(systemName: page.icon).font(.title2).foregroundStyle(Brand.blue)
                                    .frame(width: 30).accessibilityHidden(true)
                                Text(store.t(page.title.0, page.title.1)).font(.body.weight(.medium))
                                    .foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary).accessibilityHidden(true)
                            }.frame(minHeight: 72).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("settings-" + page.rawValue)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(SettingsPage.footer) { page in
                        NavigationLink { SettingsDetailView(page: page) } label: {
                            Text(store.t(page.title.0, page.title.1)).font(.subheadline)
                                .foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(.horizontal, 24).padding(.bottom, 28)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsDetailView(page: .help) } label: {
                    Image(systemName: "questionmark.bubble").frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel(store.t("Help & support", "幫助與支援"))
            }
        }
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject var store: AppStore
    let page: SettingsPage
    var body: some View {
        Group {
            switch page {
            case .preferences: AccountPreferencesView()
            case .data: SettingsDataView()
            default: SettingsInformationView(page: page)
            }
        }.navigationTitle(store.t(page.title.0, page.title.1)).navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountPreferencesView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var editingChild = false
    @State private var saved = false
    var body: some View {
        Form {
            Section {
                TextField(store.t("Your display name", "你的顯示名稱"), text: $name)
                    .textContentType(.nickname).accessibilityIdentifier("caregiverName")
                    .onChange(of: name) { _, _ in saved = false }
                Button(store.t("Save name", "儲存名稱")) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if store.update({ $0.caregiverName = trimmed.isEmpty ? nil : trimmed }) { saved = true }
                }.accessibilityIdentifier("saveCaregiverName")
                if saved { Label(store.t("Saved on this device", "已儲存於此裝置"), systemImage: "checkmark.circle").foregroundStyle(Brand.teal) }
            } header: { Text(store.t("Your profile", "你的檔案")) }
            footer: { Text(store.t("A nickname is enough. This name is not published to the community.", "使用暱稱即可。此名稱不會公開至社區。")) }
            Section(store.t("Your child", "你的孩子")) {
                if let profile = store.data.profile {
                    LabeledContent(store.t("Nickname", "暱稱"), value: profile.displayName(store.language))
                }
                Button(store.t("Edit child details", "編輯孩子資料")) { editingChild = true }
            }
            Section(store.t("Language", "語言")) {
                Picker(store.t("App language", "應用程式語言"), selection: Binding(get: { store.language }, set: { store.setLanguage($0) })) {
                    Text("English").tag(AppLanguage.english)
                    Text("繁體中文").tag(AppLanguage.traditionalChinese)
                }.accessibilityIdentifier("languagePicker")
            }
        }.onAppear { name = store.data.caregiverName ?? "" }
            .sheet(isPresented: $editingChild) { NavigationStack { ProfileEditor() } }
    }
}

struct SettingsDataView: View {
    @EnvironmentObject var store: AppStore
    @State private var deleting = false
    @State private var export: ExportFile?
    @State private var exportURL: URL?
    var body: some View {
        List {
            Section(store.t("Your records", "你的記錄")) {
                NavigationLink(store.t("View and share a PDF report", "檢視及分享 PDF 報告")) { ReportsView() }
                Button(store.t("Export all local data", "匯出所有本機資料")) { exportData() }
                    .accessibilityIdentifier("exportLocalData")
                Text(store.t("The export includes your profile, observations and questionnaire answers. Choose where to save or share it.", "匯出內容包含檔案、觀察及問卷答案。請自行選擇儲存或分享位置。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            NativeBackupControls()
            Section(store.t("AI sharing", "與 AI 分享")) {
                Label(store.t("AI is not connected", "AI 尚未連接"), systemImage: "lock.shield")
                Text(store.t("Questions and records are not sent to an AI service. Sharing controls will be available when the service is connected.", "問題及記錄不會傳送至 AI 服務。連接服務後才會提供分享控制。"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section(store.t("Device storage", "裝置儲存")) {
                Text(store.t("Records use iOS file protection and are excluded from device backups. Deleting the app or losing this device may lose your records. Export a copy you want to keep.", "記錄使用 iOS 檔案保護，並不包含於裝置備份。刪除應用程式或遺失裝置可能導致記錄遺失。請匯出需要保留的副本。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                Button(store.t("Delete all local data", "刪除所有本機資料"), role: .destructive) { deleting = true }
                    .accessibilityIdentifier("deleteLocalData")
            }
        }
        .sheet(item: $export, onDismiss: cleanupExport) { file in ShareSheet(url: file.url) }
        .alert(store.t("Delete all local data?", "刪除所有本機資料？"), isPresented: $deleting) {
            Button(store.t("Cancel", "取消"), role: .cancel) {}
            Button(store.t("Delete everything", "全部刪除"), role: .destructive) { store.erase() }
        } message: {
            Text(store.t("Your profiles, records and answers will be removed from this app. This cannot be undone. Copies you already shared are not deleted.", "你的檔案、記錄和答案將從此應用程式移除，無法復原。已分享的副本不會被刪除。"))
        }
    }
    private func exportData() {
        do {
            cleanupExport()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-data-\(UUID().uuidString).json")
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(store.data).write(to: url, options: [.atomic, .completeFileProtection])
            exportURL = url; export = ExportFile(url: url)
        } catch { store.errorMessage = store.t("Your data could not be exported. Please try again.", "未能匯出資料，請再試。") }
    }
    private func cleanupExport() {
        if let exportURL { try? FileManager.default.removeItem(at: exportURL) }
        exportURL = nil
    }
}

struct SettingsInformationView: View {
    @EnvironmentObject var store: AppStore
    let page: SettingsPage
    private func paragraph(_ title: String, _ zhTitle: String, _ body: String, _ zhBody: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.t(title, zhTitle)).font(.headline).accessibilityAddTraits(.isHeader)
            Text(store.t(body, zhBody)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: page.icon).font(.system(size: 32)).foregroundStyle(Brand.blue).accessibilityHidden(true)
                switch page {
                case .security:
                    paragraph("Your account", "你的帳戶", "This version works on your device without an online account. Email, password changes, sign-out and account deletion will become available when sign-in is connected.", "此版本無須網上帳戶即可在裝置上使用。連接登入服務後，才可管理電郵、密碼、登出及刪除帳戶。")
                    NavigationLink(store.t("Manage local data", "管理本機資料")) { SettingsDetailView(page: .data) }
                case .community:
                    paragraph("Private for now", "目前保持私人", "Community posts are local drafts. They are not published, and there is no public profile or member directory yet.", "社區帖子目前只屬本機草稿，尚未發佈，亦未提供公開檔案或成員目錄。")
                    paragraph("When community sharing is connected", "連接社區分享後", "You will be able to choose a public display name, control profile visibility and block other users. These controls are not active yet.", "你將可選擇公開顯示名稱、控制檔案可見度及封鎖其他用戶。目前尚未啟用這些控制。")
                case .notifications:
                    paragraph("No notifications are scheduled", "尚未安排通知", "Recording reminders, community replies and service updates are not connected in this version. CareVoice has not enabled these alerts.", "此版本尚未連接記錄提醒、社區回覆及服務更新。CareVoice 尚未啟用這些通知。")
                case .help:
                    paragraph("How do I edit my child's details?", "如何編輯孩子資料？", "Open Account preferences, then Edit child details. Save your changes before returning.", "開啟帳戶偏好，再點選編輯孩子資料。返回前請儲存變更。")
                    paragraph("How do I keep a copy of my records?", "如何保留記錄副本？", "Open Data & privacy to export your local data or share a PDF report.", "開啟資料與私隱，即可匯出本機資料或分享 PDF 報告。")
                    paragraph("Can I ask the AI or publish a post?", "可以提問 AI 或發佈帖子嗎？", "These services are not connected yet. You can browse Phase 1 resources and prepare a private community draft.", "這些服務尚未連接。你可瀏覽第一階段資源及撰寫私人社區草稿。")
                    paragraph("Contact support / report a problem", "聯絡支援／回報問題", "A support contact has not been configured. For this review build, share the steps to reproduce the problem with the person who provided the app. Avoid including your child's records.", "尚未設定支援聯絡方式。使用此審閱版本時，請向提供應用程式的人說明問題的重現步驟，避免附上孩子的記錄。")
                case .privacy:
                    paragraph("Current data handling", "目前的資料處理", "Profiles, observations and answers are saved locally with iOS file protection. There is no analytics, advertising or cloud sync in this build. AI questions are not sent to a server.", "檔案、觀察及答案儲存於本機，並使用 iOS 檔案保護。此版本沒有分析追蹤、廣告或雲端同步。AI 問題不會傳送至伺服器。")
                    paragraph("Sharing and external links", "分享及外部連結", "Reports and exports leave this device through the destination you choose. Opening an official resource visits an external website with its own privacy practices.", "報告及匯出資料只會透過你選擇的目的地離開裝置。開啟官方資源會前往外部網站，該網站有其私隱安排。")
                    paragraph("Policy publication pending", "私隱政策待發佈", "This describes the current review build. A published privacy policy and operator contact must be added before online accounts or community sharing launch.", "以上說明適用於目前的審閱版本。推出網上帳戶或社區分享前，須加入已發佈的私隱政策及營運者聯絡方式。")
                case .guidelines:
                    paragraph("Community guidelines — draft", "社區守則 — 草稿", "Be kind to other caregivers. Share your own experience without identifying another child or family. Peer stories should not be presented as a diagnosis or professional advice.", "請友善對待其他照顧者。分享自身經驗時，避免披露其他孩子或家庭的身份。個人經驗不應當作診斷或專業意見。")
                    paragraph("Before public posting opens", "開放公開發帖前", "The final guidelines, reporting process and moderation arrangements still need to be published. Public posting is currently unavailable.", "最終守則、舉報流程及審核安排仍待發佈。目前尚未提供公開發帖。")
                case .terms:
                    paragraph("Terms are not published yet", "使用條款尚未發佈", "This is a review build. Final service terms and the operator's contact details must be added before account and community services launch. No terms acceptance is collected on this page.", "此為審閱版本。推出帳戶及社區服務前，須加入最終服務條款及營運者聯絡資料。本頁不會收集條款同意。")
                case .about:
                    paragraph("CareVoice", "CareVoice", "A place to record everyday observations, prepare for conversations and find service information while caring for your child.", "照顧孩子時，記錄日常觀察、準備溝通內容及尋找服務資訊的地方。")
                    paragraph("Our role", "我們的角色", "CareVoice does not diagnose, screen for ASD, infer severity or replace professional advice.", "CareVoice 不提供診斷、自閉症篩查或嚴重程度判斷，亦不取代專業意見。")
                    Text(store.t("Version", "版本") + " " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                        .font(.footnote).foregroundStyle(.secondary)
                default: EmptyView()
                }
            }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(Brand.background)
    }
}


// MARK: - CareVoice/Features/Resources.swift

struct OfficialResource: Identifiable {
    let id: String
    let titleEN: String
    let titleZH: String
    let detailEN: String
    let detailZH: String
    let url: String
    let icon: String
    static let all = [
        OfficialResource(id: "first", titleEN: "Where to start", titleZH: "從哪裡開始", detailEN: "CAS guidance on discussing developmental concerns with your MCHC or family doctor.", detailZH: "兒童體能智力測驗服務指引：向母嬰健康院或家庭醫生提出發展方面的疑問。", url: "https://www.dhcas.gov.hk/en/faq.html", icon: "bubble.left.and.bubble.right"),
        OfficialResource(id: "appointment", titleEN: "Assessment appointments", titleZH: "評估預約", detailEN: "Department of Health guidance on registration after receiving a referral letter.", detailZH: "衛生署就取得轉介信後辦理登記的安排。", url: "https://www.dhcas.gov.hk/en/registration_appointment.html", icon: "calendar"),
        OfficialResource(id: "services", titleEN: "Pre-school service pathways", titleZH: "學前服務路徑", detailEN: "Read about follow-up and referral options with your assessment team.", detailZH: "與評估團隊了解跟進安排及轉介服務選項。", url: "https://www.dhcas.gov.hk/en/management_referral.html", icon: "point.topleft.down.to.point.bottomright.curvepath"),
        OfficialResource(id: "referral", titleEN: "Central referral system", titleZH: "康復服務中央轉介系統", detailEN: "SWD information for service referrals. Discuss registration with an authorised referring professional.", detailZH: "社署服務轉介資訊。請與獲授權的轉介專業人士商討登記。", url: "https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/centralref/", icon: "doc.text"),
        OfficialResource(id: "support", titleEN: "On-site pre-school support", titleZH: "到校學前支援", detailEN: "Official information about on-site pre-school rehabilitation services.", detailZH: "到校學前康復服務的官方資訊。", url: "https://www.swd.gov.hk/oprs/index_en.htm", icon: "building.2")
    ]
}

struct ResourcesView: View {
    @EnvironmentObject var store: AppStore
    @State private var section = 0
    @State private var topic = "first"
    @State private var question = ""
    @State private var submittedQuestion: String?
    @State private var composing = false
    @State private var postTitle = ""
    @State private var postBody = ""
    @State private var draftSaved = false
    @FocusState private var typing: Bool

    private var relevantResources: [OfficialResource] {
        // Explicit topic selection, not AI matching or clinical suitability scoring.
        let ids: [String]
        switch topic {
        case "appointment": ids = ["appointment", "first"]
        case "referral": ids = ["referral", "support"]
        default: ids = ["first", "services"]
        }
        return OfficialResource.all.filter { ids.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(store.t("Community section", "社區分類"), selection: $section) {
                Text(store.t("Ask CareVoice", "問 CareVoice")).tag(0)
                Text(store.t("Resources", "資源")).tag(1)
                Text(store.t("Parents", "家長交流")).tag(2)
            }.pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if section == 0 { askContent }
                    else if section == 1 {
                        Text(store.t("Official resources", "官方資源")).font(.title2.bold())
                        Text(store.t("Browse service information from the Department of Health and Social Welfare Department.", "瀏覽衛生署及社會福利署嘅服務資料。"))
                            .font(.subheadline).foregroundStyle(.secondary)
                        NavigationLink { ServiceTypesView() } label: { Label(store.t("Service types", "服務種類"), systemImage: "square.grid.2x2").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { ServiceDirectoryView() } label: { Label(store.t("Find a centre · waiting times", "尋找中心・輪候時間"), systemImage: "mappin.and.ellipse").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { GlossaryView() } label: { Label(store.t("Glossary", "術語對照"), systemImage: "character.book.closed").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { CitableFactsView() } label: { Label(store.t("Cited information", "可引用資料"), systemImage: "checkmark.seal").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        ForEach(OfficialResource.all) { resource in ResourceCard(resource: resource) }
                        sourceNote
                    } else { parentsContent }
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.scrollDismissesKeyboard(.interactively)
            if section == 0 { composer }
        }
        .background(Brand.background)
        .navigationTitle(store.t("Community", "社區"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $composing) { postComposer }
    }

    private var askContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill").font(.title2).foregroundStyle(Brand.blue)
                    .frame(width: 52, height: 52).background(Brand.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.t("A little help, one question at a time.", "一個問題，一齊搵方向。")).font(.headline)
                    Text(store.t("AI connection pending", "AI 尚未連接")).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(store.t("What would you like help with today?", "今日想了解邊方面？")).font(.title2.bold())
            Text(store.t("Choose a topic to browse official links, or try writing your question below. No question is sent while AI is disconnected.", "揀主題瀏覽官方連結，或者喺下面試寫問題。AI 未連接前，問題唔會傳送。"))
                .font(.subheadline).foregroundStyle(.secondary)
            VStack(spacing: 10) {
                topicButton("first", "Understanding my child’s needs", "了解小朋友嘅需要", "heart", .blue)
                topicButton("appointment", "Finding assessment services", "尋找評估服務", "stethoscope", .purple)
                topicButton("referral", "Support while waiting", "輪候期間嘅支援", "clock", .orange)
            }
            if let submittedQuestion {
                HStack { Spacer(minLength: 32); Text(submittedQuestion).padding(16).background(Brand.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20)) }
                Card {
                    Label(store.t("Not sent", "未傳送"), systemImage: "wifi.slash").font(.subheadline.bold())
                    Text(store.t("CareVoice AI is not connected yet. These links are selected by your topic, not an analysis of your situation.", "CareVoice AI 尚未連接。以下連結按你揀嘅主題顯示，並非對你情況嘅分析。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button(store.t("Clear question", "清除問題")) { self.submittedQuestion = nil }
                }
            }
            HStack { Text(store.t("Resources for this topic", "呢個主題嘅資源")).font(.headline); Spacer(); Image(systemName: "checkmark.shield").foregroundStyle(Brand.blue) }
            ForEach(relevantResources) { resource in ResourceCard(resource: resource) }
            sourceNote
            Text(store.t("Clinic matching will need verified location, service and referral data. CareVoice does not diagnose or confirm clinic availability.", "配對診所需要已核實嘅地區、服務同轉介資料。CareVoice 唔會診斷或確認診所名額。"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func topicButton(_ id: String, _ en: String, _ zh: String, _ symbol: String, _ color: Color) -> some View {
        Button { topic = id } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 24).foregroundStyle(Brand.blue)
                Text(store.t(en, zh)).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: topic == id ? "checkmark.circle.fill" : "circle").foregroundStyle(topic == id ? Brand.blue : Color.secondary)
            }.padding(16).frame(minHeight: 56).background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(topic == id ? Brand.blue : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain).accessibilityAddTraits(topic == id ? .isSelected : [])
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(store.t("Describe what’s happening…", "講吓你遇到嘅情況…"), text: $question, axis: .vertical)
                .lineLimit(1...4).focused($typing).padding(14)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                .onChange(of: question) { question = String($0.prefix(2000)) }
            Button {
                submittedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
                question = ""; typing = false
            } label: {
                Image(systemName: "arrow.up").font(.headline).foregroundStyle(.white)
                    .frame(width: 48, height: 48).background(Brand.blue, in: Circle())
            }.disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(store.t("Preview question locally", "本機預覽問題"))
        }.padding(16).background(.bar)
    }

    private var parentsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(store.t("You’re not alone in this.", "照顧路上，唔使一個人。")).font(.title2.bold())
            Text(store.t("A space to share questions and everyday experiences with other caregivers.", "同其他照顧者分享問題同日常經驗嘅空間。"))
                .foregroundStyle(.secondary)
            Card {
                Image(systemName: "person.2").font(.largeTitle).foregroundStyle(Brand.blue)
                Text(store.t("Caregiver discussions are coming", "家長交流準備中")).font(.headline)
                Text(store.t("Shared posts and replies are not connected yet. You can prepare a private draft here; it stays in memory for this app session and is not published.", "貼文同回覆尚未連接。你可以先準備私人草稿，只會暫存喺今次使用期間，唔會發布。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                Button(store.t(draftSaved ? "Edit my draft" : "Prepare a question", draftSaved ? "編輯草稿" : "準備一個問題")) { composing = true }
                    .buttonStyle(.borderedProminent)
            }
            if draftSaved {
                Card {
                    Label(store.t("Private draft · not published", "私人草稿・未發布"), systemImage: "lock").font(.caption).foregroundStyle(.secondary)
                    Text(postTitle).font(.headline)
                    Text(postBody).font(.subheadline)
                    Button(store.t("Discard draft", "刪除草稿"), role: .destructive) { postTitle = ""; postBody = ""; draftSaved = false }
                }
            }
            Card {
                Label(store.t("Caregiver experiences · Phase 2", "照顧者經驗・第二階段"), systemImage: "heart.text.square").font(.headline)
                Text(store.t("Later, CareVoice can surface relevant, consented and anonymised experiences. Peer stories will be labelled separately from official guidance. No experience matching is active yet.", "之後 CareVoice 可展示相關、已獲同意同匿名處理嘅經驗。家長故事會同官方指引分開標示，目前未啟用經驗配對。"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var postComposer: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(store.t("Question title", "問題標題"), text: $postTitle).onChange(of: postTitle) { postTitle = String($0.prefix(120)) }
                    TextField(store.t("What would you like to share?", "你想分享啲咩？"), text: $postBody, axis: .vertical).lineLimit(6...12)
                        .onChange(of: postBody) { postBody = String($0.prefix(3000)) }
                } footer: { Text(store.t("Leave out names, school details, phone numbers and medical documents. This draft is not published or saved after the app closes.", "請勿加入姓名、學校、電話或醫療文件。草稿唔會發布，關閉程式後亦唔會保留。")) }
            }.navigationTitle(store.t("Private draft", "私人草稿")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(store.t("Close", "關閉")) { composing = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(store.t("Keep draft", "保留草稿")) { draftSaved = true; composing = false }
                            .disabled(postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
    private var sourceNote: some View {
        Text(store.t("Official links open in your browser. Confirm eligibility, referral requirements and availability with the service provider.", "官方連結會喺瀏覽器開啟。資格、轉介要求同名額請向服務機構確認。"))
            .font(.caption).foregroundStyle(.secondary)
    }
}


struct ResourceCard: View {
    @EnvironmentObject var store: AppStore
    let resource: OfficialResource
    var body: some View {
        Link(destination: URL(string: resource.url)!) {
            Card {
                HStack {
                    Image(systemName: resource.icon).foregroundStyle(Brand.blue).font(.title2)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                }
                Text(store.t(resource.titleEN, resource.titleZH)).font(.headline).foregroundStyle(.primary)
                Text(store.t(resource.detailEN, resource.detailZH)).font(.subheadline).foregroundStyle(.secondary)
                Text(resource.url.contains("dhcas") ? store.t("DEPARTMENT OF HEALTH", "衛生署") : store.t("SOCIAL WELFARE DEPARTMENT", "社會福利署"))
                    .font(.caption2.weight(.semibold)).tracking(0.7).foregroundStyle(Brand.teal)
            }
        }.buttonStyle(.plain)
    }
}

struct NavigatorView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let profile = store.data.profile {
                    Card {
                        Label(store.t("YOUR CURRENT STAGE", "目前階段"), systemImage: "safari").font(.caption.weight(.bold)).foregroundStyle(Brand.teal)
                        Text(profile.stage.title(store.language)).font(.title2.bold())
                        Text(profile.stage.nextStep(store.language)).foregroundStyle(.secondary)
                        Button(store.t("Update my stage", "更新目前階段")) { editing = true }
                    }
                    SectionHeading(title: store.t("A manageable next step", "一步一步來"))
                    ForEach(Array(steps(profile.stage).enumerated()), id: \.offset) { i, title in
                        let key = "\(profile.stage.rawValue)-\(i)"
                        let done = store.data.completedSteps.contains(key)
                        Button { store.update { if done { $0.completedSteps.remove(key) } else { $0.completedSteps.insert(key) } } } label: {
                            Card {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: done ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(done ? Brand.teal : .secondary)
                                    Text(title).foregroundStyle(.primary).strikethrough(done).multilineTextAlignment(.leading)
                                }
                            }
                        }.buttonStyle(.plain).accessibilityValue(done ? store.t("Completed", "已完成") : store.t("Not completed", "尚未完成"))
                    }
                    Text(store.t("This is your personal checklist. Ticking a step does not register you for a service or change an official waiting list.", "這是你的個人清單。勾選項目不代表已登記服務，亦不會更改官方輪候狀況。"))
                        .font(.caption).foregroundStyle(.secondary)
                    SectionHeading(title: store.t("Official guidance", "官方指引"))
                    ResourceCard(resource: OfficialResource.all[profile.stage == .noticed || profile.stage == .professionalFollowUp ? 0 : profile.stage == .awaitingAssessment ? 1 : 3])
                    NavigationLink(store.t("See all resources", "查看所有資源")) { ResourcesView() }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Your next step", "下一步")).navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { NavigationStack { ProfileEditor() } }
    }
    private func steps(_ stage: JourneyStage) -> [String] {
        let l = store.language
        switch stage {
        case .noticed, .professionalFollowUp: return [l.text("Write down the changes you have noticed", "記下你留意到的變化"), l.text("Arrange a conversation with your doctor or MCHC", "安排與醫生或母嬰健康院討論"), l.text("Bring your questions and observations", "準備希望詢問的問題和觀察記錄")]
        case .awaitingAssessment: return [l.text("Confirm registration and appointment arrangements with your centre", "向中心確認登記及預約安排"), l.text("Check which documents the centre asks you to bring", "確認中心要求攜帶哪些文件"), l.text("Prepare an observation report", "準備觀察記錄報告")]
        case .assessed, .diagnosed: return [l.text("Discuss your report with the assessment team", "與評估團隊討論報告"), l.text("Ask your referring professional about suitable services", "向轉介專業人士了解合適的服務"), l.text("Confirm the referral steps and required documents", "確認轉介步驟及所需文件")]
        case .receivingServices: return [l.text("Keep your service team’s details", "保留服務團隊聯絡資料"), l.text("Prepare questions for your next appointment", "準備下次會面嘅問題"), l.text("Keep recording everyday observations", "繼續記錄日常觀察")]
        case .registered, .waitingSupport: return [l.text("Keep your referring professional’s contact details", "保留轉介專業人士的聯絡資料"), l.text("Ask about support while waiting", "了解輪候期間的支援"), l.text("Continue recording everyday observations", "繼續記錄日常觀察")]
        }
    }
}

// MARK: - review/CareVoiceSurveyReview.swift

// CareVoice web survey → standalone SwiftUI review, iOS 16+.
// Add this file to an iOS target and open the preview below.
// Usage: CareVoiceSurveyReview { answer in /* persist answer, then route */ }
// onComplete supplies the answers; this preview does not persist personal data.
// Route noticed to the optional questionnaire; other stages to Home.
// Integrated below through CompleteWelcomeView into the native ChildProfile model.
// Phase 1 pathway reference: content fingerprint 0ae157aa8e0a22c8.

struct CareVoiceSurveyAnswer: Codable {
    var nickname: String
    var birthDate: Date
    var stage: String
    var supportGoals: [String]
    var notes: String
    var ageMonths: Int {
        Calendar.current.dateComponents([.month], from: Calendar.current.startOfDay(for: birthDate), to: Calendar.current.startOfDay(for: Date())).month ?? 0
    }
    var shouldOfferQuestionnaire: Bool { stage == "noticed" }
}

struct CareVoiceSurveyReview: View {
    var chinese = false
    var onClose: () -> Void = {}
    var onComplete: (CareVoiceSurveyAnswer) -> Void
    @State private var step = 0
    @State private var nickname = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
    @State private var birthdayChosen = false
    @State private var birthDay = 0
    @State private var birthMonth = 0
    @State private var birthYear = 0
    @State private var stage: String?
    @State private var goals: Set<String> = []
    @State private var notes = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    private let blue = Color(red: 0.082, green: 0.396, blue: 0.753)
    private let pastels: [Color] = [Color(red: 0.89, green: 0.95, blue: 0.99), Color(red: 0.90, green: 0.96, blue: 0.91), Color(red: 1, green: 0.96, blue: 0.88), Color(red: 0.98, green: 0.90, blue: 0.93), Color(red: 0.93, green: 0.90, blue: 0.97)]
    private let stages: [(String, String, String, String)] = [
        ("noticed", "Noticing differences", "留意到不同", "magnifyingglass"),
        ("professionalFollowUp", "Seeking a referral", "尋求專業轉介", "bubble.left"),
        ("awaitingAssessment", "Awaiting assessment", "等候評估", "clock"),
        ("assessed", "Assessment completed", "已完成評估", "doc.text"),
        ("registered", "Registered in the queue", "已登記中央輪候", "checkmark.clipboard"),
        ("waitingSupport", "Support while waiting", "輪候期間支援", "heart"),
        ("receivingServices", "Allocated a service", "已獲編配服務", "person.2")
    ]
    private let options: [(String, String, String, String)] = [
        ("nextSteps", "Understanding next steps", "了解下一步", "safari"),
        ("documents", "Preparing documents", "準備所需文件", "doc.text"),
        ("services", "Finding services", "尋找服務", "person.2"),
        ("waiting", "Support while waiting", "輪候期間嘅支援", "heart"),
        ("observations", "Recording observations", "記錄日常觀察", "magnifyingglass")
    ]
    private func t(_ en: String, _ zh: String) -> String { chinese ? zh : en }
    private var heading: String {
        [t("What should we call your child?", "點稱呼你嘅小朋友？"),
         t("When is your child’s birthday?", "小朋友嘅生日係幾時？"),
         t("Where are you now?", "你而家去到邊個階段？"),
         t("What would you like help with?", "你想獲得邊方面嘅幫助？"),
         t("Anything you’d like us to know?", "仲有冇想話畀我哋知嘅事？")][step]
    }
    private var dateRange: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: Date())
        let sevenYearsAgo = Calendar.current.date(byAdding: .year, value: -7, to: today)!
        return Calendar.current.date(byAdding: .day, value: 1, to: sevenYearsAgo)!...today
    }
    private var canContinue: Bool { step == 1 ? birthdayChosen : (step == 2 ? stage != nil : true) }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Button { if step > 0 { step -= 1 } else { onClose() } } label: {
                        Image(systemName: "arrow.left").frame(width: 44, height: 44)
                    }.accessibilityLabel(t("Back", "返回"))
                    ProgressView(value: Double(step + 1), total: 5).tint(blue)
                        .accessibilityLabel(t("Setup progress", "設定進度"))
                    Text("\(step + 1) / 5").font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 20).padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(heading).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        question(width: geometry.size.width, height: geometry.size.height)
                    }.padding(24)
                }.id(step)
                VStack(spacing: 8) {
                    if step == 0 || step == 4 {
                        Button(t("Skip", "略過")) {
                            if step == 0 { nickname = ""; step += 1 }
                            else { finish(notes: "") }
                        }.frame(minHeight: 44)
                    }
                    Button(step == 4 ? t("See my next steps", "睇吓下一步") : t("Continue", "繼續")) {
                        if step < 4 { step += 1 } else { finish(notes: notes) }
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(blue.opacity(canContinue ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 14))
                    .disabled(!canContinue)
                }.padding(.horizontal, 24).padding(.bottom, 12)
            }.background(Color(uiColor: .systemBackground)).tint(blue)
        }.environment(\.locale, Locale(identifier: chinese ? "zh_Hant_HK" : "en_HK"))
    }

    @ViewBuilder private func question(width: CGFloat, height: CGFloat) -> some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: 12) {
                Text(t("Nickname (optional)", "暱稱（選填）")).font(.subheadline.bold())
                TextField(t("Your child’s nickname", "小朋友嘅暱稱"), text: $nickname)
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.words)
                    .onChange(of: nickname) { nickname = String($0.prefix(40)) }
            }.padding(24).background(pastels[0], in: RoundedRectangle(cornerRadius: 24))
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                Text(t("Choose their date of birth. We’ll work out their age for you.", "揀出生日期，我哋會自動計算年齡。")).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    birthdayPart(t("Day", "日"), value: $birthDay, values: Array(1...31), color: pastels[0])
                    birthdayPart(t("Month", "月"), value: $birthMonth, values: Array(1...12), color: pastels[2])
                    birthdayPart(t("Year", "年"), value: $birthYear, values: Array(((Calendar.current.component(.year, from: Date()) - 7)...Calendar.current.component(.year, from: Date())).reversed()), color: pastels[4])
                }
                VStack(spacing: 8) {
                    if birthdayChosen {
                        Text(birthday, style: .date).font(.headline)
                        let months = Calendar.current.dateComponents([.month], from: birthday, to: Date()).month ?? 0
                        Text(t("\(months / 12) years · \(months % 12) months old", "\(months / 12) 歲 \(months % 12) 個月")).font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        Text(t(birthDay > 0 && birthMonth > 0 && birthYear > 0 ? "Choose a valid birthday for a child under 7, no later than today." : "Their birthday will appear here", "請選擇未滿七歲小朋友嘅有效生日。")).font(.subheadline).foregroundStyle(.secondary)
                    }
                }.padding(20).frame(maxWidth: .infinity).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary.opacity(0.2)))
            }
        case 2, 3:
            let items = step == 2 ? stages : options
            let count = typeSize.isAccessibilitySize ? 1 : (width >= 400 ? 3 : 2)
            let rows = Int(ceil(Double(items.count) / Double(count)))
            let cardHeight = max(96, (height - 235 - CGFloat(rows - 1) * 12) / CGFloat(rows))
            VStack(alignment: .leading, spacing: 16) {
                if step == 3 { Text(t("Choose any that apply", "可選多項")).font(.subheadline).foregroundStyle(.secondary) }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: count), spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let selected = step == 2 ? stage == item.0 : goals.contains(item.0)
                        Button {
                            if step == 2 { stage = item.0 }
                            else if goals.contains(item.0) { goals.remove(item.0) }
                            else { goals.insert(item.0) }
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: item.3).font(.title3).foregroundStyle(blue)
                                Text(t(item.1, item.2)).font(.subheadline).foregroundStyle(Color.primary)
                                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            }.padding(.horizontal, 10).padding(.top, 28).padding(.bottom, 12)
                            .frame(maxWidth: .infinity, minHeight: cardHeight)
                            .background(pastels[index % pastels.count], in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? blue : Color.secondary.opacity(0.2), lineWidth: selected ? 2 : 1))
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundStyle(selected ? blue : Color.secondary).padding(10)
                            }
                        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                Text(t("Notes (optional)", "補充資料（選填）")).font(.subheadline.bold())
                TextEditor(text: $notes).frame(minHeight: 160).scrollContentBackground(.hidden)
                    .accessibilityLabel(t("Notes", "補充資料"))
                    .onChange(of: notes) { notes = String($0.prefix(4000)) }
            }.padding(20).background(pastels[4], in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func birthdayPart(_ label: String, value: Binding<Int>, values: [Int], color: Color) -> some View {
        VStack(spacing: 12) {
            Text(label).font(.subheadline.bold())
            Picker(label, selection: value) {
                Text("—").tag(0)
                ForEach(values, id: \.self) { number in Text(String(number)).tag(number) }
            }.pickerStyle(.menu).labelsHidden().frame(maxWidth: .infinity, minHeight: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: value.wrappedValue) { _ in validateBirthday() }
        }.padding(10).frame(maxWidth: .infinity).background(color, in: RoundedRectangle(cornerRadius: 20))
    }
    private func validateBirthday() {
        let calendar = Calendar.current
        guard birthDay > 0, birthMonth > 0, birthYear > 0,
              let date = calendar.date(from: DateComponents(year: birthYear, month: birthMonth, day: birthDay)),
              calendar.component(.day, from: date) == birthDay,
              calendar.component(.month, from: date) == birthMonth, dateRange.contains(date) else {
            birthdayChosen = false; return
        }
        birthday = date; birthdayChosen = true
    }

    private func finish(notes: String) {
        guard let stage, birthdayChosen, dateRange.contains(birthday) else { return }
        onComplete(CareVoiceSurveyAnswer(nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), birthDate: birthday, stage: stage, supportGoals: goals.sorted(), notes: notes))
    }
}

struct CareVoiceSurveyReview_Previews: PreviewProvider {
    static var previews: some View {
        CareVoiceSurveyReview { _ in }.previewDisplayName("English")
        CareVoiceSurveyReview(chinese: true) { _ in }.previewDisplayName("繁體中文")
    }
}

enum EmbeddedQuestionnaire {
    static let json = #"""
[
  {
    "id": 1,
    "en": "Does your child make eye contact? When you call his/her name, does he/she look at you?",
    "zh": "你的孩子會眼神接觸嗎？當你叫他/她的名字時，他/她會看著你嗎？",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 2,
    "en": "Does your child smile back or respond to your interactions with a smile?",
    "zh": "你的孩子會主動對你微笑或笑來回應你的互動嗎？",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 3,
    "en": "Does your child notice and show interest in other children? (e.g., watching them play)",
    "zh": "你的孩子會注意到其他小朋友並對他們感興趣嗎？（例如看著他們玩）",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 4,
    "en": "Does your child imitate your actions or facial expressions? (e.g., waving, clapping)",
    "zh": "你的孩子會模仿你的動作或表情嗎？（例如揮手、拍手）",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 5,
    "en": "Does your child show joint attention? (e.g., pointing at something with you, looking at a book together)",
    "zh": "你的孩子會展示共同注意力嗎？（例如跟你一起指著某樣東西、和你一起看圖書）",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 6,
    "en": "When your child wants something, does he/she use eye contact or gestures to get your attention?",
    "zh": "當你的孩子想要東西時，他/她會用眼神或手勢來引起你的注意嗎？",
    "categoryEN": "Social Communication",
    "categoryZH": "社交溝通",
    "yesNo": false
  },
  {
    "id": 7,
    "en": "Does your child babble (meaningful sounds, not just crying)?",
    "zh": "你的孩子會發出牙牙學語的聲音嗎（有意義的聲音，不只是哭鬧）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": true
  },
  {
    "id": 8,
    "en": "Does your child say single words (e.g., \"Mama\", \"car\", \"water\")?",
    "zh": "你的孩子會說單字嗎（例如「媽」、「車」、「水」）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": true
  },
  {
    "id": 9,
    "en": "Can your child combine two words together (e.g., \"want car\", \"mommy hug\")?",
    "zh": "你的孩子能夠將兩個字組合在一起說嗎（例如「要車車」、「媽媽抱」）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": true
  },
  {
    "id": 10,
    "en": "Does your child repeat speech (e.g., TV ad lines, echoing what you say)?",
    "zh": "你的孩子會重複說話嗎（例如重複電視廣告詞、重複你說過的話）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": false
  },
  {
    "id": 11,
    "en": "Can your child express needs with language (e.g., saying \"I want water\" instead of dragging you to the cup)?",
    "zh": "你的孩子能用語言表達他/她的需求嗎（例如說「我要喝水」而不是只是拉你去水壺）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": false
  },
  {
    "id": 12,
    "en": "Can your child understand simple instructions (e.g., \"give me the ball\", \"come here\")?",
    "zh": "你的孩子能夠理解簡單的指示嗎（例如「把球給我」、「過來」）？",
    "categoryEN": "Language Ability",
    "categoryZH": "語言能力",
    "yesNo": false
  },
  {
    "id": 13,
    "en": "Does your child use gestures to communicate (e.g., pointing, waving goodbye, nodding/shaking head)?",
    "zh": "你的孩子會用手勢來溝通嗎（例如指物、揮手表示再見、點頭/搖頭）？",
    "categoryEN": "Gestures & Expression",
    "categoryZH": "手勢與表達",
    "yesNo": false
  },
  {
    "id": 14,
    "en": "When unhappy, does your child use gestures or actions to communicate (e.g., pulling your clothes, guiding you to what they want)?",
    "zh": "當你的孩子不開心時，他/她會用手勢或行動來表達嗎（例如拉你的衣服、把你推到想要的東西前）？",
    "categoryEN": "Gestures & Expression",
    "categoryZH": "手勢與表達",
    "yesNo": false
  },
  {
    "id": 15,
    "en": "Does your child line up toys or objects repeatedly (e.g., by color or size in a row)?",
    "zh": "你的孩子會反覆排列玩具或物品嗎（例如按顏色或大小排成一排）？",
    "categoryEN": "Repetitive Behaviors",
    "categoryZH": "重複行為",
    "yesNo": false
  },
  {
    "id": 16,
    "en": "Does your child have intensely restricted interests (e.g., only playing with one toy, only talking about one topic)?",
    "zh": "你的孩子對某些事物有非常強烈的固執興趣嗎（例如只玩同一個玩具、只談論同一個話題）？",
    "categoryEN": "Repetitive Behaviors",
    "categoryZH": "重複行為",
    "yesNo": false
  },
  {
    "id": 17,
    "en": "Does your child make repetitive body movements (e.g., hand-flapping, spinning, finger flicking)?",
    "zh": "你的孩子會做出重複的身體動作嗎（例如搖手、轉圈、抖動手指）？",
    "categoryEN": "Repetitive Behaviors",
    "categoryZH": "重複行為",
    "yesNo": false
  },
  {
    "id": 18,
    "en": "Does your child struggle with changes in daily routine (e.g., taking a different route home, changed schedule)?",
    "zh": "你的孩子對日常生活的改變感到困難嗎（例如換了一條路回家、改變了日常作息）？",
    "categoryEN": "Repetitive Behaviors",
    "categoryZH": "重複行為",
    "yesNo": false
  },
  {
    "id": 19,
    "en": "Does your child insist on things being done in a certain way (e.g., must take same route, items must be in fixed positions)?",
    "zh": "你的孩子堅持某些事情必須以特定方式進行嗎（例如一定要走同一條路、物品必須放在固定位置）？",
    "categoryEN": "Repetitive Behaviors",
    "categoryZH": "重複行為",
    "yesNo": false
  },
  {
    "id": 20,
    "en": "Does your child overreact to loud noises (e.g., vacuum cleaner, alarm clock causing distress)?",
    "zh": "你的孩子對大聲的聲音有過度反應嗎（例如吸塵器、鬧鐘聲讓他/她不安）？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 21,
    "en": "Does your child reject certain food textures (e.g., only eating soft food, refusing crunchy or pureed food)?",
    "zh": "你的孩子對某些質地的食物特別排斥嗎（例如只吃軟的食物、拒絕脆的或泥狀食物）？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 22,
    "en": "Does your child have unusual reactions to touch (e.g., disliking being touched, or seeking certain textures)?",
    "zh": "你的孩子對觸覺刺激有特殊反應嗎（例如不喜歡被碰觸、或者特別喜歡某些質地）？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 23,
    "en": "Is your child sensitive to bright lights or flashing lights?",
    "zh": "你的孩子對明亮的光線或閃光敏感嗎？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 24,
    "en": "Does your child seem to respond differently to pain (e.g., no reaction to injury, or screaming at light touch)?",
    "zh": "你的孩子似乎對痛覺的反應與常人不同嗎（例如受傷了但沒有反應，或者對輕微碰觸大喊大叫）？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 25,
    "en": "Does your child seek sensory stimulation (e.g., staring at spinning objects, smelling objects)?",
    "zh": "你的孩子會尋求感官刺激嗎（例如盯著旋轉的物體看、聞物體的氣味）？",
    "categoryEN": "Sensory Response",
    "categoryZH": "感官反應",
    "yesNo": false
  },
  {
    "id": 26,
    "en": "Does your child engage in pretend play (e.g., pretending to drink from a cup, talking on a toy phone)?",
    "zh": "你的孩子會進行假想遊戲嗎（例如拿杯子假裝喝茶、拿電話假裝講話）？",
    "categoryEN": "Play Style",
    "categoryZH": "遊戲方式",
    "yesNo": false
  },
  {
    "id": 27,
    "en": "Does your child play with toys in varied ways (not just one way with the same toy)?",
    "zh": "你的孩子玩玩具的方式是多樣化的嗎（不是只用一種方式玩同一個玩具）？",
    "categoryEN": "Play Style",
    "categoryZH": "遊戲方式",
    "yesNo": false
  },
  {
    "id": 28,
    "en": "Does your child play WITH other children (not just parallel play, but interactive)?",
    "zh": "你的孩子會和其他小朋友一起玩嗎（不只是並排各玩各的，而是有互動）？",
    "categoryEN": "Play Style",
    "categoryZH": "遊戲方式",
    "yesNo": false
  },
  {
    "id": 29,
    "en": "Has your child ever lost skills they had already learned (e.g., stopped speaking words they used to say)?",
    "zh": "你的孩子曾經失去過已經學會的技能嗎（例如本來會說的話突然不說了）？",
    "categoryEN": "Regression",
    "categoryZH": "退步現象",
    "yesNo": true
  },
  {
    "id": 30,
    "en": "During your observation, has there been a noticeable regression in your child's social or communication abilities?",
    "zh": "在你觀察期間，孩子的社交或溝通能力是否有明顯的退步？",
    "categoryEN": "Regression",
    "categoryZH": "退步現象",
    "yesNo": true
  }
]
"""#
}

// MARK: - Welcome, silent looping media and account preview
struct CompleteWelcomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var account = false
    @State private var survey = false
    @State private var questionnaire = false
    @State private var pending: CareVoiceSurveyAnswer?
    var body: some View {
        ZStack {
            WelcomeMovie().ignoresSafeArea()
            VStack {
                Spacer()
                Text(store.t("Every little moment.\nA clearer picture.", "每個小日常，\n更清晰嘅了解。"))
                    .font(.largeTitle.bold()).multilineTextAlignment(.center)
                    .padding(24).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
                Button(store.t("Get started", "開始使用")) { survey = true }
                    .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 56)
                    .background(Brand.blue, in: Capsule()).padding(.top, 24)
                Button(store.t("I already have an account", "我已有帳戶")) { account = true }
                    .padding().background(.thinMaterial, in: Capsule())
            }.padding(24)
        }
        .sheet(isPresented: $account) { AccountPreview() }
        .fullScreenCover(isPresented: $survey, onDismiss: { if pending != nil { questionnaire = true } }) {
            CareVoiceSurveyReview(chinese: store.language == .traditionalChinese, onClose: { survey = false }) { answer in
                if answer.shouldOfferQuestionnaire { pending = answer; survey = false }
                else { save(answer) }
            }
        }
        .sheet(isPresented: $questionnaire, onDismiss: { if let answer = pending { save(answer); pending = nil } }) {
            VStack(spacing: 24) {
                Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Brand.blue)
                Text(store.t("Observation questionnaire", "觀察問卷")).font(.title.bold())
                Text(store.t("You can find the optional observation questions on Home and in Settings. There is no score or diagnosis.", "你可以喺首頁或設定開啟選填觀察問卷，唔會評分或診斷。"))
                Button(store.t("Go to Home", "前往首頁")) { questionnaire = false }.buttonStyle(.borderedProminent)
            }.padding(28).presentationDetents([.medium])
        }
    }
    private func save(_ answer: CareVoiceSurveyAnswer) {
        guard let stage = JourneyStage(rawValue: answer.stage) else { return }
        var profile = ChildProfile()
        profile.nickname = answer.nickname; profile.birthDate = answer.birthDate
        profile.ageMonths = answer.ageMonths; profile.stage = stage
        profile.supportGoals = answer.supportGoals; profile.concernNotes = answer.notes
        if store.saveProfile(profile) { survey = false }
    }
}

struct WelcomeMovie: UIViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    final class Surface: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var queue: AVQueuePlayer?
        var looper: AVPlayerLooper?
        deinit { queue?.pause() }
    }
    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        view.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        if let url = Bundle.main.url(forResource: "carevoice-family-hd", withExtension: "mp4") {
            let queue = AVQueuePlayer(); queue.isMuted = true
            view.queue = queue; view.looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            let layer = view.layer as! AVPlayerLayer; layer.player = queue; layer.videoGravity = .resizeAspectFill
        } else {
            let image = UIImageView(image: UIImage(systemName: "figure.and.child.holdinghands"))
            image.tintColor = UIColor.systemBlue.withAlphaComponent(0.35); image.contentMode = .scaleAspectFit
            image.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(image)
            NSLayoutConstraint.activate([image.centerXAnchor.constraint(equalTo: view.centerXAnchor), image.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50), image.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7), image.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)])
        }
        return view
    }
    func updateUIView(_ view: Surface, context: Context) { if reduceMotion { view.queue?.pause() } else { view.queue?.play() } }
    static func dismantleUIView(_ view: Surface, coordinator: ()) { view.queue?.pause(); view.looper = nil; view.queue = nil }
}

struct AccountPreview: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var message = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 12)
            Button { dismiss() } label: { Label(store.t("Back", "返回"), systemImage: "arrow.left") }.frame(minHeight: 44)
            Text(store.t("Welcome back", "歡迎返嚟")).font(.largeTitle.bold())
            HStack(spacing: 12) {
                Image(systemName: "envelope").foregroundStyle(.secondary)
                TextField(store.t("you@example.com", "電郵地址"), text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
            }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 24))
            HStack(spacing: 12) {
                Image(systemName: "lock").foregroundStyle(.secondary)
                SecureField(store.t("Your password", "密碼"), text: $password)
            }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 24))
            Button(store.t("Forgot password?", "忘記密碼？")) { preview() }.frame(maxWidth: .infinity, alignment: .trailing)
            Button(store.t("Sign in", "登入")) { preview() }
                .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 56).background(Brand.blue, in: Capsule())
            Spacer(minLength: 0)
        }.padding(.horizontal, 24).padding(.bottom, 24).background(Brand.background)
            .presentationDetents([.large]).presentationCornerRadius(32)
            .alert(store.t("Account preview", "帳戶預覽"), isPresented: $message) {
                Button("OK", role: .cancel) {}
            } message: { Text(store.t("Sign-in is not connected. Nothing was sent or saved.", "登入尚未連接，冇傳送或儲存任何資料。")) }
    }
    private func preview() { email = ""; password = ""; message = true }
}

// MARK: - Native backup/restore, with explicit replacement confirmation
struct NativeBackupControls: View {
    @EnvironmentObject var store: AppStore
    @State private var export: ExportFile?
    @State private var importing = false
    @State private var pending: AppData?
    @State private var confirming = false
    var body: some View {
        Section(store.t("Data", "資料管理")) {
            Button(store.t("Download a backup", "下載備份")) {
                do {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-backup-\(UUID().uuidString).json")
                    try JSONEncoder().encode(store.data).write(to: url, options: [.atomic, .completeFileProtection])
                    export = ExportFile(url: url)
                } catch { store.errorMessage = error.localizedDescription }
            }
            Button(store.t("Restore a backup", "還原備份")) { importing = true }
        }
        .sheet(item: $export, onDismiss: { /* Shared copies belong to the chosen destination. */ }) { file in ShareSheet(url: file.url) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get(); let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url)
                guard bytes.count < 20_000_000 else { throw CocoaError(.fileReadTooLarge) }
                let data = try JSONDecoder().decode(AppData.self, from: bytes)
                guard data.version == 1, data.profile.map({ (0...83).contains($0.ageMonths) }) ?? true,
                      Set(data.records.map(\.id)).count == data.records.count else { throw CocoaError(.coderReadCorrupt) }
                pending = data; confirming = true
            } catch { store.errorMessage = store.t("This native backup could not be restored. Your current data is unchanged.", "未能還原備份，現有資料保持不變。") }
        }
        .alert(store.t("Replace local data?", "取代本機資料？"), isPresented: $confirming) {
            Button(store.t("Cancel", "取消"), role: .cancel) { pending = nil }
            Button(store.t("Restore", "還原"), role: .destructive) { if let data = pending { store.update { $0 = data } }; pending = nil }
        } message: { Text(store.t("This replaces your profile, records and answers with the selected backup.", "呢個操作會以備份取代檔案、記錄同問卷答案。")) }
    }
}


// MARK: - Merged Phase 1: CareVoice/Core/ContentModels.swift

/// Pick the English text when the language is English, else fall back to TC.
func localized(_ en: String?, _ tc: String?, _ language: AppLanguage) -> String {
    if language == .english, let en, !en.isEmpty { return en }
    return tc ?? en ?? ""
}

struct CitableAssertion: Codable, Identifiable {
    let assertionId: String
    let topic: String
    let quote: String
    let plainTc: String
    let locator: String?
    let org: String
    let titleTc: String
    let url: String
    let capturedOn: String
    let sourceStatus: String
    let plainEn: String?
    let quoteEn: String?
    let locatorEn: String?
    let orgEn: String?
    let titleEn: String?
    var id: String { assertionId }

    enum CodingKeys: String, CodingKey {
        case assertionId = "assertion_id"
        case topic, quote
        case plainTc = "plain_tc"
        case locator, org
        case titleTc = "title_tc"
        case url
        case capturedOn = "captured_on"
        case sourceStatus = "source_status"
        case plainEn = "plain_en"
        case quoteEn = "quote_en"
        case locatorEn = "locator_en"
        case orgEn = "org_en"
        case titleEn = "title_en"
    }
}

struct ServiceType: Codable, Identifiable {
    let code: String
    let aliasTc: String?
    let aliasEn: String?
    let nameTc: String
    let nameEn: String?
    let ageMinM: Int?
    let ageMaxM: Int?
    let intensityTc: String?
    let targetTc: String?
    let referralTc: String?
    let feeTc: String?
    let waitNoteTc: String?
    let sourceId: String?
    let notesTc: String?
    let intensityEn: String?
    let targetEn: String?
    let referralEn: String?
    let feeEn: String?
    let waitNoteEn: String?
    let notesEn: String?
    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code
        case aliasTc = "alias_tc"
        case aliasEn = "alias_en"
        case nameTc = "name_tc"
        case nameEn = "name_en"
        case ageMinM = "age_min_m"
        case ageMaxM = "age_max_m"
        case intensityTc = "intensity_tc"
        case targetTc = "target_tc"
        case referralTc = "referral_tc"
        case feeTc = "fee_tc"
        case waitNoteTc = "wait_note_tc"
        case sourceId = "source_id"
        case notesTc = "notes_tc"
        case intensityEn = "intensity_en"
        case targetEn = "target_en"
        case referralEn = "referral_en"
        case feeEn = "fee_en"
        case waitNoteEn = "wait_note_en"
        case notesEn = "notes_en"
    }
}

struct ServiceUnit: Codable, Identifiable {
    let unitId: String
    let nameTc: String
    let nameEn: String?
    let serviceCode: String?
    let operatorName: String?
    let district: String?
    let address: String?
    let phone: String?
    let capacity: Int?
    let sourceId: String?
    let status: String?
    let districtEn: String?
    var id: String { unitId }

    enum CodingKeys: String, CodingKey {
        case unitId = "unit_id"
        case nameTc = "name_tc"
        case nameEn = "name_en"
        case serviceCode = "service_code"
        case operatorName = "operator"
        case district, address, phone, capacity
        case sourceId = "source_id"
        case status
        case districtEn = "district_en"
    }
}

struct WaitingSnapshot: Codable, Identifiable {
    let snapshotId: String
    let asOf: String
    let unitId: String
    let unitNameRaw: String?
    let serviceCode: String?
    let lastMatchApply: String?
    let derivedWaitM: Int?
    let sourceId: String?
    let runId: String?
    var id: String { snapshotId }

    enum CodingKeys: String, CodingKey {
        case snapshotId = "snapshot_id"
        case asOf = "as_of"
        case unitId = "unit_id"
        case unitNameRaw = "unit_name_raw"
        case serviceCode = "service_code"
        case lastMatchApply = "last_match_apply"
        case derivedWaitM = "derived_wait_m"
        case sourceId = "source_id"
        case runId = "run_id"
    }
}

struct GlossaryTerm: Codable, Identifiable {
    let term: String
    let fullTc: String
    let code: String?
    let plainTc: String
    let sourceId: String?
    let termEn: String?
    let fullEn: String?
    let plainEn: String?
    var id: String { term }

    enum CodingKeys: String, CodingKey {
        case term
        case fullTc = "full_tc"
        case code
        case plainTc = "plain_tc"
        case sourceId = "source_id"
        case termEn = "term_en"
        case fullEn = "full_en"
        case plainEn = "plain_en"
    }
}

struct PathwayStep: Codable, Identifiable {
    let stepNo: Int
    let nameTc: String
    let whoActsTc: String?
    let preconditions: String?
    let durationNote: String?
    let frictionTc: String?
    let plainTc: String?
    let status: String?
    let nameEn: String?
    let whoActsEn: String?
    let preconditionsEn: String?
    let durationNoteEn: String?
    let frictionEn: String?
    let plainEn: String?
    var id: Int { stepNo }

    enum CodingKeys: String, CodingKey {
        case stepNo = "step_no"
        case nameTc = "name_tc"
        case whoActsTc = "who_acts_tc"
        case preconditions
        case durationNote = "duration_note"
        case frictionTc = "friction_tc"
        case plainTc = "plain_tc"
        case status
        case nameEn = "name_en"
        case whoActsEn = "who_acts_en"
        case preconditionsEn = "preconditions_en"
        case durationNoteEn = "duration_note_en"
        case frictionEn = "friction_en"
        case plainEn = "plain_en"
    }
}

struct ChecklistItem: Codable, Identifiable {
    let itemId: String
    let stepNo: Int
    let nameTc: String
    let required: Int?
    let originTc: String?
    let validityTc: String?
    let sortOrder: Int?
    let sourceId: String?
    let notesTc: String?
    let nameEn: String?
    let originEn: String?
    let validityEn: String?
    let notesEn: String?
    var id: String { itemId }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case stepNo = "step_no"
        case nameTc = "name_tc"
        case required
        case originTc = "origin_tc"
        case validityTc = "validity_tc"
        case sortOrder = "sort_order"
        case sourceId = "source_id"
        case notesTc = "notes_tc"
        case nameEn = "name_en"
        case originEn = "origin_en"
        case validityEn = "validity_en"
        case notesEn = "notes_en"
    }
}

struct RedFlag: Codable, Identifiable {
    let flagId: String
    let signalTc: String
    let routeTc: String
    let routeContact: String?
    let neverSayTc: String
    let sourceId: String?
    let status: String?
    let signalEn: String?
    let routeEn: String?
    let routeContactEn: String?
    let neverSayEn: String?
    var id: String { flagId }

    enum CodingKeys: String, CodingKey {
        case flagId = "flag_id"
        case signalTc = "signal_tc"
        case routeTc = "route_tc"
        case routeContact = "route_contact"
        case neverSayTc = "never_say_tc"
        case sourceId = "source_id"
        case status
        case signalEn = "signal_en"
        case routeEn = "route_en"
        case routeContactEn = "route_contact_en"
        case neverSayEn = "never_say_en"
    }
}

struct ContentManifest: Codable {
    let builtOn: String?
    let dbFile: String?
    let contentFingerprint: String?
    let counts: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case builtOn = "built_on"
        case dbFile = "db_file"
        case contentFingerprint = "content_fingerprint"
        case counts
    }
}

struct GovernmentContent {
    let assertions: [CitableAssertion]
    let serviceTypes: [ServiceType]
    let serviceUnits: [ServiceUnit]
    let waiting: [WaitingSnapshot]
    let glossary: [GlossaryTerm]
    let pathwaySteps: [PathwayStep]
    let checklistItems: [ChecklistItem]
    let redFlags: [RedFlag]
    let manifest: ContentManifest?

    static func load() -> GovernmentContent {
        func decode<T: Decodable>(_ name: String, _ type: T.Type) -> T? {
            guard let json = EmbeddedGovernmentContent.files[name] else { return nil }
            let data = Data(json.utf8)
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return GovernmentContent(
            assertions: decode("citable_assertions", [CitableAssertion].self) ?? [],
            serviceTypes: decode("service_types", [ServiceType].self) ?? [],
            serviceUnits: decode("service_units", [ServiceUnit].self) ?? [],
            waiting: decode("waiting_snapshot", [WaitingSnapshot].self) ?? [],
            glossary: decode("glossary", [GlossaryTerm].self) ?? [],
            pathwaySteps: decode("pathway_steps", [PathwayStep].self) ?? [],
            checklistItems: decode("checklist_items", [ChecklistItem].self) ?? [],
            redFlags: decode("red_flags", [RedFlag].self) ?? [],
            manifest: decode("manifest", ContentManifest.self)
        )
    }

    func waitMonths(for unitId: String) -> Int? {
        waiting.first { $0.unitId == unitId }?.derivedWaitM
    }

    func serviceType(code: String?) -> ServiceType? {
        guard let code else { return nil }
        return serviceTypes.first { $0.code == code }
    }

    var districts: [String] {
        let values = serviceUnits.compactMap { $0.district }.filter { !$0.isEmpty }
        return Array(Set(values)).sorted()
    }

    var serviceCodes: [String] {
        let values = serviceUnits.compactMap { $0.serviceCode }.filter { !$0.isEmpty }
        return Array(Set(values)).sorted()
    }
}

// MARK: - Merged Phase 1: CareVoice/Features/ContentViews.swift

// MARK: - Service types

struct ServiceTypesView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.t("What the letters mean", "這些代號是甚麼")).font(.system(.title, design: .rounded).bold())
                Text(store.t("Government-funded pre-school rehabilitation services, in plain words.", "政府資助的學前康復服務，用淺白的話解釋。")).foregroundStyle(.secondary)
                ForEach(store.content.serviceTypes) { type in
                    Card {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(localized(type.aliasEn, type.aliasTc, store.language)).font(.title3.bold()).foregroundStyle(Brand.blue)
                            Text(localized(type.nameEn, type.nameTc, store.language)).font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        if let target = type.targetTc { row(store.t("Who it's for", "服務對象"), localized(type.targetEn, target, store.language)) }
                        if let intensity = type.intensityTc { row(store.t("What it is", "服務形式"), localized(type.intensityEn, intensity, store.language)) }
                        if let referral = type.referralTc { row(store.t("How to get it", "轉介方式"), localized(type.referralEn, referral, store.language)) }
                        if let fee = type.feeTc { row(store.t("Fee", "費用"), localized(type.feeEn, fee, store.language)) }
                        if let wait = type.waitNoteTc { row(store.t("Typical wait", "輪候情況"), localized(type.waitNoteEn, wait, store.language)) }
                    }
                }
                sourceNote()
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Service types", "服務種類")).navigationBarTitleDisplayMode(.inline)
    }
    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Brand.teal)
            Text(value).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }
    private func sourceNote() -> some View {
        Text(store.t("Compiled from official Social Welfare Department and Department of Health pages. Details are confirmed by the service provider.", "資料整理自社會福利署及衞生署官方網頁，詳情以服務機構確認為準。"))
            .font(.caption).foregroundStyle(.secondary)
    }
}

// MARK: - Glossary

struct GlossaryView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""

    private var filtered: [GlossaryTerm] {
        guard !search.isEmpty else { return store.content.glossary }
        return store.content.glossary.filter { t in
            t.term.localizedCaseInsensitiveContains(search)
            || (t.termEn ?? "").localizedCaseInsensitiveContains(search)
            || t.fullTc.localizedCaseInsensitiveContains(search)
            || (t.fullEn ?? "").localizedCaseInsensitiveContains(search)
            || t.plainTc.localizedCaseInsensitiveContains(search)
            || (t.plainEn ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("Jargon, decoded", "行話對照")).font(.system(.title, design: .rounded).bold())
                if filtered.isEmpty {
                    ContentUnavailableView(store.t("No matching terms", "沒有符合的詞語"), systemImage: "magnifyingglass")
                }
                ForEach(filtered) { term in
                    Card {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(localized(term.termEn, term.term, store.language)).font(.headline).foregroundStyle(Brand.blue)
                            Text(localized(term.fullEn, term.fullTc, store.language)).font(.subheadline.weight(.semibold))
                        }
                        Text(localized(term.plainEn, term.plainTc, store.language)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Glossary", "術語對照")).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: store.t("Search terms", "搜尋詞語"))
    }
}

// MARK: - Service directory

struct ServiceDirectoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var district = "all"
    @State private var serviceCode = "all"

    private var filtered: [ServiceUnit] {
        var units = store.content.serviceUnits
        if district != "all" { units = units.filter { $0.district == district } }
        if serviceCode != "all" { units = units.filter { $0.serviceCode == serviceCode } }
        if !search.isEmpty {
            units = units.filter { $0.nameTc.localizedCaseInsensitiveContains(search) || ($0.nameEn ?? "").localizedCaseInsensitiveContains(search) }
        }
        return units.sorted { ($0.district ?? "") < ($1.district ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Menu {
                        Picker(store.t("District", "地區"), selection: $district) {
                            Text(store.t("All districts", "所有地區")).tag("all")
                            ForEach(store.content.districts, id: \.self) { d in
                                Text(districtName(d)).tag(d)
                            }
                        }
                    } label: {
                        Label(district == "all" ? store.t("District", "地區") : districtName(district), systemImage: "mappin.and.ellipse")
                    }
                    Menu {
                        Picker(store.t("Service", "服務"), selection: $serviceCode) {
                            Text(store.t("All services", "所有服務")).tag("all")
                            ForEach(store.content.serviceCodes, id: \.self) { c in
                                Text(serviceLabel(c)).tag(c)
                            }
                        }
                    } label: {
                        Label(serviceCode == "all" ? store.t("Service", "服務") : serviceLabel(serviceCode), systemImage: "building.2")
                    }
                    Spacer()
                }.font(.subheadline)
                ForEach(filtered) { unit in
                    Card {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localized(unit.nameEn, unit.nameTc, store.language)).font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            if let code = unit.serviceCode {
                                Text(serviceLabel(code))
                                    .font(.caption.bold()).foregroundStyle(Brand.teal)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Brand.teal.opacity(0.12), in: Capsule())
                            }
                        }
                        if let d = unit.district { Text(localized(unit.districtEn, d, store.language)).font(.caption).foregroundStyle(.secondary) }
                        if let address = unit.address, !address.isEmpty { Text(address).font(.subheadline) }
                        HStack(spacing: 16) {
                            if let phone = unit.phone, !phone.isEmpty {
                                Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                    Label(phone, systemImage: "phone").font(.subheadline).foregroundStyle(Brand.blue)
                                }
                            }
                            if let wait = store.content.waitMonths(for: unit.unitId) {
                                Label(store.t("\(wait) mo wait", "輪候約 \(wait) 個月"), systemImage: "clock").font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView(store.t("No centres match", "沒有符合的中心"), systemImage: "magnifyingglass")
                }
                Text(store.t("Waiting figures are a snapshot (as of 2026-08-31) recalculated from official datasets — not live availability.", "輪候數字為截至 2026-08-31 的快照，由官方數據集逐間復算，並非實時名額。"))
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Find a centre", "服務機構・輪候")).navigationBarTitleDisplayMode(.inline)
    }

    private func serviceLabel(_ code: String) -> String {
        guard let st = store.content.serviceType(code: code) else { return code }
        return localized(st.aliasEn, st.aliasTc, store.language)
    }

    private func districtName(_ d: String) -> String {
        if store.language == .english {
            if let unit = store.content.serviceUnits.first(where: { $0.district == d }), let en = unit.districtEn, !en.isEmpty { return en }
        }
        return d
    }
}

// MARK: - Citable facts

struct CitableFactsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""

    private var topics: [String] {
        Array(Set(store.content.assertions.map { $0.topic })).sorted()
    }

    private var searchResults: [CitableAssertion] {
        guard !search.isEmpty else { return [] }
        return store.content.assertions.filter { a in
            localized(a.plainEn, a.plainTc, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.quoteEn, a.quote, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.titleEn, a.titleTc, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.orgEn, a.org, store.language).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(store.t("Every fact, with its source", "每條資料都有出處")).font(.system(.title, design: .rounded).bold())
                Text(store.t("These are verbatim official statements, each linking back to the original page.", "以下為官方原文逐字摘錄，每條均可點回原始網頁。")).foregroundStyle(.secondary)
                if store.language == .english {
                    Text(store.t("English text is a translation, not an official quote.", "英文內容為翻譯，並非官方原文。"))
                        .font(.caption).foregroundStyle(.orange)
                }
                if search.isEmpty {
                    ForEach(topics, id: \.self) { topic in
                        let items = store.content.assertions.filter { $0.topic == topic }
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(items) { a in assertionCard(a) }
                            }.padding(.top, 6)
                        } label: {
                            HStack {
                                Text(topicLabel(topic, store.language)).font(.headline)
                                Spacer()
                                Text("\(items.count)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    if searchResults.isEmpty {
                        ContentUnavailableView(store.t("No matching information", "沒有符合的資料"), systemImage: "magnifyingglass")
                    }
                    ForEach(searchResults) { a in assertionCard(a, showTopic: true) }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Cited information", "可引用資料")).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: store.t("Search cited information", "搜尋可引用資料"))
    }

    private func assertionCard(_ a: CitableAssertion, showTopic: Bool = false) -> some View {
        Card {
            if showTopic {
                Text(topicLabel(a.topic, store.language)).font(.caption.bold()).foregroundStyle(Brand.teal)
            }
            Text(localized(a.plainEn, a.plainTc, store.language)).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Divider()
            Text("「\(localized(a.quoteEn, a.quote, store.language))」").font(.footnote).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(localized(a.orgEn, a.org, store.language)).font(.caption.bold()).foregroundStyle(Brand.teal)
                Text(localized(a.titleEn, a.titleTc, store.language)).font(.caption).foregroundStyle(.secondary)
                Spacer()
                if !a.url.isEmpty {
                    Link(store.t("Source", "來源"), destination: URL(string: a.url)!).font(.caption).foregroundStyle(Brand.blue)
                }
            }
        }
    }
}

private func topicLabel(_ topic: String, _ l: AppLanguage) -> String {
    switch topic {
    case "waiting": return l.text("Waiting times", "輪候時間")
    case "waiting_support": return l.text("Support while waiting", "輪候期間支援")
    case "subsidy": return l.text("Subsidy", "津貼")
    case "eligibility": return l.text("Eligibility", "資格")
    case "service": return l.text("Services", "服務")
    case "cost": return l.text("Cost", "費用")
    case "transition": return l.text("Transition support", "過渡支援")
    case "referral_route": return l.text("Referral", "轉介")
    case "materials": return l.text("Documents", "所需材料")
    case "right": return l.text("Rights", "權益")
    case "redflag": return l.text("Red flags", "紅旗")
    default: return topic
    }
}

enum EmbeddedGovernmentContent {
    static let files: [String: String] = [
"checklist_items": #"""
[
  {
    "item_id": "CI-001",
    "step_no": 3,
    "name_tc": "醫生或心理學家之介紹信",
    "required": 1,
    "origin_tc": "開信者：私家醫生／醫院／心理學家",
    "validity_tc": "待核实",
    "sort_order": 10,
    "source_id": "SRC-014",
    "notes_tc": "★ 没有这封信，第 3 步根本走不了。这是家长最常缺的第一样东西",
    "name_en": "Referral letter from a doctor or psychologist",
    "origin_en": "Issued by: private doctor / hospital / psychologist",
    "validity_en": "To be confirmed",
    "notes_en": "Without this letter, step 3 can't proceed. It's the first thing parents most often lack."
  },
  {
    "item_id": "CI-008",
    "step_no": 5,
    "name_tc": "心理報告／醫生報告（由轉介人附帶提交）",
    "required": 1,
    "origin_tc": "評估團隊／醫生／轉介人",
    "validity_tc": "待核实",
    "sort_order": 10,
    "source_id": "SRC-014",
    "notes_tc": "家长不需要自己准备，但要确认转介人有把它一起交上去",
    "name_en": "Psychological report / medical report (submitted by the referrer)",
    "origin_en": "Assessment team / doctor / referrer",
    "validity_en": "To be confirmed",
    "notes_en": "Parents don't prepare this themselves, but should confirm the referrer submitted it along."
  },
  {
    "item_id": "CI-010",
    "step_no": 6,
    "name_tc": "學習訓練津貼（T位）申請表連所需文件副本",
    "required": 0,
    "origin_tc": "社署發信邀請後由家長填交",
    "validity_tc": "—",
    "sort_order": 10,
    "source_id": "SRC-005",
    "notes_tc": "不主动申请就没有；社署会发信邀请合资格家庭，但要家长自己交表。可网上或邮寄递交",
    "name_en": "Training Subsidy (T-place) application form with copies of required documents",
    "origin_en": "Filled in and submitted by the parent after SWD sends an invitation letter",
    "validity_en": "—",
    "notes_en": "You won't get it unless you apply; SWD invites eligible families by letter, but parents must submit the form. Can be submitted online or by post."
  },
  {
    "item_id": "CI-002",
    "step_no": 3,
    "name_tc": "兒童出世紙或身份證（必須為正本）",
    "required": 1,
    "origin_tc": "家長自行保管",
    "validity_tc": "—",
    "sort_order": 20,
    "source_id": "SRC-014",
    "notes_tc": "官方要求正本，不接受影印本",
    "name_en": "Child's birth certificate or identity card (original required)",
    "origin_en": "Kept by the parent",
    "validity_en": "—",
    "notes_en": "Official requirement is the original; photocopies not accepted."
  },
  {
    "item_id": "CI-009",
    "step_no": 5,
    "name_tc": "服務類別（E／S／I／O）及中心地區偏好",
    "required": 1,
    "origin_tc": "家長在登記時提供",
    "validity_tc": "—",
    "sort_order": 20,
    "source_id": "SRC-004",
    "notes_tc": "★ 官方明写编配时按「申請日期先後及地區選擇」排序——所以地区偏好填错会直接影响什么时候拿到服务",
    "name_en": "Service type (E/S/I/O) and centre district preference",
    "origin_en": "Provided by the parent at registration",
    "validity_en": "—",
    "notes_en": "Official text states allocation is by 'application date and district preference' — so a wrong district preference directly affects when you get a place."
  },
  {
    "item_id": "CI-003",
    "step_no": 3,
    "name_tc": "父親及母親身份證（或影印本）",
    "required": 1,
    "origin_tc": "家長自行保管",
    "validity_tc": "—",
    "sort_order": 30,
    "source_id": "SRC-014",
    "notes_tc": null,
    "name_en": "Father's and mother's identity cards (or photocopies)",
    "origin_en": "Kept by the parent",
    "validity_en": "—"
  },
  {
    "item_id": "CI-004",
    "step_no": 3,
    "name_tc": "兒童半身近照 1 張",
    "required": 1,
    "origin_tc": "家長自備",
    "validity_tc": "—",
    "sort_order": 40,
    "source_id": "SRC-014",
    "notes_tc": "这条最容易漏，而且临时补拍来不及",
    "name_en": "1 recent half-length photo of the child",
    "origin_en": "Prepared by the parent",
    "validity_en": "—",
    "notes_en": "Most easily forgotten, and hard to retake at the last minute."
  },
  {
    "item_id": "CI-005",
    "step_no": 3,
    "name_tc": "健康院紀錄簿／防疫注射紀錄／所有專科覆診咭",
    "required": 1,
    "origin_tc": "衞生署母嬰健康院／醫院",
    "validity_tc": "—",
    "sort_order": 50,
    "source_id": "SRC-014",
    "notes_tc": "记录孩子一路以来的发展监察数据，对评估有用",
    "name_en": "Health centre record book / immunisation record / all specialist follow-up cards",
    "origin_en": "Department of Health Maternal & Child Health Centre / hospital",
    "validity_en": "—",
    "notes_en": "Records the child's developmental surveillance data over time; useful for assessment."
  },
  {
    "item_id": "CI-006",
    "step_no": 3,
    "name_tc": "住址證明（或影印本）",
    "required": 1,
    "origin_tc": "家長自備",
    "validity_tc": "—",
    "sort_order": 60,
    "source_id": "SRC-014",
    "notes_tc": "决定分派到哪个地区的测验中心",
    "name_en": "Proof of address (or photocopy)",
    "origin_en": "Prepared by the parent",
    "validity_en": "—",
    "notes_en": "Determines which district's assessment centre you are assigned to."
  },
  {
    "item_id": "CI-007",
    "step_no": 3,
    "name_tc": "專科門診費用（首次 $135、其後每次 $80）或有效的綜援醫療費用豁免證明書",
    "required": 1,
    "origin_tc": "現場繳付",
    "validity_tc": "—",
    "sort_order": 70,
    "source_id": "SRC-022",
    "notes_tc": "✅ 金額與綜援豁免證明已改掛衞生署一手來源（SRC-022 登記表格 PDF）；原 SRC-014（非官方次級來源）不再作為本條依據。⚠️ 檔名帶 170803 版本標記、未確認是否最新版；對外只寫「衞生署登記表格所列」，不寫「現行收費」。若家庭有綜援豁免證明，可免",
    "name_en": "Specialist clinic fee (first visit $135, subsequent $80) or a valid CSSA medical fee waiver certificate",
    "origin_en": "Paid on site",
    "validity_en": "—",
    "notes_en": "Amount and CSSA waiver now cite a Department of Health first-hand source (SRC-022 registration form PDF). Filename carries a version tag; externally state 'as listed on the Department of Health registration form', not 'current fee'. Families with a CSSA waiver are exempt."
  }
]
"""#,
"citable_assertions": #"""
[
  {
    "assertion_id": "A-005",
    "topic": "cost",
    "quote": "經由社工或康復服務單位的工作人員轉介至社署康復服務中央轉介系統。有關申請不會收取任何費用。",
    "plain_tc": "申请走中央转介系统、由社工或康复单位的人转介；申请不收钱，服务本身也是免费的。",
    "locator": "申請手續",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "Applications go through the Central Referral System, referred by a social worker or rehabilitation unit staff; applying is free, and the service itself is free.",
    "quote_en": "Referred to the SWD Central Referral System for Rehabilitation Services by a social worker or a staff member of a rehabilitation service unit. No fee is charged for the application.",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Application procedures"
  },
  {
    "assertion_id": "A-027",
    "topic": "cost",
    "quote": "免費。",
    "plain_tc": "这项服务本身免费。",
    "locator": "費用",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The service itself is free.",
    "quote_en": "Free of charge.",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Fee"
  },
  {
    "assertion_id": "A-003",
    "topic": "eligibility",
    "quote": "年齡介乎2歲至6歲以下未開始接受小學教育，並有下列任何1項發展障礙的兒童：",
    "plain_tc": "能排 S 位的是 2 到 6 岁以下、还没上小学的孩子，而且要有中度至严重的障碍——其中一项明确包括自闭症。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "A child can be placed in an S-place if they are aged 2 to under 6, not yet in primary school, and have a moderate to severe disability — one of which is explicitly autism.",
    "quote_en": "Children aged 2 to under 6 who have not yet started primary education and have any one of the following developmental disabilities:",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-004",
    "topic": "eligibility",
    "quote": "康復服務中央轉介系統接受家長為2歲以下的兒童預早登記輪候此項服務，但當有服務空缺時，這些兒童必須符合基本入讀條件，包括年齡已屆2歲，方能合資格獲得服務編配。",
    "plain_tc": "孩子还没满 2 岁，就可以先去登记排队；但真的有空位要分配时，孩子必须已经满 2 岁才能拿到。",
    "locator": "服務對象（末段）",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "A child under 2 can register to queue in advance, but when a vacancy comes up the child must already have turned 2 to be offered a place.",
    "quote_en": "The Central Referral System for Rehabilitation Services accepts parents to register in advance for this service for children under the age of 2, but when a vacancy arises, these children must meet the basic admission conditions, including having reached the age of 2, before a place can be allocated.",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets (last paragraph)"
  },
  {
    "assertion_id": "A-007",
    "topic": "eligibility",
    "quote": "Central Referral System for Rehabilitation Services (the System) accepts parents to register application for Special Child Care Centre or Integrated Programme in Kindergarten-cum-Child Care Centre services for children from below the age of two in advance.",
    "plain_tc": "没满 2 岁的孩子，家长可以先去中央转介系统预早登记排队 S 位或 I 位。",
    "locator": "Remarks (1)",
    "org": "社署",
    "title_tc": "康復服務中央轉介系統 — 輪候資料更新",
    "url": "https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/crsrehabwa",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "For a child under 2, parents can register in advance on the Central Referral System to queue for an S-place or I-place.",
    "quote_en": "Central Referral System for Rehabilitation Services (the System) accepts parents to register application for Special Child Care Centre or Integrated Programme in Kindergarten-cum-Child Care Centre services for children from below the age of two in advance.",
    "org_en": "Social Welfare Department",
    "title_en": "Central Referral System for Rehabilitation Services — Waiting List Information Updates"
  },
  {
    "assertion_id": "A-021",
    "topic": "eligibility",
    "quote": "並無接受任何資助學前康復服務，包括「過渡性早期教育及訓練中心」或「學前康復服務–校本支援模式」",
    "plain_tc": "要拿 T 位津贴，前提是孩子「没有在接受任何资助学前康复服务」，其中包括「过渡性 E 位」。",
    "locator": "第4頁．受惠對象條件(2)",
    "org": "社署",
    "title_tc": "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/TSP%20Service%20Brief_Chi_202610.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "To get the T-place subsidy, the child must not be receiving any subsidised pre-school rehabilitation service, including the 'transitional E-place'.",
    "quote_en": "Not receiving any subsidised pre-school rehabilitation service, including the 'Transitional Early Education and Training Centre' or the 'Pre-school Rehabilitation Service – School-based Support Model'.",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "locator_en": "p.4 Eligibility conditions (2)"
  },
  {
    "assertion_id": "A-022",
    "topic": "eligibility",
    "quote": "中度或嚴重智障；",
    "plain_tc": "障碍条件之一：中度或严重智障。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "One of the disability conditions: moderate or severe intellectual disability.",
    "quote_en": "Moderate or severe intellectual disability;",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-023",
    "topic": "eligibility",
    "quote": "中度或嚴重肢體傷殘；",
    "plain_tc": "障碍条件之一：中度或严重肢体伤残。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "One of the disability conditions: moderate or severe physical disability.",
    "quote_en": "Moderate or severe physical disability;",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-024",
    "topic": "eligibility",
    "quote": "失聰或嚴重至極度嚴重聽覺受損；",
    "plain_tc": "障碍条件之一：失聪或严重至极严重听觉受损。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "One of the disability conditions: deafness or severe to profound hearing impairment.",
    "quote_en": "Deafness or severe to profound hearing impairment;",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-025",
    "topic": "eligibility",
    "quote": "失明或嚴重視覺受損；或",
    "plain_tc": "障碍条件之一：失明或严重视觉受损。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "One of the disability conditions: blindness or severe visual impairment.",
    "quote_en": "Blindness or severe visual impairment; or",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-026",
    "topic": "eligibility",
    "quote": "行為/情緒上有嚴重問題、有過度活躍傾向或患有自閉症。",
    "plain_tc": "障碍条件之一：行为或情绪上有严重问题、有过度活跃倾向，或患有自闭症——「自闭症孩子走 S 线」的官方依据就在这一条。",
    "locator": "服務對象",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "One of the disability conditions: serious behavioural or emotional problems, hyperactivity, or autism — the official basis for 'a child with autism goes down the S-route'.",
    "quote_en": "Serious behavioural/emotional problems, a tendency to hyperactivity, or autism.",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Service targets"
  },
  {
    "assertion_id": "A-015",
    "topic": "referral_route",
    "quote": "兒童可經專業人士（如醫生、心理學家）或經醫院直接轉介（例如：早產兒）。",
    "plain_tc": "想去测验中心做评估，得先有医生或心理学家这类专业人士的转介，或者由医院直接转介。家长自己是不能直接预约的。",
    "locator": "一．服務對象",
    "org": "衞生署",
    "title_tc": "兒童體能智力測驗服務《服務範圍》",
    "url": "http://www.dhcas.gov.hk/tc/scope.html",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "To get an assessment at the Child Assessment Centre, you first need a referral from a professional such as a doctor or psychologist, or a direct hospital referral. Parents cannot book on their own.",
    "quote_en": "Children may be referred by professionals (such as doctors or psychologists) or directly through a hospital (e.g. premature infants).",
    "org_en": "Department of Health",
    "title_en": "Child Assessment Service — Scope of Service",
    "locator_en": "1. Service targets"
  },
  {
    "assertion_id": "A-002",
    "topic": "service",
    "quote": "提供全日的訓練和照顧予中度至嚴重程度殘疾的幼兒，以協助他們發展及成長，讓他們為小學教育作好準備。",
    "plain_tc": "S 位是全日制的：孩子白天一整天都在中心，由专业团队做训练和照顾，目标是为上小学做准备。",
    "locator": "簡介段",
    "org": "社署",
    "title_tc": "特殊幼兒中心（服務頁）",
    "url": "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/specialchi/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "An S-place is full-day: the child spends the whole day at the centre receiving training and care from a professional team, with the goal of preparing for primary school.",
    "quote_en": "Providing full-day training and care to children with moderate to severe disabilities, to help them develop and grow and prepare them for primary education.",
    "org_en": "Social Welfare Department",
    "title_en": "Special Child Care Centre (service page)",
    "locator_en": "Introduction paragraph"
  },
  {
    "assertion_id": "A-009",
    "topic": "service",
    "quote": "As of the end of January 2025, there are 50 Special Child Care Centres (SCCCs), including six Residential Special Child Care Centres, across the territory providing full-day training and care for children aged two to six with moderate to severe disabilities.",
    "plain_tc": "全香港有 50 所 S 位中心，其中 6 所有住宿，为 2 到 6 岁中度至严重残疾的孩子提供全天训练和照顾。",
    "locator": "Reply (1)",
    "org": "立法會",
    "title_tc": "LCQ22: Special child care centres（2025-03-19 書面答覆．英文版）",
    "url": "https://www.info.gov.hk/gia/general/202503/19/P2025031900214.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "There are 50 S-place centres in Hong Kong, 6 of which are residential, providing full-day training and care for children aged 2–6 with moderate to severe disabilities.",
    "quote_en": "As of the end of January 2025, there are 50 Special Child Care Centres (SCCCs), including six Residential Special Child Care Centres, across the territory providing full-day training and care for children aged two to six with moderate to severe disabilities.",
    "org_en": "Legislative Council",
    "title_en": "LCQ22: Special child care centres (19 Mar 2025 written reply, English version)"
  },
  {
    "assertion_id": "A-032",
    "topic": "service",
    "quote": "服務透過非政府機構營辦的跨專業服務團隊（服務隊）（成員包括職業治療師、物理治療師、言語治療師、臨床／教育心理學家、社工、以及特殊幼兒工作員）以校本綜合模式提供到校訓練及支援服務予就讀於參與「到校學前康復服務」的幼稚園或幼稚園暨幼兒中心，而年齡為6歲以下，並被評估為輕度殘疾或懷疑有特殊需要的兒童。",
    "plain_tc": "O 位（到校学前康复服务）是 NGO 的跨专业团队直接到幼儿园给孩子做训练和支援，收 6 岁以下、被评估为轻度残疾或怀疑有特殊需要的孩子。",
    "locator": "服務簡介．第4段",
    "org": "社署",
    "title_tc": "到校學前康復服務（OPRS）",
    "url": "https://swd.gov.hk/oprs/index_tc.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The O-place (on-site pre-school rehabilitation service) is delivered by an NGO multidisciplinary team directly at the kindergarten, for children under 6 assessed with mild disabilities or suspected special needs.",
    "quote_en": "The service is provided by a multidisciplinary service team operated by a non-governmental organisation (comprising occupational therapists, physiotherapists, speech therapists, clinical/educational psychologists, social workers and special child care workers) through a school-based integrated model, delivering on-site training and support to children under 6 attending a kindergarten or kindergarten-cum-child care centre participating in the 'On-site Pre-school Rehabilitation Service', who have been assessed with mild disabilities or are suspected of having special needs.",
    "org_en": "Social Welfare Department",
    "title_en": "On-site Pre-school Rehabilitation Services (OPRS)",
    "locator_en": "Service introduction, paragraph 4"
  },
  {
    "assertion_id": "A-011",
    "topic": "subsidy",
    "quote": "學習訓練津貼不會直接發放給父母／監護人，而是發放給認可服務機構，並根據兒童的殘疾程度提供以下兩個水平的資助：",
    "plain_tc": "T 位津贴不是发现金给家长。社署按孩子的残疾程度分两档，钱直接付给认可服务机构，家长拿到的是机构提供的训练服务。",
    "locator": "第1頁．資助水平及服務",
    "org": "社署",
    "title_tc": "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/TSP%20Service%20Brief_Chi_202610.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The T-place subsidy is not paid in cash to parents. SWD pays it in two tiers, based on the child's disability, directly to recognised service operators; parents receive the training services those operators provide.",
    "quote_en": "The Training Subsidy is not paid directly to the parent/guardian, but to recognised service operators, and is provided at the following two levels according to the child's degree of disability:",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "locator_en": "p.1 Subsidy levels and services"
  },
  {
    "assertion_id": "A-012",
    "topic": "subsidy",
    "quote": "由於「到校學前康復服務」已達致零等候，因此由2026年10月1日起，新申請「到校學前康復服務」的兒童並不是「學習訓練津貼」的受惠對象。",
    "plain_tc": "从 2026 年 10 月 1 日起，新申请 O 位（到校学前康复服务）的孩子，不能再申请 T 位津贴了——因为 O 位已经做到零等候。",
    "locator": "註一",
    "org": "社署",
    "title_tc": "為輪候資助學前康復服務的兒童提供學習訓練津貼（服務頁）",
    "url": "https://swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/tsp/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "From 1 Oct 2026, new applicants for the O-place (on-site pre-school rehabilitation service) can no longer apply for the T-place subsidy — because the O-place has reached zero waiting.",
    "quote_en": "As the 'On-site Pre-school Rehabilitation Service' has reached zero waiting, from 1 October 2026 children newly applying for the 'On-site Pre-school Rehabilitation Service' are not beneficiaries of the 'Training Subsidy Programme'.",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme (service page)",
    "locator_en": "Note 1"
  },
  {
    "assertion_id": "A-013",
    "topic": "subsidy",
    "quote": "隨着「校本支援模式」逐步推行，「幼稚園暨幼兒中心兼收計劃」的合資格兒童將可直接透過校本支援模式獲得服務，無需經中央轉介系統輪候。因此，由2027年4月1日起，新申請「幼稚園暨幼兒中心兼收計劃」的兒童並不是「學習訓練津貼」的受惠對象。",
    "plain_tc": "从 2027 年 4 月 1 日起，新申请 I 位（兼收计划）的孩子也不再是 T 位津贴的受惠对象——因为 I 位会改由校本支援模式直接提供服务，不用再排队。",
    "locator": "註二",
    "org": "社署",
    "title_tc": "為輪候資助學前康復服務的兒童提供學習訓練津貼（服務頁）",
    "url": "https://swd.gov.hk/tc/pubsvc/rehab/cat_serpresch/tsp/",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "From 1 Apr 2027, new applicants for the I-place (integrated programme) are no longer eligible for the T-place subsidy — because the I-place will be served directly through the school-based support model without queueing.",
    "quote_en": "With the progressive implementation of the 'School-based Support Model', eligible children of the 'Integrated Programme in Kindergarten-cum-Child Care Centre' will receive services directly through the school-based support model without going through the Central Referral System. Therefore, from 1 April 2027, children newly applying for the 'Integrated Programme in Kindergarten-cum-Child Care Centre' are not beneficiaries of the 'Training Subsidy Programme'.",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme (service page)",
    "locator_en": "Note 2"
  },
  {
    "assertion_id": "A-016",
    "topic": "subsidy",
    "quote": "每月六節共六小時由特殊幼兒工作員、臨床／教育心理學家或職業／物理／言語治療師提供的個別或小組訓練／治療服務（包括有父母／監護人／照顧者同時參與的平衡小組），其中包括每六個月最少十八小時由職業／物理／言語治療師提供的訓練／治療服務；",
    "plain_tc": "高额津贴（等 S 位的孩子）实际买到的是：每月 6 节共 6 小时训练或治疗，其中每 6 个月至少 18 小时由职业／物理／言语治疗师提供。",
    "locator": "第1頁．資助水平及服務（高額津貼）",
    "org": "社署",
    "title_tc": "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/TSP%20Service%20Brief_Chi_202610.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The higher subsidy (for children waiting for an S-place) buys: 6 sessions totalling 6 hours per month of individual or group training/therapy, including at least 18 hours every 6 months by occupational/physiotherapists or speech therapists.",
    "quote_en": "Six sessions totalling six hours per month of individual or group training/therapy services provided by special child care workers, clinical/educational psychologists or occupational/physiotherapists/speech therapists (including balanced groups with parents/guardians/carers), of which at least eighteen hours every six months are provided by occupational/physiotherapists/speech therapists;",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "locator_en": "p.1 Subsidy levels and services (higher subsidy)"
  },
  {
    "assertion_id": "A-018",
    "topic": "subsidy",
    "quote": "按家庭人數釐定的家庭住戶每月收入中位數 (港元) (二零二六年第二季) (只適用於申請「學習訓練津貼」的入息審查)\n1｜$8,250\n2｜$18,000\n3｜$30,300\n4｜$40,800\n5或以上｜$39,225",
    "plain_tc": "申请 T 位津贴的入息门槛是「家庭每月收入不超过住户每月收入中位数的 75%」。2026 年第二季的数字：1 人 $8,250、2 人 $18,000、3 人 $30,300、4 人 $40,800、5 人或以上 $39,225。等 S 位的家庭免入息审查。",
    "locator": "單頁表格（逐格抄錄，非連續句子）",
    "org": "社署（資料源自政府統計處）",
    "title_tc": "按家庭人數釐定的家庭住戶每月收入中位數——百分之七十五（二零二六年第二季）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/MMDHI_2026Q2_CHI.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The income threshold for the T-place subsidy is 'household monthly income not exceeding 75% of the median monthly household income'. 2026 Q2 figures: 1 person $8,250, 2 people $18,000, 3 people $30,300, 4 people $40,800, 5 or more $39,225. Families waiting for an S-place are exempt from the means test.",
    "quote_en": "Median monthly household income by household size (HK$) (2026 Q2) (for the means test of the 'Training Subsidy Programme' only)\n1 | $8,250\n2 | $18,000\n3 | $30,300\n4 | $40,800\n5 or more | $39,225",
    "org_en": "Social Welfare Department (source: Census and Statistics Department)",
    "title_en": "Household Monthly Income Median by household size — 75th percentile (2026 Q2)",
    "locator_en": "Single-page table (transcribed cell by cell, not a continuous sentence)"
  },
  {
    "assertion_id": "A-020",
    "topic": "subsidy",
    "quote": "每月四節共三小時由特殊幼兒工作員、臨床／教育心理學家或職業／物理／言語治療師提供的個別或小組訓練／治療服務（包括有父母／監護人／照顧者同時參與的平衡小組）；",
    "plain_tc": "普通津贴（等 E 位／I 位的孩子）实际买到的是：每月 4 节共 3 小时训练或治疗。",
    "locator": "第1頁．資助水平及服務（普通津貼）",
    "org": "社署",
    "title_tc": "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/TSP%20Service%20Brief_Chi_202610.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "The normal subsidy (for children waiting for an E-place/I-place) buys: 4 sessions totalling 3 hours per month of training or therapy.",
    "quote_en": "Four sessions totalling three hours per month of individual or group training/therapy services provided by special child care workers, clinical/educational psychologists or occupational/physiotherapists/speech therapists (including balanced groups with parents/guardians/carers);",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "locator_en": "p.1 Subsidy levels and services (normal subsidy)"
  },
  {
    "assertion_id": "A-030",
    "topic": "subsidy",
    "quote": "為輪候資助學前康復服務的兒童提供學習訓練津貼提供高額津貼名額服務之認可服務機構名單",
    "plain_tc": "社署公布过认可服务机构名单：领高额津贴（等 S 位）的孩子，可以按这份名单选机构用学习训练津贴；名单最后更新于 2026 年 10 月。",
    "locator": "每頁頁首標題（共12頁）",
    "org": "社署",
    "title_tc": "學習訓練津貼認可服務機構名單（高額津貼）（最後更新 2026年10月）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/Centre%20List_HLS%28CHI%29_20261001.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "SWD has published a list of recognised service operators: children receiving the higher subsidy (waiting for an S-place) can choose an operator from this list to use the Training Subsidy; the list was last updated in October 2026.",
    "quote_en": "List of recognised service operators providing higher-subsidy places under the Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services.",
    "org_en": "Social Welfare Department",
    "title_en": "List of Recognised Service Operators for the Training Subsidy (higher subsidy) (last updated Oct 2026)",
    "locator_en": "Page-header title (12 pages)"
  },
  {
    "assertion_id": "A-031",
    "topic": "subsidy",
    "quote": "為輪候資助學前康復服務的兒童提供學習訓練津貼提供普通額津貼名額服務之認可服務機構名單",
    "plain_tc": "社署公布过认可服务机构名单：领普通额津贴（等 E 位／I 位）的孩子，可以按这份名单选机构用学习训练津贴；名单最后更新于 2026 年 10 月。",
    "locator": "每頁頁首標題（共12頁）",
    "org": "社署",
    "title_tc": "學習訓練津貼認可服務機構名單（普通津貼）（最後更新 2026年10月）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/Centre%20List_NLS%28CHI%29_20261001.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "SWD has published a list of recognised service operators: children receiving the normal subsidy (waiting for an E-place/I-place) can choose an operator from this list to use the Training Subsidy; the list was last updated in October 2026.",
    "quote_en": "List of recognised service operators providing normal-subsidy places under the Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services.",
    "org_en": "Social Welfare Department",
    "title_en": "List of Recognised Service Operators for the Training Subsidy (normal subsidy) (last updated Oct 2026)",
    "locator_en": "Page-header title (12 pages)"
  },
  {
    "assertion_id": "A-008",
    "topic": "transition",
    "quote": "輪候特殊幼兒中心而並未接受上述過渡服務的兒童，可無須經過家庭入息審查申請「為輪候資助學前康復服務的兒童提供學習訓練津貼」。他們可運用津貼使用認可服務機構營辦的自負盈虧的學前康復服務，盡早接受訓練。",
    "plain_tc": "在等 S 位、而且没有在用 E 位或 O 位做过渡的孩子，可以免入息审查申请学习训练津贴（T 位）；用这笔钱去买认可机构的训练服务，早点开始训练。",
    "locator": "第(一)及(二)部分",
    "org": "立法會",
    "title_tc": "立法會二十二題：特殊幼兒中心（2025-03-19 書面答覆）",
    "url": "https://www.info.gov.hk/gia/general/202503/19/P2025031900202.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "Children waiting for an S-place who are not using transition services can apply for the Training Subsidy (T-place) without a means test, and use the subsidy to buy self-financed pre-school rehabilitation services from recognised operators to start training sooner.",
    "quote_en": "Children waiting for a Special Child Care Centre who are not receiving the above transition services may apply for the 'Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services' without a household means test. They can use the subsidy to access self-financed pre-school rehabilitation services operated by recognised service operators to start training as early as possible.",
    "org_en": "Legislative Council",
    "title_en": "Legislative Council Question 22: Special child care centres (19 Mar 2025 written reply)",
    "locator_en": "Parts (1) and (2)"
  },
  {
    "assertion_id": "A-010",
    "topic": "transition",
    "quote": "為了讓有特殊需要的兒童盡早獲得訓練及支援，他們可在輪候特殊幼兒中心服務期間同時申請及接受早期教育及訓練中心或到校學前康復服務過渡服務，直至獲得編配特殊幼兒中心服務。",
    "plain_tc": "在排队等 S 位的这段时间，孩子可以同时申请和接受 E 位或 O 位的过渡服务，一直用到 S 位有位置为止。也就是说，孩子不用干等。",
    "locator": "第(一)及(二)部分",
    "org": "立法會",
    "title_tc": "立法會二十二題：特殊幼兒中心（2025-03-19 書面答覆）",
    "url": "https://www.info.gov.hk/gia/general/202503/19/P2025031900202.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "While queueing for an S-place, the child can simultaneously apply for and receive an E-place or O-place transition service, until an S-place is allocated. In other words, the child doesn't have to wait idle.",
    "quote_en": "To allow children with special needs to receive training and support as early as possible, they may, while waiting for a Special Child Care Centre place, simultaneously apply for and receive transition services from an Early Education and Training Centre or the On-site Pre-school Rehabilitation Service, until they are allocated a Special Child Care Centre place.",
    "org_en": "Legislative Council",
    "title_en": "Legislative Council Question 22: Special child care centres (19 Mar 2025 written reply)",
    "locator_en": "Parts (1) and (2)"
  },
  {
    "assertion_id": "A-006",
    "topic": "waiting",
    "quote": "Upon receipt of vacancy reports from service units, the System will select eligible children on the waiting list for admission to the services according to the order of their dates of application and location preference normally.",
    "plain_tc": "轮候是按申请日期的先后排序的（再加上地区选择）。所以早一天登记，就是排在前面一天。",
    "locator": "Remarks (1)",
    "org": "社署",
    "title_tc": "康復服務中央轉介系統 — 輪候資料更新",
    "url": "https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/crsrehabwa",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "Waiting is ordered by application date (plus district preference). So registering one day earlier puts you one place ahead.",
    "quote_en": "Upon receipt of vacancy reports from service units, the System will select eligible children on the waiting list for admission to the services according to the order of their dates of application and location preference normally.",
    "org_en": "Social Welfare Department",
    "title_en": "Central Referral System for Rehabilitation Services — Waiting List Information Updates"
  },
  {
    "assertion_id": "A-014",
    "topic": "waiting",
    "quote": "二○一八／一九年度，各類資助學前康復服務的平均輪候時間如下：\n早期教育及訓練中心｜16.6\n幼稚園暨幼兒中心兼收計劃｜12.6\n特殊幼兒中心｜18.4\n到校學前康復服務｜不適用（註）",
    "plain_tc": "官方自己算过平均轮候：2018/19 年度，E 位 16.6 个月、I 位 12.6 个月、S 位 18.4 个月。",
    "locator": "回覆(二)及(三)．學前康復服務表",
    "org": "立法會",
    "title_tc": "立法會十八題：支援有特殊需要的兒童（2020-02-26 書面答覆）",
    "url": "https://www.info.gov.hk/gia/general/202002/26/P2020022600495.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "Officially computed average waits: in 2018/19, E-place 16.6 months, I-place 12.6 months, S-place 18.4 months.",
    "quote_en": "In 2018/19, the average waiting times of various subsidised pre-school rehabilitation services were as follows:\nEarly Education and Training Centre | 16.6\nIntegrated Programme in Kindergarten-cum-Child Care Centre | 12.6\nSpecial Child Care Centre | 18.4\nOn-site Pre-school Rehabilitation Service | Not applicable (note)",
    "org_en": "Legislative Council",
    "title_en": "Legislative Council Question 18: Support for children with special needs (26 Feb 2020 written reply)",
    "locator_en": "Reply (2) and (3), Pre-school rehabilitation services table"
  },
  {
    "assertion_id": "A-019",
    "topic": "waiting",
    "quote": "惟受惠兒童拒絕接受中央轉介系統編配的服務後，其資助學前康復服務的申請將會從輪候名單中移除。",
    "plain_tc": "在使用 T 位津贴期间，如果孩子被编配到服务而你拒绝了，资助学前康复服务的申请会被从轮候名单中移除——等于要重新排队。",
    "locator": "第1頁．經中央轉介系統編配服務",
    "org": "社署",
    "title_tc": "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）",
    "url": "https://www.swd.gov.hk/storage/asset/section/306/tc/TSP%20Service%20Brief_Chi_202610.pdf",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "While using the T-place subsidy, if you are allocated a service and refuse it, the child's subsidised pre-school rehabilitation application will be removed from the waiting list — meaning you have to queue again.",
    "quote_en": "However, if a beneficiary child refuses a service allocated through the Central Referral System, the child's application for subsidised pre-school rehabilitation services will be removed from the waiting list.",
    "org_en": "Social Welfare Department",
    "title_en": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "locator_en": "p.1 Service allocation via the Central Referral System"
  },
  {
    "assertion_id": "A-028",
    "topic": "waiting",
    "quote": "註：平均輪候時間是按財政年度計算（即由每年的四月一日至翌年的三月三十一日），由於到校學前康復服務於二○一八年十月常規化，因此沒有整個二○一八至一九年度的統計數字。",
    "plain_tc": "表下注：平均轮候时间按财政年度计算（每年 4 月 1 日到翌年 3 月 31 日）；因为到校学前康复服务 2018 年 10 月才常规化，所以没有 2018/19 全年度的统计数字。",
    "locator": "回覆(二)及(三)．學前康復服務表下註",
    "org": "立法會",
    "title_tc": "立法會十八題：支援有特殊需要的兒童（2020-02-26 書面答覆）",
    "url": "https://www.info.gov.hk/gia/general/202002/26/P2020022600495.htm",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "Note under the table: average waiting time is computed by financial year (1 Apr to 31 Mar); because the On-site Pre-school Rehabilitation Service was regularised in October 2018, there is no full 2018/19 figure.",
    "quote_en": "Note: Average waiting time is computed by financial year (i.e. from 1 April each year to 31 March the following year). As the On-site Pre-school Rehabilitation Service was regularised in October 2018, there is no full-year 2018/19 figure.",
    "org_en": "Legislative Council",
    "title_en": "Legislative Council Question 18: Support for children with special needs (26 Feb 2020 written reply)",
    "locator_en": "Note under the pre-school rehabilitation services table, Reply (2) and (3)"
  },
  {
    "assertion_id": "A-001",
    "topic": "waiting_support",
    "quote": "測驗服務亦會為家長提供短期過渡性支援服務，例如講座、工作坊及訓練課程等，加深家長對子女情況的認識，協助他們掌握更有效的方法照顧子女，從而進行家居訓練，協助兒童發展成長。",
    "plain_tc": "在等候评估和服务的这段时间，官方提供的是讲座、工作坊、训练课程这类过渡支援；而在家给孩子做训练，是由家长自己承担的。",
    "locator": "第六段（儿童体能智力测验服务一节）",
    "org": "政府新聞網（食衞局）",
    "title_tc": "《齊心支援 讓兒童健康成長》",
    "url": "https://www.news.gov.hk/chi/2019/10/20191003/20191003_110945_673.html",
    "captured_on": "2026-10-07",
    "source_status": "active",
    "plain_en": "While waiting for assessment and services, the official support is transition support such as talks, workshops and training courses; home training for the child is the parents' own responsibility.",
    "quote_en": "The Assessment Service also provides parents with short-term transitional support services, such as talks, workshops and training courses, to deepen parents' understanding of their child's condition and help them master more effective ways of caring for their child, so as to carry out home training and support the child's development.",
    "org_en": "Government news portal (Food and Health Bureau)",
    "title_en": "Supporting children to grow up healthy",
    "locator_en": "Paragraph 6 (Child Assessment Service section)"
  }
]
"""#,
"glossary": #"""
[
  {
    "term": "CAC／測驗中心",
    "full_tc": "衞生署兒童體能智力測驗中心",
    "code": "CAS",
    "plain_tc": "做评估的地方，不是做训练的地方。全港有 7 间，按住址分地区。要医生或心理学家写转介信才能去。",
    "source_id": "SRC-001",
    "full_en": "Child Assessment Centre, Department of Health",
    "plain_en": "Where assessment happens, not training. 7 across Hong Kong, by district. You need a referral letter from a doctor or psychologist.",
    "term_en": "CAC"
  },
  {
    "term": "EETC",
    "full_tc": "早期教育及訓練中心",
    "code": "E",
    "plain_tc": "早期教育及訓練中心的英文缩写，官方轮候数据集用这个名，就是「E位」。",
    "source_id": "SRC-012",
    "full_en": "Early Education and Training Centre",
    "plain_en": "The English abbreviation for Early Education and Training Centre, used in the official waiting dataset — the 'E-place'.",
    "term_en": "EETC"
  },
  {
    "term": "E位",
    "full_tc": "早期教育及訓練中心",
    "code": "E",
    "plain_tc": "像补习班：每星期去几次，每次一小时左右，由治疗师或特殊幼儿老师做个别训练。适合程度较轻、还在家里或普通幼儿园的孩子。",
    "source_id": "SRC-003",
    "full_en": "Early Education and Training Centre",
    "plain_en": "Like tutoring: a few visits a week, about an hour each, one-to-one training by therapists or special child care workers. For children with milder needs who are at home or in a mainstream kindergarten.",
    "term_en": "EETC"
  },
  {
    "term": "I位",
    "full_tc": "幼稚園暨幼兒中心兼收計劃",
    "code": "I",
    "plain_tc": "在普通幼儿园里给轻度弱能的孩子加训练和照顾，让孩子跟一般孩子一起上学。",
    "source_id": "SRC-009",
    "full_en": "Integrated Programme in Kindergarten-cum-Child Care Centre",
    "plain_en": "Adds training and care for mildly disabled children within a mainstream kindergarten, so they attend with typically developing peers.",
    "term_en": "ICCC"
  },
  {
    "term": "OPRS",
    "full_tc": "到校學前康復服務",
    "code": "O",
    "plain_tc": "到校學前康復服務的英文缩写，家长口中的「O位」就是它。",
    "source_id": "SRC-007",
    "full_en": "On-site Pre-school Rehabilitation Services",
    "plain_en": "The abbreviation for On-site Pre-school Rehabilitation Services — the 'O-place'.",
    "term_en": "OPRS"
  },
  {
    "term": "O位",
    "full_tc": "到校學前康復服務",
    "code": "O",
    "plain_tc": "NGO 的跨专业团队直接到幼儿园给孩子做训练，家长不用自己带孩子跑中心。已经做到零等候。",
    "source_id": "SRC-007",
    "full_en": "On-site Pre-school Rehabilitation Services",
    "plain_en": "An NGO multidisciplinary team delivers training directly at the kindergarten, so parents don't shuttle children to a centre. Already at 'zero waiting'.",
    "term_en": "OPRS"
  },
  {
    "term": "SCCC",
    "full_tc": "特殊幼兒中心",
    "code": "S",
    "plain_tc": "特殊幼兒中心的英文缩写，官方轮候数据集用这个名，就是「S位」。",
    "source_id": "SRC-013",
    "full_en": "Special Child Care Centre",
    "plain_en": "The abbreviation for Special Child Care Centre, used in the official waiting dataset — the 'S-place'.",
    "term_en": "SCCC"
  },
  {
    "term": "S位",
    "full_tc": "特殊幼兒中心",
    "code": "S",
    "plain_tc": "像全日制特教幼儿园：孩子每天去，全天由跨专业团队做训练和照顾。收 2–6 岁中度至严重的残疾儿童，自闭症通常在评估后归到这条线。",
    "source_id": "SRC-003",
    "full_en": "Special Child Care Centre",
    "plain_en": "Like a full-day special kindergarten: the child attends daily for all-day training and care by a multidisciplinary team. For ages 2–6 with moderate to severe disabilities; autism is usually placed here after assessment.",
    "term_en": "SCCC"
  },
  {
    "term": "S位＋住宿",
    "full_tc": "住宿特殊幼兒中心",
    "code": "SR",
    "plain_tc": "跟 S 位一样，但连住宿也包。全港只有 6 所，轮候通常更久。",
    "source_id": "SRC-008",
    "full_en": "Residential Special Child Care Centre",
    "plain_en": "Same as S-place but with residential care. Only 6 territory-wide; waits are usually longer.",
    "term_en": "RSCCC"
  },
  {
    "term": "TSP",
    "full_tc": "學習訓練津貼",
    "code": "T",
    "plain_tc": "學習訓練津貼的英文缩写，就是「T位」。",
    "source_id": "SRC-005",
    "full_en": "Training Subsidy Programme",
    "plain_en": "The abbreviation for the Training Subsidy Programme — the 'T-place'.",
    "term_en": "TSP"
  },
  {
    "term": "T位",
    "full_tc": "學習訓練津貼",
    "code": "T",
    "plain_tc": "不是服务，是钱。在排队的期间，用现金津贴去买认可机构的训练课。分普通和高额两档。",
    "source_id": "SRC-005",
    "full_en": "Training Subsidy Programme",
    "plain_en": "Not a service, but money. While queueing, use the cash subsidy to buy training sessions from recognised operators. Two tiers: normal and higher.",
    "term_en": "TSP"
  },
  {
    "term": "中央轉介系統／CRSRS",
    "full_tc": "康復服務中央轉介系統（學前兒童康復服務子系統）",
    "code": null,
    "plain_tc": "排队的那个系统。所有政府资助的学前康复服务都从这里分配。★「排上队」＝在这里完成登记，不是看完医生就算。",
    "source_id": "SRC-004",
    "full_en": "Central Referral System for Rehabilitation Services (pre-school children sub-system)",
    "plain_en": "The queueing system. All government-subsidised pre-school rehabilitation services are allocated here. 'Getting on the list' means completing registration here, not merely seeing a doctor.",
    "term_en": "Central Referral System (CRSRS)"
  },
  {
    "term": "住宿S位",
    "full_tc": "住宿特殊幼兒中心",
    "code": null,
    "plain_tc": "连住宿也包的特殊幼儿中心，全港只有6所，轮候通常更久。",
    "source_id": "SRC-008",
    "full_en": "Residential Special Child Care Centre",
    "plain_en": "A special child care centre that also provides residential care. Only 6 territory-wide; waits usually longer.",
    "term_en": "RSCCC"
  },
  {
    "term": "個案工作員",
    "full_tc": "社會福利署／非政府機構之個案工作員",
    "code": null,
    "plain_tc": "帮你办手续的社工。转介信、中央转介系统登记，多数由他们手上过。",
    "source_id": "SRC-009",
    "full_en": "Case worker of the Social Welfare Department / NGO",
    "plain_en": "The social worker who handles your paperwork. Referral letters and Central Referral System registration mostly pass through them.",
    "term_en": "Case worker"
  },
  {
    "term": "兼收計劃",
    "full_tc": "幼稚園暨幼兒中心兼收計劃",
    "code": null,
    "plain_tc": "让轻度弱能的孩子在普通幼儿园里边上学边接受训练。",
    "source_id": "SRC-005",
    "full_en": "Integrated Programme in Kindergarten-cum-Child Care Centre",
    "plain_en": "Lets mildly disabled children attend a mainstream kindergarten while receiving training.",
    "term_en": "Integrated Programme"
  },
  {
    "term": "普通津貼",
    "full_tc": "學習訓練津貼（普通津貼）",
    "code": null,
    "plain_tc": "T位津贴的普通档，给入息稍高的家庭。",
    "source_id": "SRC-018",
    "full_en": "Training Subsidy Programme (normal subsidy)",
    "plain_en": "The normal tier of the T-place subsidy, for households with slightly higher income.",
    "term_en": "Normal subsidy"
  },
  {
    "term": "輪候期間的過渡服務",
    "full_tc": "過渡性服務",
    "code": null,
    "plain_tc": "等 S 位的时候，同时间可以用 E 位或 O 位顶上，一直用到 S 位有位。★ 很多家长完全不知道这条。",
    "source_id": "SRC-008",
    "full_en": "Transitional services",
    "plain_en": "While waiting for an S-place, you can simultaneously use an E-place or O-place until an S-place opens. Many parents don't know this at all.",
    "term_en": "Transitional services"
  },
  {
    "term": "醫務社工",
    "full_tc": "社署／醫院管理局之醫務社會工作員",
    "code": null,
    "plain_tc": "驻在医院的社工。如果孩子走的是医院那条线，通常是他们帮你转介，并附带心理报告、医生报告。",
    "source_id": "SRC-014",
    "full_en": "Medical social worker of the Social Welfare Department / Hospital Authority",
    "plain_en": "A social worker based in a hospital. If your child is on the hospital route, they usually make the referral with psychological and medical reports.",
    "term_en": "Medical social worker"
  },
  {
    "term": "預早登記",
    "full_tc": "預早登記計劃",
    "code": null,
    "plain_tc": "未满2岁就可以先排队的机制，不用等到2岁才入队。",
    "source_id": "SRC-003",
    "full_en": "Advance registration scheme",
    "plain_en": "A mechanism to join the queue before age 2, so you don't wait until the child turns 2.",
    "term_en": "Advance registration"
  },
  {
    "term": "高額津貼",
    "full_tc": "學習訓練津貼（高額津貼）",
    "code": null,
    "plain_tc": "T位津贴的高额档，给入息较低的家庭。",
    "source_id": "SRC-017",
    "full_en": "Training Subsidy Programme (higher subsidy)",
    "plain_en": "The higher tier of the T-place subsidy, for households with lower income.",
    "term_en": "Higher subsidy"
  }
]
"""#,
"manifest": #"""
{
  "built_on": "2026-10-16",
  "db_file": "phase1.db",
  "content_fingerprint": "0ae157aa8e0a22c8",
  "fingerprint_note": "内容指纹＝schema.sql ＋ 全部 seed CSV 的 sha256 前 16 位。算法：按文件名排序，每个文件先写入文件名、再写入文件内容，最后取 sha256 的前 16 位。同样的 seed 一定得到同样的指纹，与生成时间无关。交付或答辩时报出这个值，即可证明双方手上是同一版数据。",
  "contract": "本目錄為只讀快照。開發同學請勿寫入；發現資料問題請回報，由資料層重新建庫導出。",
  "counts": {
    "source": 23,
    "assertion": 32,
    "service_type": 7,
    "service_unit": 124,
    "waiting_snapshot": 124,
    "pathway_step": 7,
    "checklist_item": 10,
    "glossary": 20,
    "red_flag": 5
  },
  "only_active_guarantee": "citable_assertions.json 只含 status=active 且來源 active 的條目；未核對的一律不出現在產品輸出裡。"
}
"""#,
"pathway_steps": #"""
[
  {
    "step_no": 1,
    "name_tc": "察覺不對路（語言／社交／行為里程碑落後）",
    "who_acts_tc": "家長／照顧者／幼稚園老師",
    "preconditions": "—",
    "duration_note": "家长多在孩子 1.5–4 岁之间开始起疑",
    "friction_tc": "不知道这算不算问题、算不算严重；怕被说是坏家长；身边人说「大个就会好」",
    "plain_tc": "这一步没有任何官方入口。家长全靠自己判断——所以最容易被拖几个月。",
    "status": "active",
    "name_en": "Noticing something is off (delays in language / social / behavioural milestones)",
    "who_acts_en": "Parent / carer / kindergarten teacher",
    "preconditions_en": "—",
    "duration_note_en": "Parents usually start to wonder between 1.5 and 4 years old",
    "friction_en": "Not sure whether it counts as a problem or how serious it is; fear of being seen as a bad parent; others saying 'they'll grow out of it'",
    "plain_en": "This step has no official entry point. Parents are entirely on their own to judge — so it is easiest to be delayed by months."
  },
  {
    "step_no": 2,
    "name_tc": "找專業人士開轉介信",
    "who_acts_tc": "家長 → 私家醫生／家庭醫生／心理學家／母嬰健康院",
    "preconditions": "孩子的發展疑慮已向專業人士提出",
    "duration_note": "取决于能否约到医生",
    "friction_tc": "不知道「要医生转介才能评估」这条规则，白等；平日看开的家庭医生不一定愿意写",
    "plain_tc": "要带孩子去做评估，先得有一封医生或心理学家写的转介信。家长自己不能直接去测验中心排队。",
    "status": "active",
    "name_en": "Getting a referral letter from a professional",
    "who_acts_en": "Parent → private doctor / family doctor / psychologist / Maternal & Child Health Centre",
    "preconditions_en": "The child's developmental concerns have been raised with a professional",
    "duration_note_en": "Depends on whether you can get a doctor's appointment",
    "friction_en": "Not knowing the rule that 'a doctor's referral is required for assessment', and waiting in vain; the usual family doctor may not be willing to write one",
    "plain_en": "To take a child for assessment, you first need a referral letter from a doctor or psychologist. Parents cannot queue at the assessment centre directly."
  },
  {
    "step_no": 3,
    "name_tc": "到衞生署兒童體能智力測驗中心登記及評估",
    "who_acts_tc": "家長帶孩子前往；測驗中心跨專業團隊執行",
    "preconditions": "已持有專業人士轉介信",
    "duration_note": "官方口径：新症登記後三個星期內獲約見（2019年数字）",
    "friction_tc": "不知道要带哪些文件、不知道首次要收费、不知道要带孩子近照和健康院纪录簿",
    "plain_tc": "带齐材料到所属地区的测验中心登记，中心会安排时间给孩子做全面评估。",
    "status": "active",
    "name_en": "Registering and assessment at the Department of Health Child Assessment Centre",
    "who_acts_en": "Parent brings the child; the centre's multidisciplinary team carries it out",
    "preconditions_en": "Already holds a professional referral letter",
    "duration_note_en": "Official figure: an appointment within three weeks of registration for new cases (2019 figure)",
    "friction_en": "Not knowing which documents to bring, that the first visit has a fee, and to bring a recent photo and the health centre record book",
    "plain_en": "Bring all the documents to register at the assessment centre for your district; the centre will arrange a time for a comprehensive assessment."
  },
  {
    "step_no": 4,
    "name_tc": "評估結果與轉介決定",
    "who_acts_tc": "測驗中心評估團隊",
    "preconditions": "評估已完成",
    "duration_note": "—",
    "friction_tc": "不知道评估之后会发生什么、要等多久、会不会有跟进",
    "plain_tc": "评估完，医生会按孩子的情况决定把他转介去哪条服务线——这一步决定了后面排哪条队。",
    "status": "active",
    "name_en": "Assessment result and referral decision",
    "who_acts_en": "The assessment centre's assessment team",
    "preconditions_en": "Assessment completed",
    "duration_note_en": "—",
    "friction_en": "Not knowing what happens after assessment, how long to wait, or whether there will be follow-up",
    "plain_en": "After assessment, the doctor decides which service route to refer the child to — this step determines which queue you join next."
  },
  {
    "step_no": 5,
    "name_tc": "在康復服務中央轉介系統（CRSRS）登記入隊",
    "who_acts_tc": "轉介人（社工／醫務社工／康復服務單位工作人員）代為登記",
    "preconditions": "已有評估結果（附心理報告／醫生報告）",
    "duration_note": "—",
    "friction_tc": "★ 家长常常以为「看完医生就等于排上队了」，其实要等社工完成中央转介系统登记才算；中间的空档没人告知",
    "plain_tc": "由社工把你的申请录进中央转介系统，这才是真正「排上队」的时刻。★ 入队用时这个指标，就量到这里。",
    "status": "active",
    "name_en": "Registering on the Central Referral System (CRSRS)",
    "who_acts_en": "The referrer (social worker / medical social worker / rehabilitation unit staff) registers on the family's behalf",
    "preconditions_en": "Assessment result already available (with psychological/medical reports)",
    "duration_note_en": "—",
    "friction_en": "Parents often think 'seeing the doctor means you're on the list', but you're only on the list once a social worker completes Central Referral System registration; nobody tells you about the gap in between",
    "plain_en": "A social worker enters your application into the Central Referral System — this is the moment you are truly 'on the list'. The 'time to get on the list' metric is measured up to here."
  },
  {
    "step_no": 6,
    "name_tc": "輪候期間的過渡安排（E位／O位／T位津貼）",
    "who_acts_tc": "家長申請；社工協助",
    "preconditions": "已列入中央轉介系統輪候名單",
    "duration_note": "最长可持续到 S 位有位置为止",
    "friction_tc": "★ 绝大多数家长不知道：等 S 位期间可以同时上 E 位或 O 位；没在用过渡服务的还可以免入息审查领 T 位津贴",
    "plain_tc": "在等 S 位的这段时间，孩子可以同时申请 E 位或 O 位过渡；如果没用过渡服务，还可以申请学习训练津贴（T 位）去买训练。孩子不用干等。",
    "status": "active",
    "name_en": "Transition arrangements while waiting (E-place / O-place / T-place subsidy)",
    "who_acts_en": "Parent applies; social worker assists",
    "preconditions_en": "Already on the Central Referral System waiting list",
    "duration_note_en": "Can last until an S-place becomes available",
    "friction_en": "Most parents don't know: while waiting for an S-place you can simultaneously use an E-place or O-place; and if not using a transition service you can receive the T-place subsidy without a means test",
    "plain_en": "While waiting for an S-place, the child can simultaneously apply for an E-place or O-place transition; and if not using a transition service, you can apply for the Training Subsidy (T-place) to buy training. The child doesn't have to wait idle."
  },
  {
    "step_no": 7,
    "name_tc": "獲編配服務（或變更服務類別／中心選擇）",
    "who_acts_tc": "中央轉介系統按申請日期先後及地區選擇編配",
    "preconditions": "輪候名單中、符合基本入讀條件（含年滿2歲）",
    "duration_note": "—",
    "friction_tc": "不知道中间可以更改服务类别或中心选择；不知道搬家／转区要重新排队与否",
    "plain_tc": "有位置了，系统会按你申请日期的先后、加上你选的地区来分配。",
    "status": "active",
    "name_en": "Service allocation (or changing service type / centre choice)",
    "who_acts_en": "The Central Referral System allocates by application date and district preference",
    "preconditions_en": "On the waiting list and meeting basic admission conditions (including age 2)",
    "duration_note_en": "—",
    "friction_en": "Not knowing you can change service type or centre choice midway; not knowing whether moving house / changing district requires requeueing",
    "plain_en": "When a place opens, the system allocates it by your application date order plus your district preference."
  }
]
"""#,
"red_flags": #"""
[
  {
    "flag_id": "RF-001",
    "signal_tc": "孩子出現自傷行為（撞頭、咬自己、抓傷自己）或對他人有攻擊行為",
    "route_tc": "立即聯絡孩子的主診醫生；情況緊急時到就近急症室或致電 999",
    "route_contact": "999（緊急）｜社署熱線 2343 2255（24 小時）",
    "never_say_tc": "絕對不可以說「這是自閉症的典型行為，忍一忍就好」或「大個就會好」。系統不判斷行為的成因，只把家長帶到真人專業支援。",
    "source_id": "SRC-020",
    "status": "active",
    "signal_en": "The child shows self-injury (head-banging, biting, scratching) or aggression toward others",
    "route_en": "Contact the child's treating doctor immediately; in an emergency go to the nearest A&E or call 999",
    "route_contact_en": "999 (emergency) | SWD hotline 2343 2255 (24 hours)",
    "never_say_en": "Never say 'this is typical autistic behaviour, just endure it' or 'they'll grow out of it'. The system does not judge the cause of the behaviour; it only directs the parent to real human professional support."
  },
  {
    "flag_id": "RF-002",
    "signal_tc": "孩子出現抽搐、意識改變、突然無法喚醒或呼吸異常",
    "route_tc": "立即致電 999 或前往急症室",
    "route_contact": "999",
    "never_say_tc": "不要作任何解釋性或安撫性的判斷。系統只做轉送，不評論症狀。",
    "source_id": "SRC-020",
    "status": "active",
    "signal_en": "The child has convulsions, altered consciousness, suddenly cannot be woken, or abnormal breathing",
    "route_en": "Call 999 or go to A&E immediately",
    "route_contact_en": "999",
    "never_say_en": "Do not make any explanatory or reassuring judgement. The system only routes, and does not comment on symptoms."
  },
  {
    "flag_id": "RF-003",
    "signal_tc": "孩子出現能力倒退——本來會講的字詞、本來會做的動作消失了",
    "route_tc": "盡快約見家庭醫生或母嬰健康院，並要求轉介至衞生署兒童體能智力測驗服務評估",
    "route_contact": "衞生署兒童體能智力測驗服務（需醫生或心理學家轉介）",
    "never_say_tc": "不可以說「退步是正常的」或「等等看」。能力倒退需要真人評估，不需要系統意見。",
    "source_id": "SRC-001",
    "status": "active",
    "signal_en": "The child shows skill regression — previously spoken words or performed actions disappear",
    "route_en": "See a family doctor or Maternal & Child Health Centre soon and ask for referral to the Department of Health Child Assessment Service",
    "route_contact_en": "Department of Health Child Assessment Service (referral by doctor or psychologist required)",
    "never_say_en": "Do not say 'regression is normal' or 'wait and see'. Skill regression needs real human assessment, not an app's opinion."
  },
  {
    "flag_id": "RF-004",
    "signal_tc": "照顧者出現自傷念頭、情緒崩潰、或表示「撐不下去」",
    "route_tc": "即時尋求真人支援：社署熱線、醫院管理局精神健康專線、防止自殺會熱線，或前往就近急症室",
    "route_contact": "社署熱線 2343 2255（24 小時）｜醫院管理局精神健康專線 2466 7350（24 小時）｜生命熱線 2382 0000（24 小時）｜香港撒瑪利亞防止自殺會 2389 2222（24 小時）｜明愛向晴軒 18288（24 小時）｜緊急：999／急症室",
    "never_say_tc": "絕對不可以評價家長（例如「你要正面啲」）。家長在崩潰時最不需要的就是被評判——這是本项目文案的第一条红线。",
    "source_id": "SRC-021",
    "status": "active",
    "signal_en": "The caregiver has thoughts of self-harm, emotional breakdown, or says they 'can't carry on'",
    "route_en": "Seek real human support immediately: SWD hotline, Hospital Authority mental health hotline, suicide prevention hotline, or go to the nearest A&E",
    "route_contact_en": "SWD hotline 2343 2255 (24h) | HA Mental Health Direct 2466 7350 (24h) | Suicide Prevention Services 2382 0000 (24h) | The Samaritans HK 2389 2222 (24h) | Caritas Family Crisis Line 18288 (24h) | Emergency: 999 / A&E",
    "never_say_en": "Never judge the parent (e.g. 'think positive'). The last thing a parent in breakdown needs is to be judged — this is the first red line of this project's copy."
  },
  {
    "flag_id": "RF-005",
    "signal_tc": "家長要求系統判斷「我的孩子是不是自閉症」",
    "route_tc": "明確表示不做診斷，並導向衞生署兒童體能智力測驗服務的正式評估（需經醫生或心理學家轉介）",
    "route_contact": "衞生署兒童體能智力測驗服務",
    "never_say_tc": "不可以說「你的孩子應該是自閉症」或任何暗示診斷的表述。系統只整理事實、呈現資訊；判斷權在專業評估。",
    "source_id": "SRC-001",
    "status": "active",
    "signal_en": "The parent asks the system to judge 'is my child autistic'",
    "route_en": "Clearly state that the app does not diagnose, and direct to formal assessment at the Department of Health Child Assessment Service (referral by doctor or psychologist required)",
    "route_contact_en": "Department of Health Child Assessment Service",
    "never_say_en": "Do not say 'your child is probably autistic' or any expression implying diagnosis. The system only organises facts and presents information; the judgement belongs to professional assessment."
  }
]
"""#,
"service_types": #"""
[
  {
    "code": "CAS",
    "alias_tc": "CAC／測驗中心",
    "name_tc": "衞生署兒童體能智力測驗服務",
    "name_en": "Child Assessment Service (CAS), Department of Health",
    "age_min_m": 0,
    "age_max_m": 143,
    "intensity_tc": "評估與診斷（非訓練）",
    "target_tc": "12歲以下有發展障礙或行為問題的兒童",
    "referral_tc": "經專業人士（如醫生、心理學家）或經醫院直接轉介",
    "fee_tc": "待核实",
    "wait_note_tc": "官方口径：新症登記後三個星期內獲得約見（2019年数字，须标年份）",
    "source_id": "SRC-001",
    "notes_tc": "★ 这是整条家长旅程的第一道门。服务对象是12岁以下，但往社署学前康复服务的转介只覆盖6岁以下——0-6口径的由来",
    "target_en": "Children under 12 with developmental disabilities or behavioural problems",
    "intensity_en": "Assessment and diagnosis (not training)",
    "referral_en": "Referral by a professional (e.g. doctor, psychologist) or directly through a hospital",
    "fee_en": "To be confirmed",
    "wait_note_en": "Official figure: new registrations are offered an appointment within three weeks (2019 figure — state the year)",
    "notes_en": "The first door of the whole parent journey. The service covers children under 12, but referral to SWD pre-school rehabilitation only covers under 6 — the origin of the 0–6 scope.",
    "alias_en": "CAS"
  },
  {
    "code": "E",
    "alias_tc": "E位",
    "name_tc": "早期教育及訓練中心",
    "name_en": "Early Education and Training Centre (EETC)",
    "age_min_m": 0,
    "age_max_m": 71,
    "intensity_tc": "部分時間制（每次以小時計，如補習堂形式）",
    "target_tc": "初生至6歲以下、程度相對較輕的發展障礙兒童（0至2歲亦接受）",
    "referral_tc": "經社工或康復服務單位工作人員轉介至社署康復服務中央轉介系統",
    "fee_tc": "待核实（官方页未取到收费表述）",
    "wait_note_tc": "2026-08 逐间复算：64 间中心中 38 间显示当月派位，中位数 0 个月，最长 6 个月",
    "source_id": "SRC-012",
    "notes_tc": "家长圈最重要的行话之一。E位可作等 S 位期间的过渡服务",
    "target_en": "Children from birth to under 6 with relatively mild developmental disabilities (ages 0–2 also accepted)",
    "intensity_en": "Part-time (hourly sessions, like tutoring)",
    "referral_en": "Referral by a social worker or rehabilitation service unit staff to the SWD Central Referral System",
    "fee_en": "To be confirmed (no fee statement captured from the official page)",
    "wait_note_en": "Recalculated per centre (Aug 2026): 38 of 64 centres show a placement that month; median 0 months, longest 6 months",
    "notes_en": "One of the most important terms in parent circles. E-place can be used as a transition service while waiting for an S-place.",
    "alias_en": "EETC"
  },
  {
    "code": "I",
    "alias_tc": "I位",
    "name_tc": "幼稚園暨幼兒中心兼收計劃",
    "name_en": "Integrated Programme in Kindergarten-cum-Child Care Centre (ICCC)",
    "age_min_m": 24,
    "age_max_m": 71,
    "intensity_tc": "在普通幼稚園／幼兒中心內提供訓練和照顧",
    "target_tc": "輕度弱能兒童",
    "referral_tc": "經中央轉介系統",
    "fee_tc": "待核实",
    "wait_note_tc": "官方口径 2018/19 年度平均輪候 12.6 個月（历史数字，须标年份）",
    "source_id": "SRC-009",
    "notes_tc": "⚠️ 由2027-04-01起新申請者不再是學習訓練津貼受惠對象（见 SRC-005 注二）",
    "target_en": "Children with mild disabilities",
    "intensity_en": "Training and care within a mainstream kindergarten/child care centre",
    "referral_en": "Via the Central Referral System",
    "fee_en": "To be confirmed",
    "wait_note_en": "Official figure: average wait 12.6 months in 2018/19 (historical — state the year)",
    "notes_en": "From 1 Apr 2027 new applicants are no longer eligible for the Training Subsidy (see SRC-005 note 2).",
    "alias_en": "ICCC"
  },
  {
    "code": "O",
    "alias_tc": "O位",
    "name_tc": "到校學前康復服務",
    "name_en": "On-site Pre-school Rehabilitation Services (OPRS)",
    "age_min_m": 0,
    "age_max_m": 71,
    "intensity_tc": "由 NGO 跨專業團隊到校提供訓練、諮詢及教師／家長支援",
    "target_tc": "懷疑有特殊需要的兒童（包括正輪候CAS評估者），及經評估為輕度殘疾的兒童",
    "referral_tc": "第一層支援無需經中央轉介系統；經認可專業人士評估者，由指定服務單位社工轉介至中央轉介系統",
    "fee_tc": "免費",
    "wait_note_tc": "已達致「零等候」（官方口径，见 SRC-005 注一）",
    "source_id": "SRC-007",
    "notes_tc": "★ 由2026-10-01起新申請者不再是學習訓練津貼受惠對象——因已达零等候。此条同时是「规则有生效日」的最佳教学案例",
    "target_en": "Children suspected of special needs (including those awaiting CAS assessment), and children assessed with mild disabilities",
    "intensity_en": "On-site training, consultation and teacher/parent support by an NGO multidisciplinary team",
    "referral_en": "First-tier support does not require the Central Referral System; those assessed by recognised professionals are referred by a designated service unit social worker",
    "fee_en": "Free",
    "wait_note_en": "Has reached 'zero waiting' (official — see SRC-005 note 1)",
    "notes_en": "From 1 Oct 2026 new applicants are no longer eligible for the Training Subsidy — because zero waiting has been reached. This is also the best example of a rule having an effective date.",
    "alias_en": "OPRS"
  },
  {
    "code": "S",
    "alias_tc": "S位",
    "name_tc": "特殊幼兒中心",
    "name_en": "Special Child Care Centre (SCCC)",
    "age_min_m": 24,
    "age_max_m": 71,
    "intensity_tc": "全日訓練及照顧（如全日制幼儿园，全天有专业团队）",
    "target_tc": "2歲至6歲以下、中度至嚴重程度殘疾的幼兒，包含「患有自閉症」",
    "referral_tc": "經由社工或康復服務單位的工作人員轉介至社署康復服務中央轉介系統",
    "fee_tc": "免費",
    "wait_note_tc": "2026-08 逐间复算：60 行服务单位、中位數 4 個月、28% 超 12 個月、最長 48 個月；官方口径 2023-24 年度平均輪候 19.2 個月",
    "source_id": "SRC-003",
    "notes_tc": "★ 与 E 位的落差是本项目最核心的原创发现（同一条街上两条队差十倍）",
    "target_en": "Children aged 2 to under 6 with moderate to severe disabilities, including autism",
    "intensity_en": "Full-day training and care (like a full-day kindergarten, with a professional team all day)",
    "referral_en": "Referral by a social worker or rehabilitation service unit staff to the SWD Central Referral System",
    "fee_en": "Free",
    "wait_note_en": "Recalculated per centre (Aug 2026): 60 service units; median 4 months, 28% over 12 months, longest 48 months; official figure: average wait 19.2 months in 2023–24",
    "notes_en": "The gap with E-place is this project's core original finding (two queues on the same street, ten times apart).",
    "alias_en": "SCCC"
  },
  {
    "code": "SR",
    "alias_tc": "S位（住宿）",
    "name_tc": "住宿特殊幼兒中心",
    "name_en": "Residential Special Child Care Centre",
    "age_min_m": 24,
    "age_max_m": 71,
    "intensity_tc": "持續訓練及住宿照顧",
    "target_tc": "中度或嚴重殘疾而無需經常接受醫療／醫院護理，或家庭環境不適宜照顧的兒童",
    "referral_tc": "同 S 位，經中央轉介系統",
    "fee_tc": "待核实",
    "wait_note_tc": "官方口径：全港 6 所住宿特殊幼兒中心（50 所 SCCC 之中）",
    "source_id": "SRC-008",
    "notes_tc": "数量少、轮候通常更久；2026-08 复算中最长 48 个月即出现在此类",
    "target_en": "Children with moderate or severe disabilities who do not need frequent medical/hospital care, or whose home environment is unsuitable for care",
    "intensity_en": "Continuous training and residential care",
    "referral_en": "Same as S-place, via the Central Referral System",
    "fee_en": "To be confirmed",
    "wait_note_en": "Official figure: 6 residential special child care centres territory-wide (out of 50 SCCCs)",
    "notes_en": "Few in number, usually longer waits; the longest 48-month figure in the Aug 2026 recalculation appears in this category.",
    "alias_en": "RSCCC"
  },
  {
    "code": "T",
    "alias_tc": "T位",
    "name_tc": "為輪候資助學前康復服務的兒童提供學習訓練津貼",
    "name_en": "Training Subsidy Programme (TSP)",
    "age_min_m": 0,
    "age_max_m": 71,
    "intensity_tc": "現金津貼（用以购买认可机构的自负盈亏训练服务）",
    "target_tc": "6歲以下、已列入中央轉介系統輪候名單、且並無接受任何資助學前康復服務的兒童",
    "referral_tc": "由社署發信邀請合資格兒童的家長／監護人申請（非家长主动排队获得的项目）",
    "fee_tc": "全免（申請不收費）",
    "wait_note_tc": "不适用（本身不是排队型服务）",
    "source_id": "SRC-005",
    "notes_tc": "★ 普通津貼每月最高 $3,549（轮候E／I／O位，需入息审查）；高額津貼每月最高 $6,904（轮候S位，免入息审查）。等待是有价签的\"——这条是 pitch 素材\"",
    "target_en": "Children under 6 who are on the Central Referral System waiting list and not receiving any subsidised pre-school rehabilitation service",
    "intensity_en": "Cash subsidy (to buy self-financed training services from recognised operators)",
    "referral_en": "SWD sends letters inviting eligible children's parents/guardians to apply (not obtained by parents proactively queueing)",
    "fee_en": "Fully free (no application fee)",
    "wait_note_en": "Not applicable (not a queue-based service)",
    "notes_en": "Normal subsidy: up to $3,549/month (waiting E/I/O, means-tested); higher subsidy: up to $6,904/month (waiting S-place, no means test). 'Waiting has a price tag' — pitch material.",
    "alias_en": "TSP"
  }
]
"""#,
"service_units": #"""
[
  {
    "unit_id": "PD001",
    "name_tc": "香港聾人福利促進會尚德幼兒中心(為聽覺受損兒童而設）",
    "name_en": "HKSD Sheung Tak Child Care Centre (for hearing impaired children)",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "新界將軍澳尚德邨尚美樓地下B座",
    "phone": "2178 0838",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PD002",
    "name_tc": "香港聾人福利促進會白普理幼兒中心(為聽覺受損兒童而設）",
    "name_en": "HKSD Bradbury Child Care Centre (for hearing impaired children)",
    "service_code": "S",
    "operator": null,
    "district": "九龍城",
    "address": "九龍馬頭涌道135號聖三一座堂百週年紀念白普理大樓3樓",
    "phone": "2768 7875",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Kowloon City"
  },
  {
    "unit_id": "PE001",
    "name_tc": "香港明愛樂幼學前教育及訓練中心",
    "name_en": "Caritas Lok Yau Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "中西區",
    "address": "香港堅道2號明愛大廈2樓201室",
    "phone": "2114 0785",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Central and Western"
  },
  {
    "unit_id": "PE002",
    "name_tc": "協康會順利早期教育及訓練中心",
    "name_en": "HHS Shun Lee Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "觀塘",
    "address": "九龍順利邨利富樓2樓109-112室",
    "phone": "2342 5107",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PE003",
    "name_tc": "協康會白田早期教育及訓練中心",
    "name_en": "HHS Pak Tin Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗白田邨瑞田樓B座3樓3號室",
    "phone": "2778 8308",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE004",
    "name_tc": "協康會長青早期教育及訓練中心",
    "name_en": "HHS Cheung Ching Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "葵青",
    "address": "新界長青邨青葵樓地下110-112室",
    "phone": "2497 6262",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PE005",
    "name_tc": "協康會郭葉鍊洪早期教育及訓練中心",
    "name_en": "HHS Kwok Yip Lin Houn Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田沙角邨沙燕樓3樓12-16號",
    "phone": "2648 9968",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PE006",
    "name_tc": "香港基督教服務處彩雲早期教育及訓練中心",
    "name_en": "HKCS Choi Wan Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙彩雲邨",
    "phone": "2796 2722",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PE007C",
    "name_tc": "監護者早期教育中心(以中文為母語的幼兒而設)",
    "name_en": "Watchdog Early Education Centre (for Chinese-speaking children)",
    "service_code": "E",
    "operator": null,
    "district": "中西區",
    "address": "香港中環波老道12地下",
    "phone": "2521 7364",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Central and Western"
  },
  {
    "unit_id": "PE007E",
    "name_tc": "監護者早期教育中心(以英語為母語的幼兒而設)",
    "name_en": "Watchdog Early Education Centre (for English-speaking children)",
    "service_code": "E",
    "operator": null,
    "district": "中西區",
    "address": "香港中環波老道12地下",
    "phone": "2521 7364",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Central and Western"
  },
  {
    "unit_id": "PE008",
    "name_tc": "協康會良景早期教育及訓練中心",
    "name_en": "HHS Leung King Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門良景邨良智樓地下5-8室",
    "phone": "2454 0268",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PE009",
    "name_tc": "香港基督教服務處環翠早期教育及訓練中心",
    "name_en": "HKCS Wan Tsui Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "東區",
    "address": "香港柴灣環翠邨福翠樓地下102-107號",
    "phone": "2898 9505",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PE010",
    "name_tc": "協康會海富中心(早期教育及訓練中心)",
    "name_en": "HHS Hoi Fu Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "油尖旺",
    "address": "九龍旺角海泓道海富苑海欣閣地下及一樓",
    "phone": "2777 5588",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Yau Tsim Mong"
  },
  {
    "unit_id": "PE011",
    "name_tc": "香港明愛樂苗學前教育及訓練中心",
    "name_en": "Caritas Lok Miu Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "東區",
    "address": "香港北角福蔭道7號銅鑼灣社區中心1樓",
    "phone": "2571 8524",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PE012",
    "name_tc": "香港基督教服務處屯門早期教育及訓練中心",
    "name_en": "HKCS Tuen Mun Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門青山公路201號2樓",
    "phone": "2451 6738",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PE013",
    "name_tc": "香港耀能協會懷熙早期教育及訓練中心",
    "name_en": "SAHK Chan Tseng Hsi Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍橫頭磡邨宏興樓地下101-106號",
    "phone": "2336 6756",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PE014",
    "name_tc": "協康會譚杜早期教育及訓練中心",
    "name_en": "HHS Jessie & Thomas Tam Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔運頭塘邨運來樓地下14-15號",
    "phone": "2638 8863",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PE015C",
    "name_tc": "明德兒童啟育中心 (以中文為母語的幼兒而設)",
    "name_en": "The Child Development Centre (for Chinese-speaking children)",
    "service_code": "E",
    "operator": null,
    "district": "東區",
    "address": "香港北角渣華道123號北角福利服務設施大樓3樓",
    "phone": "2849 2018",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PE015E",
    "name_tc": "明德兒童啟育中心 (以英語為母語的幼兒而設)",
    "name_en": "The Child Development Centre (for English-speaking children)",
    "service_code": "E",
    "operator": null,
    "district": "東區",
    "address": "香港北角渣華道123號北角福利服務設施大樓3樓",
    "phone": "2849 2018",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PE016",
    "name_tc": "香港基督教服務處元朗早期教育及訓練中心",
    "name_en": "HKCS Yuen Long Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗水邊圍邨碧水樓207-210號",
    "phone": "2473 2989",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PE017",
    "name_tc": "宣美語言及聽覺訓練中心 (為聽覺受損兒童而設）",
    "name_en": "Suen Mei Speech and Hearing Centre (for hearing impaired children)",
    "service_code": "E",
    "operator": null,
    "district": "葵青",
    "address": "新界荔景山路272號地下",
    "phone": "2743 7377",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PE018",
    "name_tc": "協康會賽馬會早期教育及訓練中心",
    "name_en": "HHS Jockey Club Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "北區",
    "address": "新界上水龍運街2號北區社區中心1 樓",
    "phone": "2670 4899",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "North"
  },
  {
    "unit_id": "PE019",
    "name_tc": "香港基督教服務處葵興早期教育及訓練中心",
    "name_en": "HKCS Kwai Hing Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "葵青",
    "address": "新界葵涌葵興邨興福樓地下4-9號",
    "phone": "2423 1822",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PE020",
    "name_tc": "仁濟醫院圓玄學院早期教育及訓練中心",
    "name_en": "YCH Yuen Yuen Institute Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣仁濟街18號",
    "phone": "2409 1938",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PE021",
    "name_tc": "香港耀能協會德田早期教育及訓練中心",
    "name_en": "SAHK Tak Tin Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "觀塘",
    "address": "九龍藍田德田邨德康樓1樓1號",
    "phone": "2952 6669",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PE022",
    "name_tc": "基督教靈實協會梁烱初寶林早期教育及訓練中心",
    "name_en": "HOHCS K.C. Liang Po Lam Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "西貢",
    "address": "九龍將軍澳寶林邨寶儉樓地下",
    "phone": "2246 3400",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PE023",
    "name_tc": "協康會富昌中心(早期教育及訓練中心)",
    "name_en": "HHS Fu Cheong Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍長沙灣富昌邨富萊樓B及C座地下",
    "phone": "2353 4001",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE024",
    "name_tc": "協康會東涌中心 (早期教育及訓練中心)",
    "name_en": "HHS Tung Chung Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "離島",
    "address": "大嶼山東涌逸東邨逸東商場二期地下",
    "phone": "2109 2262",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Islands"
  },
  {
    "unit_id": "PE025",
    "name_tc": "協康會大窩口中心 (早期教育及訓練中心)",
    "name_en": "HHS Tai Wo Hau Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣大窩口邨富賢樓地下",
    "phone": "2420 2222",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PE026",
    "name_tc": "香港耀能協會鴨脷洲幼兒中心 (早期教育及訓練中心)",
    "name_en": "SAHK Apleichau Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "南區",
    "address": "香港鴨脷洲鴨脷洲邨利怡樓地下1-16號",
    "phone": "2554 5019",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PE027",
    "name_tc": "香港耀能協會石硤尾幼兒中心 (早期教育及訓練中心)",
    "name_en": "SAHK Shek Kip Mei Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗石硤尾邨第23座116-130號地下",
    "phone": "2778 1773",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE028",
    "name_tc": "香港耀能協會隆亨幼兒中心 (早期教育及訓練中心)",
    "name_en": "SAHK Lung Hang Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田隆亨邨善心樓118-125,",
    "phone": "2604 2798",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PE029",
    "name_tc": "匡智會匡智松嶺學前兒童中心 (早期教育及訓練中心)",
    "name_en": "HCA Hong Chi Pinehill Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔南坑頌雅路松嶺村",
    "phone": "2689 0588",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PE030",
    "name_tc": "香港聾人福利促進會何文田中心 (早期教育及訓練中心) (為聽覺受損兒童而設）(在四個位於北角、將軍澳、何文田及屯門的服務單位提供機構為本的服務)",
    "name_en": "The Hong Kong Society for the Deaf Ho Man Tin Centre (EETC) (for hearing impaired children) (providing agency-based service at 4 service units in North Point, TKO, Ho Man Tin and Tuen Mun)",
    "service_code": "E",
    "operator": null,
    "district": "九龍城",
    "address": "中心地址：九龍何文田愛民村嘉民樓",
    "phone": "2715 0755",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kowloon City"
  },
  {
    "unit_id": "PE031",
    "name_tc": "香港基督教服務處摩理臣山兒童發展中心 (早期教育及訓練中心)",
    "name_en": "HKCS Morrison Hill Child Development Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "灣仔",
    "address": "香港灣仔皇后大道東282號",
    "phone": "3553 3638",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wan Chai"
  },
  {
    "unit_id": "PE032",
    "name_tc": "香港耀能協會象山幼兒中心 (早期教育及訓練中心)",
    "name_en": "SAHK Cheung Shan Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣象山邨秀山樓地下21-25號",
    "phone": "2492 1109",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PE033",
    "name_tc": "保良局倪文玲(元朗)兒童發展中心 (早期教育及訓練中心)",
    "name_en": "Po Leung Kuk Malina Ngai (Yuen Long) Child Development Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗水邊圍邨盈水樓215-220室",
    "phone": "2479 1901",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PE034",
    "name_tc": "東華三院馬孔令琦兒童發展中心",
    "name_en": "TWGHs Ma Kung Lin Chi Child Development Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "油尖旺",
    "address": "九龍旺角嘉禮大廈2樓A-D室",
    "phone": "2396 2050",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Yau Tsim Mong"
  },
  {
    "unit_id": "PE035",
    "name_tc": "協康會裕明中心 (早期教育及訓練中心)",
    "name_en": "HHS Yu Ming Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "西貢",
    "address": "九龍將軍澳裕明苑裕昌閣地下",
    "phone": "3590 5116",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PE036",
    "name_tc": "鄰舍輔導會啟康幼兒中心（早期教育及訓練中心）",
    "name_en": "NAAC Child Enlightenment Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田博康邨博泰樓地下B翼",
    "phone": "2635 9668",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PE037",
    "name_tc": "保良局曹金霖幼兒學習中心(早期教育及訓練中心)",
    "name_en": "PLK Chao King Lin Early Learning Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙竹園南邨",
    "phone": "2322 3030",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PE038",
    "name_tc": "鄰舍輔導會陳蔭川欣康幼兒中心 (早期教育及訓練中心)",
    "name_en": "NAAC Chan Yin Chuen Child Enrichment Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙鳳德邨硃鳳樓地下B翼",
    "phone": "2567 2880",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PE039",
    "name_tc": "香港耀能協會白田幼兒中心 (早期教育及訓練中心)",
    "name_en": "SAHK Pak Tin Pre-school Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍石硤尾白田邨",
    "phone": "2779 2168",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE040",
    "name_tc": "東華三院廖烈武伉儷兒童發展中心 (早期教育及訓練中心)",
    "name_en": "TWGHs Mr and Mrs Liu Lit Mo Child Development Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗天水圍天晴邨",
    "phone": "2461 2622",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PE041",
    "name_tc": "協康會鯉魚門中心 (早期教育訓練中心)",
    "name_en": "Heep Hong Society Lei Yue Mun Centre (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "觀塘",
    "address": "九龍觀塘鯉魚門邨鯉旺樓平台一號單位",
    "phone": "2682 2203",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PE042",
    "name_tc": "香港耀能協會葵盛早期教育及訓練中心",
    "name_en": "SAHK Kwai Shing Early Education & Training Cenre",
    "service_code": "E",
    "operator": null,
    "district": "葵青",
    "address": "新界葵涌葵盛西邨第8座",
    "phone": "2493 0363",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PE043",
    "name_tc": "保良局梁安琪兒童發展中心",
    "name_en": "PLK Angela Leong On Kei Child Development Centre",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田美田邨美全樓地下C翼",
    "phone": "2663 1254",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PE044",
    "name_tc": "協康會上海總會油麗中心",
    "name_en": "HHS Shanghai Fraternity Association Yau Lai Centre",
    "service_code": "E",
    "operator": null,
    "district": "觀塘",
    "address": "九龍觀塘油塘道9號油麗邨停車場大廈5樓",
    "phone": "2415 2077",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PE045",
    "name_tc": "協康會環翠中心 (早期教育及訓練中心)",
    "name_en": "HHS Wan Tsui Centre (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "東區",
    "address": "香港柴灣環翠邨澤翠樓地下102-113號",
    "phone": "3568 4145",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PE046",
    "name_tc": "鄰舍輔導會景康幼兒中心 (早期教育及訓練中心)",
    "name_en": "NAAC Child Advancement Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門山景邨景樂樓地下A翼",
    "phone": "2426 0122",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PE047",
    "name_tc": "匡智會匡智廣福學前兒童中心 (早期教育及訓練中心)",
    "name_en": "HCA Hong Chi Kwong Fuk Pre-School Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔廣福邨廣祐樓地下118-125室",
    "phone": "3708 8664",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PE048",
    "name_tc": "協康會大口環早期教育及訓練中心",
    "name_en": "HHS Sandy Bay Early Education & Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林大口環道19號5樓及6樓",
    "phone": "3158 8368",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PE049",
    "name_tc": "保良局慧妍雅集兒童發展中心",
    "name_en": "PLK Wai Yin Association Child Development Centre",
    "service_code": "E",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔寶鄉邨地下G07",
    "phone": "2769 0208",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PE050",
    "name_tc": "香港耀能協會安泰幼兒中心(早期教育及訓練中心)",
    "name_en": "SAHK On Tai Pre-school Centre (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "觀塘",
    "address": "九龍觀塘安秀道23號",
    "phone": "2362 2688",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PE051",
    "name_tc": "保良局倪文玲(深水埗)兒童發展中心 (早期教育及訓練中心)",
    "name_en": "Po Leung Kuk Malina Ngai (Sham Shui Po) Child Development Centre (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗蘇屋邨社區綜合服務大樓二樓",
    "phone": "2955 1622",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE052",
    "name_tc": "香港小童群益會「樂航」兒童早期發展中心(東涌)",
    "name_en": "BGCA \"SAIL\" Early Child Development Centre (Tung Chung)",
    "service_code": "E",
    "operator": null,
    "district": "離島",
    "address": "香港大嶼山東涌滿東村滿樂坊105及106號",
    "phone": "2580 0013",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Islands"
  },
  {
    "unit_id": "PE053",
    "name_tc": "路德會凝趣兒童發展中心",
    "name_en": "Amazing Lutheran Child Development Centre",
    "service_code": "E",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙富山邨富暉樓1樓102室",
    "phone": "2363 6636",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PE054",
    "name_tc": "協康會雍明中心 (早期教育及訓練中心)",
    "name_en": "HHS Yung Ming Centre (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "西貢",
    "address": "將軍澳至善街5號",
    "phone": "2915 8433",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PE055",
    "name_tc": "救世軍駿洋幼兒中心（早期教育及訓練中心）",
    "name_en": "The Salvation Army Chun Yeung Child Care Centre (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界火炭駿洋邨駿逸樓地下 G02 室",
    "phone": "2520 0181",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PE056",
    "name_tc": "仁濟醫院嚴徐玉珊早期教育及訓練中心",
    "name_en": "Yan Chai Hospital Yim Tsui Yuk Shan Early Education and Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔富蝶邨綜合社會服務大樓2樓",
    "phone": "3695 0292",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PE057",
    "name_tc": "保良局倪文玲(海達)兒童發展中心 (早期教育及訓練中心）",
    "name_en": "PLK Malina Ngai (Hoi Tat) Child Development Centre  (EETC Section)",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗深旺道38號",
    "phone": "2590 0203",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE058",
    "name_tc": "路德會凝悅兒童發展中心",
    "name_en": "Bravo Lutheran Child Development Centre",
    "service_code": "E",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗海壇街218號",
    "phone": "2126 7600",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PE059",
    "name_tc": "協康會上海總會菁田中心（早期教育及訓練中心）",
    "name_en": "HHS Shanghai Fraternity Association Ching Tin Center (EETC) ",
    "service_code": "E",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門欣寶路10號菁田邨菁信樓1樓部份樓層",
    "phone": "2818 1300",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PE060",
    "name_tc": "香港耀能協會康城早期教育及訓練中心",
    "name_en": "SAHK LOHAS Park Early Education and Training Centre",
    "service_code": "E",
    "operator": null,
    "district": "西貢",
    "address": "將軍澳康城路1號日出康城第XII期政府樓宇「早期教育及訓練中心」",
    "phone": "3153 2557",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PE061",
    "name_tc": "仁濟醫院童夢兒童成長發展中心",
    "name_en": "YCH Dreamland Child Development Centre ",
    "service_code": "E",
    "operator": null,
    "district": "葵青",
    "address": "新界青衣青衣路18號青富苑青隆閣LG1樓",
    "phone": "2808 0001",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PE062",
    "name_tc": "香港小童群益會「樂航」兒童早期發展中心 (馬鞍山) (早期教育及訓練中心)",
    "name_en": "BGCA \"SAIL\" Early Child Development Centre (Ma On Shan) (EETC section)",
    "service_code": "E",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田馬鞍山恆智街3號欣安商場2期2樓",
    "phone": "2670 6488",
    "capacity": null,
    "source_id": "SRC-012",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PR001",
    "name_tc": "匡智會匡智松嶺學前兒童中心 (住宿）",
    "name_en": "HCA Hong Chi Pinehill Pre-school Centre (Residential)",
    "service_code": "SR",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔南坑頌雅路松嶺村匡智賽馬會松嶺學前及兒童服務大樓",
    "phone": "2689 0588",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PR007",
    "name_tc": "香港耀能協會鴨脷洲幼兒中心 (設有住宿部份）",
    "name_en": "SAHK Apleichau Pre-school Centre (Residential)",
    "service_code": "SR",
    "operator": null,
    "district": "南區",
    "address": "香港鴨脷洲鴨脷洲邨利怡樓地下1-16號",
    "phone": "2554 5019",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PR018",
    "name_tc": "香港耀能協會賽馬會方心淑引導式教育中心 (住宿部份) (請自行向中心申請)",
    "name_en": "SAHK Jockey Club Marion Fang Conductive Learning Centre (Residential) (Direct application to the centre)",
    "service_code": "SR",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍橫頭磡邨宏亮樓6-17號地下",
    "phone": "2336 2011",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PR019",
    "name_tc": "母親的抉擇特殊幼兒住宿中心 (住宿）",
    "name_en": "Mother's Choice Wee Care Home (Residential)",
    "service_code": "SR",
    "operator": null,
    "district": "中西區",
    "address": "香港中環寶雲道5號",
    "phone": "2313 5650",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Central and Western"
  },
  {
    "unit_id": "PR024",
    "name_tc": "仁濟醫院羅氏基金護幼中心暨宿舍 (住宿)",
    "name_en": "YCH Law's Foundation Child Care Centre cum Hostel (Residential)",
    "service_code": "SR",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣仁濟街18號仁濟醫院綜合服務大樓1樓",
    "phone": "2615 1714",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PR025",
    "name_tc": "心光幼兒中心 (住宿) (為患有中度至嚴重視覺受損或失明的兒童而設)",
    "name_en": "Ebenezer Child Care Centre (Residential)(for children with moderate to severe visual impairment or blindness)",
    "service_code": "SR",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林道131號",
    "phone": "3159 5403",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PR026",
    "name_tc": "心光幼兒中心 (住宿) (為中度至嚴重殘疾而患有懷疑或輕度視覺受損的兒童而設)",
    "name_en": "Ebenezer Child Care Centre (Residential section) (for children of moderate to severe disabilities with suspected or mild visual impairment)",
    "service_code": "SR",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林道131號",
    "phone": "3159 5403",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PS001",
    "name_tc": "香港明愛樂興幼兒中心",
    "name_en": "Caritas Lok Hing Child Care Centre",
    "service_code": "S",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門大興邨興盛樓22號地下",
    "phone": "2465 6388",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PS002",
    "name_tc": "協康會慶華中心 (特殊幼兒中心)",
    "name_en": "HHS Catherine Lo Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林大口環道19號綜合服務大樓2-4樓",
    "phone": "3158 8315",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PS003",
    "name_tc": "協康會王石崇傑紀念中心",
    "name_en": "HHS Mary Wong Centre",
    "service_code": "S",
    "operator": null,
    "district": "觀塘",
    "address": "九龍牛頭角彩霞邨彩星樓5號地下",
    "phone": "2755 8118",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PS004",
    "name_tc": "協康會大窩口中心 (特殊幼兒中心)",
    "name_en": "HHS Tai Wo Hau Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣大窩口邨富賢樓地下",
    "phone": "2420 2222",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PS005",
    "name_tc": "協康會秦石中心",
    "name_en": "HHS Chun Shek Centre",
    "service_code": "S",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田秦石邨石玉樓11-18A地下",
    "phone": "2697 3620",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PS007",
    "name_tc": "香港耀能協會鴨脷洲幼兒中心 (日間特殊幼兒中心)",
    "name_en": "SAHK Apleichau Pre-school Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "南區",
    "address": "香港鴨脷洲鴨脷洲邨利怡樓地下1-16號",
    "phone": "2554 5019",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PS008",
    "name_tc": "香港耀能協會橫頭磡幼兒中心",
    "name_en": "SAHK Wang Tau Hom Pre-school Centre",
    "service_code": "S",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍橫頭磡邨宏富樓8-14號地下",
    "phone": "2338 3555",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PS009",
    "name_tc": "香港耀能協會石圍角幼兒中心",
    "name_en": "SAHK Shek Wai Kok Pre-school Centre",
    "service_code": "S",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣石圍角邨石荷樓地下101-119號",
    "phone": "2427 0741",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PS010",
    "name_tc": "香港耀能協會石硤尾幼兒中心 (特殊幼兒中心)",
    "name_en": "SAHK Shek Kip Mei Pre-school Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗石硤尾邨第23座116-130號地下",
    "phone": "2778 1773",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS011",
    "name_tc": "香港耀能協會隆亨幼兒中心 (特殊幼兒中心)",
    "name_en": "SAHK Lung Hang Pre-school Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田隆亨邨善心樓118-125, 127-130號地下",
    "phone": "2604 2798",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PS013",
    "name_tc": "協康會灣仔中心",
    "name_en": "HHS Wan Chai Centre",
    "service_code": "S",
    "operator": null,
    "district": "灣仔",
    "address": "香港灣仔灣仔道185號康樂商業大廈1樓",
    "phone": "2891 8011",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wan Chai"
  },
  {
    "unit_id": "PS014",
    "name_tc": "協康會天平中心",
    "name_en": "HHS Tin Ping Centre",
    "service_code": "S",
    "operator": null,
    "district": "北區",
    "address": "新界上水天平邨天美樓地下11-15號",
    "phone": "2673 0189",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "North"
  },
  {
    "unit_id": "PS015",
    "name_tc": "協康會環翠中心 (特殊幼兒中心)",
    "name_en": "HHS Wan Tsui Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "東區",
    "address": "香港柴灣環翠邨澤翠樓地下130-141號",
    "phone": "2889 3919",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PS016",
    "name_tc": "中華基督教會香港區會屯門特殊幼兒中心",
    "name_en": "HKCCCC Tuen Mun Special Child Care Centre",
    "service_code": "S",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門井財街29號3樓",
    "phone": "2450 8745",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PS017",
    "name_tc": "協康會雷瑞德夫人中心",
    "name_en": "HHS Alice Louey Centre",
    "service_code": "S",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔富善邨善翠樓地下1號",
    "phone": "2662 9733",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PS018",
    "name_tc": "香港耀能協會賽馬會方心淑引導式教育中心 (日間特殊幼兒中心) (請自行向中心申請)",
    "name_en": "SAHK Jockey Club Marion Fang Conductive Learning Centre (SCCC Section) (Direct application to the centre)",
    "service_code": "S",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍橫頭磡邨宏亮樓6-17號地下",
    "phone": "2336 2011",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PS020",
    "name_tc": "香港基督教服務處祥華特殊幼兒中心",
    "name_en": "HKCS Cheung Wah Special Child Care Centre",
    "service_code": "S",
    "operator": null,
    "district": "北區",
    "address": "新界粉嶺祥華邨祥智樓地下A翼",
    "phone": "2676 2020",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "North"
  },
  {
    "unit_id": "PS021",
    "name_tc": "協康會水邊圍中心",
    "name_en": "HHS Shui Pin Wai Centre",
    "service_code": "S",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗水邊圍邨疊水樓地下2號",
    "phone": "2478 8739",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PS022",
    "name_tc": "協康會長沙灣中心",
    "name_en": "HHS Cheung Sha Wan Centre",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍長沙灣道303號長沙灣政府合署1樓",
    "phone": "2391 9696",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS023",
    "name_tc": "協康會陳宗漢紀念中心",
    "name_en": "HHS Chan Chung Hon Centre",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "九龍將軍澳尚德邨尚義樓地下B及C翼",
    "phone": "2178 2885",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PS024",
    "name_tc": "協康會富昌中心 (特殊幼兒中心)",
    "name_en": "HHS Fu Cheong Centre(SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍長沙灣富昌邨富萊樓B & C座地下",
    "phone": "2353 4001",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS025",
    "name_tc": "協康會東涌中心 (特殊幼兒中心)",
    "name_en": "HHS Tung Chung Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "離島",
    "address": "東涌逸東邨逸東商場二期地下",
    "phone": "2109 2262",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Islands"
  },
  {
    "unit_id": "PS026",
    "name_tc": "心光幼兒中心 (日間特殊幼兒中心) (為視覺受損兒童而設)",
    "name_en": "Ebenezer Child Care Centre (SCCC Section) (for children with moderate to severe visual impairment or blindness)",
    "service_code": "S",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林道131號",
    "phone": "3159 5403",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PS027",
    "name_tc": "香港耀能協會象山幼兒中心 (特殊幼兒中心)",
    "name_en": "SAHK Cheung Shan Pre-school Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "荃灣",
    "address": "新界荃灣象山邨秀山樓21-25號地下",
    "phone": "2492 1109",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tsuen Wan"
  },
  {
    "unit_id": "PS028",
    "name_tc": "香港基督教服務處摩理臣山兒童發展中心 (特殊幼兒中心)",
    "name_en": "HKCS Morrison Hill Child Development Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "灣仔",
    "address": "香港灣仔皇后大道東282號鄧肇堅醫院社區日間醫療中心一樓",
    "phone": "3553 3638",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wan Chai"
  },
  {
    "unit_id": "PS029",
    "name_tc": "保良局倪文玲(元朗)兒童發展中心 (特殊幼兒中心)",
    "name_en": "Po Leung Kuk Malina Ngai (Yuen Long) Child Development Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗水邊圍邨盈水樓215-220室",
    "phone": "2479 1901",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PS030",
    "name_tc": "協康會裕明中心 (特殊幼兒中心)",
    "name_en": "HHS Yu Ming Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "九龍將軍澳裕明苑裕昌閣地下",
    "phone": "3590 5116",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PS031",
    "name_tc": "鄰舍輔導會啟康幼兒中心(特殊幼兒中心)",
    "name_en": "NAAC Child Enlightenment Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "沙田",
    "address": "沙田博康邨博泰樓地下B翼",
    "phone": "2635 9668",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PS032",
    "name_tc": "保良局曹金霖幼兒學習中心 (特殊幼兒中心)",
    "name_en": "PLK Chao King Lin Early Learning Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙竹園南邨華園樓地下121-140室",
    "phone": "2322 3030",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PS033",
    "name_tc": "鄰舍輔導會陳蔭川欣康幼兒中心(特殊幼兒中心)",
    "name_en": "NAAC Chan Yin Chuen Child Enrichment Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙鳳德邨硃鳳樓地下B翼",
    "phone": "2567 2880",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PS034",
    "name_tc": "香港耀能協會白田幼兒中心 (特殊幼兒中心)",
    "name_en": "SAHK Pak Tin Pre-School Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍石硤尾白田邨白田社區綜合大樓2樓及3樓",
    "phone": "2779 2168",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS035",
    "name_tc": "東華三院廖烈武伉儷兒童發展中心 (特殊幼兒中心)",
    "name_en": "TWGHs Mr and Mrs Liu Lit Mo Child Development Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "元朗",
    "address": "新界元朗天水圍天晴邨社區綜合服務大樓3樓302室",
    "phone": "2461 2622",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Yuen Long"
  },
  {
    "unit_id": "PS036",
    "name_tc": "鄰舍輔導會景康幼兒中心 (特殊幼兒中心)",
    "name_en": "NAAC Child Advancement Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門山景邨景樂樓A翼地下",
    "phone": "2426 0122",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PS037",
    "name_tc": "匡智會匡智廣福學前兒童中心 (特殊幼兒中心)",
    "name_en": "HCA Hong Chi Kwong Fuk Pre-School Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔廣福邨廣祐樓地下118-125室",
    "phone": "3708 8664",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PS038",
    "name_tc": "協康會鯉魚門中心(特殊幼兒中心)",
    "name_en": "Heep Hong Society Lei Yue Mun Centre (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "觀塘",
    "address": "九龍觀塘鯉魚門邨鯉旺樓平台一號單位",
    "phone": "2682 2203",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PS039",
    "name_tc": "香港耀能協會安泰幼兒中心 (特殊幼兒中心)",
    "name_en": "SAHK On Tai Pre-school Centre (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "觀塘",
    "address": "九龍觀塘安秀道23號安泰邨服務設施大樓1樓",
    "phone": "2362 2688",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Kwun Tong"
  },
  {
    "unit_id": "PS040",
    "name_tc": "匡智松嶺學前兒童中心 (特殊幼兒中心)",
    "name_en": "Hong Chi Pinehill Pre-school Centre (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "大埔",
    "address": "新界大埔南坑頌雅路松嶺村匡智賽馬會松嶺學前及兒童服務大樓",
    "phone": "2689 0588",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tai Po"
  },
  {
    "unit_id": "PS041",
    "name_tc": "香港小童群益會「樂航」兒童早期發展中心(東涌) (特殊幼兒中心)",
    "name_en": "BGCA “SAIL” Early Child Development Centre (Tung Chung) (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "離島",
    "address": "香港大嶼山滿東村滿樂坊105及106號",
    "phone": "2580 0013",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Islands"
  },
  {
    "unit_id": "PS042",
    "name_tc": "保良局倪文玲(深水埗)兒童發展中心 (特殊幼兒中心)",
    "name_en": "Po Leung Kuk Malina Ngai (Sham Shui Po) Child Development Centre (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗蘇屋邨社區綜合服務大樓二樓",
    "phone": "2955 1622",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS043",
    "name_tc": "路德會凝趣兒童發展中心 (特殊幼兒中心)",
    "name_en": "Amazing Lutheran Child Development Centre (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "黃大仙",
    "address": "九龍黃大仙富山邨富暉樓地下G01室(特殊幼兒中心)",
    "phone": "2363 6636",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Wong Tai Sin"
  },
  {
    "unit_id": "PS044",
    "name_tc": "協康會雍明中心（特殊幼兒中心)",
    "name_en": "HHS Yung Ming Centre (SCCC section)",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "將軍澳至善街5號將軍澳南服務設施大樓3樓",
    "phone": "2915 8433",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PS045",
    "name_tc": "保良局倪文玲(海達)兒童發展中心（特殊幼兒中心）",
    "name_en": "Po Leung Kuk Malina Ngai (Hoi Tat) Child Development Centre  (SCCC Section) ",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗深旺道 38 號海達邨服務設施大樓地下",
    "phone": "2590 0203",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS046",
    "name_tc": "救世軍駿洋幼兒中心（特殊幼兒中心）",
    "name_en": "The Salvation Army Chun Yeung Child Care Centre  (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "沙田",
    "address": "新界火炭駿洋邨駿逸樓地下G01室",
    "phone": "2520 0181",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PS047",
    "name_tc": "路德會凝悅兒童發展中心(特殊幼兒中心)",
    "name_en": "Bravo Lutheran Child Development Centre (SCCC Section) ",
    "service_code": "S",
    "operator": null,
    "district": "深水埗",
    "address": "九龍深水埗海壇街218號愛海頌第一座三樓",
    "phone": "2126 7600",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sham Shui Po"
  },
  {
    "unit_id": "PS048",
    "name_tc": "東華三院北角兒童發展中心(以英語為母語的幼兒而設)",
    "name_en": "TWGHs North Point Child Development Centre (for English-speaking children) ",
    "service_code": "S",
    "operator": null,
    "district": "東區",
    "address": "香港北角渣華道123號北角福利服務設施大樓2樓",
    "phone": "3797 7355",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Eastern"
  },
  {
    "unit_id": "PS049",
    "name_tc": "心光幼兒中心 (日間特殊幼兒中心) (為中度至嚴重殘疾而患有懷疑或輕度視覺受損的兒童而設)",
    "name_en": "Ebenezer Child Care Centre (SCCC Section) (for children of moderate to severe disabilities with suspected or mild visual impairment)",
    "service_code": "S",
    "operator": null,
    "district": "南區",
    "address": "香港薄扶林道131號",
    "phone": "3159 5403",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Southern"
  },
  {
    "unit_id": "PS050",
    "name_tc": "協康會上海總會菁田中心（特殊幼兒中心）",
    "name_en": "HHS Shanghai Fraternity Association Ching Tin Center (SCCC Section)",
    "service_code": "S",
    "operator": null,
    "district": "屯門",
    "address": "新界屯門欣寶路10號菁田邨菁信樓1樓部份樓層",
    "phone": "2818 2009",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Tuen Mun"
  },
  {
    "unit_id": "PS051",
    "name_tc": "香港小童群益會「樂航」兒童早期發展中心 (馬鞍山) (特殊幼兒中心)",
    "name_en": "BGCA \"SAIL\" Early Child Development Centre (Ma On Shan) (SCCC section) ",
    "service_code": "S",
    "operator": null,
    "district": "沙田",
    "address": "新界沙田馬鞍山恆智街3號欣安商場2期1樓",
    "phone": "2670 6488",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sha Tin"
  },
  {
    "unit_id": "PS052",
    "name_tc": "香港聾人福利促進會尚德幼兒中心(為聽覺受損兒童而設）",
    "name_en": "HKSD Sheung Tak Child Care Centre (for children of moderate to severe disabilities with suspected, mild or moderate hearing impairment) ",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "新界將軍澳尚德邨尚美樓地下B座",
    "phone": "2178 0838",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  },
  {
    "unit_id": "PS053",
    "name_tc": "仁濟醫院孫蔡吐媚兒童成長發展中心",
    "name_en": "YCH Suen Choi To May Child Development Centre \n",
    "service_code": "S",
    "operator": null,
    "district": "葵青",
    "address": "新界青衣青衣路18號青富苑青隆閣LG1樓",
    "phone": "2808 1718",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Kwai Tsing"
  },
  {
    "unit_id": "PS054",
    "name_tc": "香港聾人福利促進會尚德幼兒中心",
    "name_en": "HKSD Sheung Tak Child Care Centre",
    "service_code": "S",
    "operator": null,
    "district": "西貢",
    "address": "新界將軍澳尚德邨尚美樓地下B座",
    "phone": "2178 0838",
    "capacity": null,
    "source_id": "SRC-013",
    "status": "active",
    "district_en": "Sai Kung"
  }
]
"""#,
"waiting_snapshot": #"""
[
  {
    "snapshot_id": "2026-08-31-PR026",
    "as_of": "2026-08-31",
    "unit_id": "PR026",
    "unit_name_raw": "心光幼兒中心 (住宿) (為中度至嚴重殘疾而患有懷疑或輕度視覺受損的兒童而設)",
    "service_code": "SR",
    "last_match_apply": "08/2022",
    "derived_wait_m": 48,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR025",
    "as_of": "2026-08-31",
    "unit_id": "PR025",
    "unit_name_raw": "心光幼兒中心 (住宿) (為患有中度至嚴重視覺受損或失明的兒童而設)",
    "service_code": "SR",
    "last_match_apply": "05/2023",
    "derived_wait_m": 39,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS052",
    "as_of": "2026-08-31",
    "unit_id": "PS052",
    "unit_name_raw": "香港聾人福利促進會尚德幼兒中心(為聽覺受損兒童而設）",
    "service_code": "S",
    "last_match_apply": "05/2024",
    "derived_wait_m": 27,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS048",
    "as_of": "2026-08-31",
    "unit_id": "PS048",
    "unit_name_raw": "東華三院北角兒童發展中心(以英語為母語的幼兒而設)",
    "service_code": "S",
    "last_match_apply": "07/2024",
    "derived_wait_m": 25,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS035",
    "as_of": "2026-08-31",
    "unit_id": "PS035",
    "unit_name_raw": "東華三院廖烈武伉儷兒童發展中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "09/2024",
    "derived_wait_m": 23,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS021",
    "as_of": "2026-08-31",
    "unit_id": "PS021",
    "unit_name_raw": "協康會水邊圍中心",
    "service_code": "S",
    "last_match_apply": "10/2024",
    "derived_wait_m": 22,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS029",
    "as_of": "2026-08-31",
    "unit_id": "PS029",
    "unit_name_raw": "保良局倪文玲(元朗)兒童發展中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "11/2024",
    "derived_wait_m": 21,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS049",
    "as_of": "2026-08-31",
    "unit_id": "PS049",
    "unit_name_raw": "心光幼兒中心 (日間特殊幼兒中心) (為中度至嚴重殘疾而患有懷疑或輕度視覺受損的兒童而設)",
    "service_code": "S",
    "last_match_apply": "03/2025",
    "derived_wait_m": 17,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR018",
    "as_of": "2026-08-31",
    "unit_id": "PR018",
    "unit_name_raw": "香港耀能協會賽馬會方心淑引導式教育中心 (住宿部份) (請自行向中心申請)",
    "service_code": "SR",
    "last_match_apply": "03/2025",
    "derived_wait_m": 17,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS018",
    "as_of": "2026-08-31",
    "unit_id": "PS018",
    "unit_name_raw": "香港耀能協會賽馬會方心淑引導式教育中心 (日間特殊幼兒中心) (請自行向中心申請)",
    "service_code": "S",
    "last_match_apply": "03/2025",
    "derived_wait_m": 17,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS020",
    "as_of": "2026-08-31",
    "unit_id": "PS020",
    "unit_name_raw": "香港基督教服務處祥華特殊幼兒中心",
    "service_code": "S",
    "last_match_apply": "04/2025",
    "derived_wait_m": 16,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS014",
    "as_of": "2026-08-31",
    "unit_id": "PS014",
    "unit_name_raw": "協康會天平中心",
    "service_code": "S",
    "last_match_apply": "05/2025",
    "derived_wait_m": 15,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS001",
    "as_of": "2026-08-31",
    "unit_id": "PS001",
    "unit_name_raw": "香港明愛樂興幼兒中心",
    "service_code": "S",
    "last_match_apply": "05/2025",
    "derived_wait_m": 15,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS036",
    "as_of": "2026-08-31",
    "unit_id": "PS036",
    "unit_name_raw": "鄰舍輔導會景康幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "05/2025",
    "derived_wait_m": 15,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS050",
    "as_of": "2026-08-31",
    "unit_id": "PS050",
    "unit_name_raw": "協康會上海總會菁田中心（特殊幼兒中心）",
    "service_code": "S",
    "last_match_apply": "05/2025",
    "derived_wait_m": 15,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR007",
    "as_of": "2026-08-31",
    "unit_id": "PR007",
    "unit_name_raw": "香港耀能協會鴨脷洲幼兒中心 (設有住宿部份）",
    "service_code": "SR",
    "last_match_apply": "06/2025",
    "derived_wait_m": 14,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS016",
    "as_of": "2026-08-31",
    "unit_id": "PS016",
    "unit_name_raw": "中華基督教會香港區會屯門特殊幼兒中心",
    "service_code": "S",
    "last_match_apply": "06/2025",
    "derived_wait_m": 14,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS004",
    "as_of": "2026-08-31",
    "unit_id": "PS004",
    "unit_name_raw": "協康會大窩口中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "08/2025",
    "derived_wait_m": 12,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PD001",
    "as_of": "2026-08-31",
    "unit_id": "PD001",
    "unit_name_raw": "香港聾人福利促進會尚德幼兒中心(為聽覺受損兒童而設）",
    "service_code": "S",
    "last_match_apply": "10/2025",
    "derived_wait_m": 10,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS042",
    "as_of": "2026-08-31",
    "unit_id": "PS042",
    "unit_name_raw": "保良局倪文玲(深水埗)兒童發展中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "10/2025",
    "derived_wait_m": 10,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS053",
    "as_of": "2026-08-31",
    "unit_id": "PS053",
    "unit_name_raw": "仁濟醫院孫蔡吐媚兒童成長發展中心",
    "service_code": "S",
    "last_match_apply": "10/2025",
    "derived_wait_m": 10,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS039",
    "as_of": "2026-08-31",
    "unit_id": "PS039",
    "unit_name_raw": "香港耀能協會安泰幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "11/2025",
    "derived_wait_m": 9,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PD002",
    "as_of": "2026-08-31",
    "unit_id": "PD002",
    "unit_name_raw": "香港聾人福利促進會白普理幼兒中心(為聽覺受損兒童而設）",
    "service_code": "S",
    "last_match_apply": "11/2025",
    "derived_wait_m": 9,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS017",
    "as_of": "2026-08-31",
    "unit_id": "PS017",
    "unit_name_raw": "協康會雷瑞德夫人中心",
    "service_code": "S",
    "last_match_apply": "11/2025",
    "derived_wait_m": 9,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS038",
    "as_of": "2026-08-31",
    "unit_id": "PS038",
    "unit_name_raw": "協康會鯉魚門中心(特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "12/2025",
    "derived_wait_m": 8,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS025",
    "as_of": "2026-08-31",
    "unit_id": "PS025",
    "unit_name_raw": "協康會東涌中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "01/2026",
    "derived_wait_m": 7,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS003",
    "as_of": "2026-08-31",
    "unit_id": "PS003",
    "unit_name_raw": "協康會王石崇傑紀念中心",
    "service_code": "S",
    "last_match_apply": "01/2026",
    "derived_wait_m": 7,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS024",
    "as_of": "2026-08-31",
    "unit_id": "PS024",
    "unit_name_raw": "協康會富昌中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "01/2026",
    "derived_wait_m": 7,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE007E",
    "as_of": "2026-08-31",
    "unit_id": "PE007E",
    "unit_name_raw": "監護者早期教育中心(以英語為母語的幼兒而設)",
    "service_code": "E",
    "last_match_apply": "02/2026",
    "derived_wait_m": 6,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE040",
    "as_of": "2026-08-31",
    "unit_id": "PE040",
    "unit_name_raw": "東華三院廖烈武伉儷兒童發展中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "02/2026",
    "derived_wait_m": 6,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE016",
    "as_of": "2026-08-31",
    "unit_id": "PE016",
    "unit_name_raw": "香港基督教服務處元朗早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "02/2026",
    "derived_wait_m": 6,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE033",
    "as_of": "2026-08-31",
    "unit_id": "PE033",
    "unit_name_raw": "保良局倪文玲(元朗)兒童發展中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "02/2026",
    "derived_wait_m": 6,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS009",
    "as_of": "2026-08-31",
    "unit_id": "PS009",
    "unit_name_raw": "香港耀能協會石圍角幼兒中心",
    "service_code": "S",
    "last_match_apply": "02/2026",
    "derived_wait_m": 6,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE020",
    "as_of": "2026-08-31",
    "unit_id": "PE020",
    "unit_name_raw": "仁濟醫院圓玄學院早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "04/2026",
    "derived_wait_m": 4,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE059",
    "as_of": "2026-08-31",
    "unit_id": "PE059",
    "unit_name_raw": "協康會上海總會菁田中心（早期教育及訓練中心）",
    "service_code": "E",
    "last_match_apply": "04/2026",
    "derived_wait_m": 4,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR024",
    "as_of": "2026-08-31",
    "unit_id": "PR024",
    "unit_name_raw": "仁濟醫院羅氏基金護幼中心暨宿舍 (住宿)",
    "service_code": "SR",
    "last_match_apply": "04/2026",
    "derived_wait_m": 4,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS046",
    "as_of": "2026-08-31",
    "unit_id": "PS046",
    "unit_name_raw": "救世軍駿洋幼兒中心（特殊幼兒中心）",
    "service_code": "S",
    "last_match_apply": "04/2026",
    "derived_wait_m": 4,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE011",
    "as_of": "2026-08-31",
    "unit_id": "PE011",
    "unit_name_raw": "香港明愛樂苗學前教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE045",
    "as_of": "2026-08-31",
    "unit_id": "PE045",
    "unit_name_raw": "協康會環翠中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE015C",
    "as_of": "2026-08-31",
    "unit_id": "PE015C",
    "unit_name_raw": "明德兒童啟育中心 (以中文為母語的幼兒而設)",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE031",
    "as_of": "2026-08-31",
    "unit_id": "PE031",
    "unit_name_raw": "香港基督教服務處摩理臣山兒童發展中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE029",
    "as_of": "2026-08-31",
    "unit_id": "PE029",
    "unit_name_raw": "匡智會匡智松嶺學前兒童中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE046",
    "as_of": "2026-08-31",
    "unit_id": "PE046",
    "unit_name_raw": "鄰舍輔導會景康幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS054",
    "as_of": "2026-08-31",
    "unit_id": "PS054",
    "unit_name_raw": "香港聾人福利促進會尚德幼兒中心",
    "service_code": "S",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS030",
    "as_of": "2026-08-31",
    "unit_id": "PS030",
    "unit_name_raw": "協康會裕明中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS027",
    "as_of": "2026-08-31",
    "unit_id": "PS027",
    "unit_name_raw": "香港耀能協會象山幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS051",
    "as_of": "2026-08-31",
    "unit_id": "PS051",
    "unit_name_raw": "香港小童群益會「樂航」兒童早期發展中心 (馬鞍山) (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "05/2026",
    "derived_wait_m": 3,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE010",
    "as_of": "2026-08-31",
    "unit_id": "PE010",
    "unit_name_raw": "協康會海富中心(早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE034",
    "as_of": "2026-08-31",
    "unit_id": "PE034",
    "unit_name_raw": "東華三院馬孔令琦兒童發展中心",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE058",
    "as_of": "2026-08-31",
    "unit_id": "PE058",
    "unit_name_raw": "路德會凝悅兒童發展中心",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE025",
    "as_of": "2026-08-31",
    "unit_id": "PE025",
    "unit_name_raw": "協康會大窩口中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE008",
    "as_of": "2026-08-31",
    "unit_id": "PE008",
    "unit_name_raw": "協康會良景早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE012",
    "as_of": "2026-08-31",
    "unit_id": "PE012",
    "unit_name_raw": "香港基督教服務處屯門早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS041",
    "as_of": "2026-08-31",
    "unit_id": "PS041",
    "unit_name_raw": "香港小童群益會「樂航」兒童早期發展中心(東涌) (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS032",
    "as_of": "2026-08-31",
    "unit_id": "PS032",
    "unit_name_raw": "保良局曹金霖幼兒學習中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS005",
    "as_of": "2026-08-31",
    "unit_id": "PS005",
    "unit_name_raw": "協康會秦石中心",
    "service_code": "S",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS011",
    "as_of": "2026-08-31",
    "unit_id": "PS011",
    "unit_name_raw": "香港耀能協會隆亨幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS037",
    "as_of": "2026-08-31",
    "unit_id": "PS037",
    "unit_name_raw": "匡智會匡智廣福學前兒童中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "06/2026",
    "derived_wait_m": 2,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE007C",
    "as_of": "2026-08-31",
    "unit_id": "PE007C",
    "unit_name_raw": "監護者早期教育中心(以中文為母語的幼兒而設)",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE026",
    "as_of": "2026-08-31",
    "unit_id": "PE026",
    "unit_name_raw": "香港耀能協會鴨脷洲幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE054",
    "as_of": "2026-08-31",
    "unit_id": "PE054",
    "unit_name_raw": "協康會雍明中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE060",
    "as_of": "2026-08-31",
    "unit_id": "PE060",
    "unit_name_raw": "香港耀能協會康城早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE057",
    "as_of": "2026-08-31",
    "unit_id": "PE057",
    "unit_name_raw": "保良局倪文玲(海達)兒童發展中心 (早期教育及訓練中心）",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE019",
    "as_of": "2026-08-31",
    "unit_id": "PE019",
    "unit_name_raw": "香港基督教服務處葵興早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE018",
    "as_of": "2026-08-31",
    "unit_id": "PE018",
    "unit_name_raw": "協康會賽馬會早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE049",
    "as_of": "2026-08-31",
    "unit_id": "PE049",
    "unit_name_raw": "保良局慧妍雅集兒童發展中心",
    "service_code": "E",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS026",
    "as_of": "2026-08-31",
    "unit_id": "PS026",
    "unit_name_raw": "心光幼兒中心 (日間特殊幼兒中心) (為視覺受損兒童而設)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS013",
    "as_of": "2026-08-31",
    "unit_id": "PS013",
    "unit_name_raw": "協康會灣仔中心",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS028",
    "as_of": "2026-08-31",
    "unit_id": "PS028",
    "unit_name_raw": "香港基督教服務處摩理臣山兒童發展中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS044",
    "as_of": "2026-08-31",
    "unit_id": "PS044",
    "unit_name_raw": "協康會雍明中心（特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS008",
    "as_of": "2026-08-31",
    "unit_id": "PS008",
    "unit_name_raw": "香港耀能協會橫頭磡幼兒中心",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS033",
    "as_of": "2026-08-31",
    "unit_id": "PS033",
    "unit_name_raw": "鄰舍輔導會陳蔭川欣康幼兒中心(特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS043",
    "as_of": "2026-08-31",
    "unit_id": "PS043",
    "unit_name_raw": "路德會凝趣兒童發展中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS010",
    "as_of": "2026-08-31",
    "unit_id": "PS010",
    "unit_name_raw": "香港耀能協會石硤尾幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS022",
    "as_of": "2026-08-31",
    "unit_id": "PS022",
    "unit_name_raw": "協康會長沙灣中心",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS034",
    "as_of": "2026-08-31",
    "unit_id": "PS034",
    "unit_name_raw": "香港耀能協會白田幼兒中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS045",
    "as_of": "2026-08-31",
    "unit_id": "PS045",
    "unit_name_raw": "保良局倪文玲(海達)兒童發展中心（特殊幼兒中心）",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS031",
    "as_of": "2026-08-31",
    "unit_id": "PS031",
    "unit_name_raw": "鄰舍輔導會啟康幼兒中心(特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS040",
    "as_of": "2026-08-31",
    "unit_id": "PS040",
    "unit_name_raw": "匡智松嶺學前兒童中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "07/2026",
    "derived_wait_m": 1,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE001",
    "as_of": "2026-08-31",
    "unit_id": "PE001",
    "unit_name_raw": "香港明愛樂幼學前教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE009",
    "as_of": "2026-08-31",
    "unit_id": "PE009",
    "unit_name_raw": "香港基督教服務處環翠早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE015E",
    "as_of": "2026-08-31",
    "unit_id": "PE015E",
    "unit_name_raw": "明德兒童啟育中心 (以英語為母語的幼兒而設)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE024",
    "as_of": "2026-08-31",
    "unit_id": "PE024",
    "unit_name_raw": "協康會東涌中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE052",
    "as_of": "2026-08-31",
    "unit_id": "PE052",
    "unit_name_raw": "香港小童群益會「樂航」兒童早期發展中心(東涌)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE048",
    "as_of": "2026-08-31",
    "unit_id": "PE048",
    "unit_name_raw": "協康會大口環早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE002",
    "as_of": "2026-08-31",
    "unit_id": "PE002",
    "unit_name_raw": "協康會順利早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE021",
    "as_of": "2026-08-31",
    "unit_id": "PE021",
    "unit_name_raw": "香港耀能協會德田早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE041",
    "as_of": "2026-08-31",
    "unit_id": "PE041",
    "unit_name_raw": "協康會鯉魚門中心 (早期教育訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE044",
    "as_of": "2026-08-31",
    "unit_id": "PE044",
    "unit_name_raw": "協康會上海總會油麗中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE050",
    "as_of": "2026-08-31",
    "unit_id": "PE050",
    "unit_name_raw": "香港耀能協會安泰幼兒中心(早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE022",
    "as_of": "2026-08-31",
    "unit_id": "PE022",
    "unit_name_raw": "基督教靈實協會梁烱初寶林早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE035",
    "as_of": "2026-08-31",
    "unit_id": "PE035",
    "unit_name_raw": "協康會裕明中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE006",
    "as_of": "2026-08-31",
    "unit_id": "PE006",
    "unit_name_raw": "香港基督教服務處彩雲早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE013",
    "as_of": "2026-08-31",
    "unit_id": "PE013",
    "unit_name_raw": "香港耀能協會懷熙早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE037",
    "as_of": "2026-08-31",
    "unit_id": "PE037",
    "unit_name_raw": "保良局曹金霖幼兒學習中心(早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE038",
    "as_of": "2026-08-31",
    "unit_id": "PE038",
    "unit_name_raw": "鄰舍輔導會陳蔭川欣康幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE053",
    "as_of": "2026-08-31",
    "unit_id": "PE053",
    "unit_name_raw": "路德會凝趣兒童發展中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE030",
    "as_of": "2026-08-31",
    "unit_id": "PE030",
    "unit_name_raw": "香港聾人福利促進會何文田中心 (早期教育及訓練中心) (為聽覺受損兒童而設）(在四個位於北角、將軍澳、何文田及屯門的服務單位提供機構為本的服務)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE003",
    "as_of": "2026-08-31",
    "unit_id": "PE003",
    "unit_name_raw": "協康會白田早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE023",
    "as_of": "2026-08-31",
    "unit_id": "PE023",
    "unit_name_raw": "協康會富昌中心(早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE027",
    "as_of": "2026-08-31",
    "unit_id": "PE027",
    "unit_name_raw": "香港耀能協會石硤尾幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE039",
    "as_of": "2026-08-31",
    "unit_id": "PE039",
    "unit_name_raw": "香港耀能協會白田幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE051",
    "as_of": "2026-08-31",
    "unit_id": "PE051",
    "unit_name_raw": "保良局倪文玲(深水埗)兒童發展中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE017",
    "as_of": "2026-08-31",
    "unit_id": "PE017",
    "unit_name_raw": "宣美語言及聽覺訓練中心 (為聽覺受損兒童而設）",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE042",
    "as_of": "2026-08-31",
    "unit_id": "PE042",
    "unit_name_raw": "香港耀能協會葵盛早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE004",
    "as_of": "2026-08-31",
    "unit_id": "PE004",
    "unit_name_raw": "協康會長青早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE061",
    "as_of": "2026-08-31",
    "unit_id": "PE061",
    "unit_name_raw": "仁濟醫院童夢兒童成長發展中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE032",
    "as_of": "2026-08-31",
    "unit_id": "PE032",
    "unit_name_raw": "香港耀能協會象山幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE005",
    "as_of": "2026-08-31",
    "unit_id": "PE005",
    "unit_name_raw": "協康會郭葉鍊洪早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE028",
    "as_of": "2026-08-31",
    "unit_id": "PE028",
    "unit_name_raw": "香港耀能協會隆亨幼兒中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE036",
    "as_of": "2026-08-31",
    "unit_id": "PE036",
    "unit_name_raw": "鄰舍輔導會啟康幼兒中心（早期教育及訓練中心）",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE043",
    "as_of": "2026-08-31",
    "unit_id": "PE043",
    "unit_name_raw": "保良局梁安琪兒童發展中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE055",
    "as_of": "2026-08-31",
    "unit_id": "PE055",
    "unit_name_raw": "救世軍駿洋幼兒中心（早期教育及訓練中心）",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE062",
    "as_of": "2026-08-31",
    "unit_id": "PE062",
    "unit_name_raw": "香港小童群益會「樂航」兒童早期發展中心 (馬鞍山) (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE014",
    "as_of": "2026-08-31",
    "unit_id": "PE014",
    "unit_name_raw": "協康會譚杜早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE047",
    "as_of": "2026-08-31",
    "unit_id": "PE047",
    "unit_name_raw": "匡智會匡智廣福學前兒童中心 (早期教育及訓練中心)",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PE056",
    "as_of": "2026-08-31",
    "unit_id": "PE056",
    "unit_name_raw": "仁濟醫院嚴徐玉珊早期教育及訓練中心",
    "service_code": "E",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-012",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR019",
    "as_of": "2026-08-31",
    "unit_id": "PR019",
    "unit_name_raw": "母親的抉擇特殊幼兒住宿中心 (住宿）",
    "service_code": "SR",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS015",
    "as_of": "2026-08-31",
    "unit_id": "PS015",
    "unit_name_raw": "協康會環翠中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS002",
    "as_of": "2026-08-31",
    "unit_id": "PS002",
    "unit_name_raw": "協康會慶華中心 (特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS007",
    "as_of": "2026-08-31",
    "unit_id": "PS007",
    "unit_name_raw": "香港耀能協會鴨脷洲幼兒中心 (日間特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS023",
    "as_of": "2026-08-31",
    "unit_id": "PS023",
    "unit_name_raw": "協康會陳宗漢紀念中心",
    "service_code": "S",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PS047",
    "as_of": "2026-08-31",
    "unit_id": "PS047",
    "unit_name_raw": "路德會凝悅兒童發展中心(特殊幼兒中心)",
    "service_code": "S",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  },
  {
    "snapshot_id": "2026-08-31-PR001",
    "as_of": "2026-08-31",
    "unit_id": "PR001",
    "unit_name_raw": "匡智會匡智松嶺學前兒童中心 (住宿）",
    "service_code": "SR",
    "last_match_apply": "08/2026",
    "derived_wait_m": 0,
    "source_id": "SRC-013",
    "run_id": "20261012-01"
  }
]
"""#,
    ]
}
