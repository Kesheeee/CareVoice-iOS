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
                tab(3, "gearshape", store.t("Settings", "設定"))
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
    @State private var deleting = false
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
            Section(store.t("Preferences", "偏好設定")) {
                Picker(store.t("Language", "語言"), selection: Binding(get: { store.language }, set: { store.setLanguage($0) })) {
                    Text("English").tag(AppLanguage.english)
                    Text("繁體中文").tag(AppLanguage.traditionalChinese)
                }.accessibilityIdentifier("languagePicker")
                NavigationLink(store.t("Observation questionnaire", "情況問卷")) { QuestionnaireView() }
                NavigationLink(store.t("Reports", "報告")) { ReportsView() }
            }
            NativeBackupControls()
            Section(store.t("Your privacy", "你的私隱")) {
                Label(store.t("Stored on this device", "儲存於此裝置"), systemImage: "iphone.and.arrow.forward")
                Text(store.t("No account, analytics, advertising or cloud sync. Records use iOS file protection and are excluded from device backups. Deleting the app or losing the device may lose your records. Share a report when you want to keep a copy.", "無帳戶、分析追蹤、廣告或雲端同步。記錄使用 iOS 檔案保護，並不會包含於裝置備份。刪除應用程式或遺失裝置可能導致記錄遺失，你可分享報告以保留副本。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section(store.t("About CareVoice", "關於 CareVoice")) {
                Text(store.t("A companion for observation and service navigation. This app does not diagnose, screen for ASD, infer severity or replace professional advice.", "協助觀察記錄及服務導航的工具，不提供診斷、自閉症篩查或嚴重程度判斷，亦不能替代專業意見。"))
                    .font(.footnote).foregroundStyle(.secondary)
                LabeledContent(store.t("Version", "版本"), value: "1.0 · MVP")
            }
            Section {
                Button(store.t("Delete all local data", "刪除所有本機資料"), role: .destructive) { deleting = true }
            }
        }.navigationTitle(store.t("Settings", "設定"))
            .sheet(isPresented: $editing) { NavigationStack { ProfileEditor() } }
            .alert(store.t("Delete all local data?", "刪除所有本機資料？"), isPresented: $deleting) {
                Button(store.t("Cancel", "取消"), role: .cancel) { }
                Button(store.t("Delete everything", "全部刪除"), role: .destructive) { store.erase() }
            } message: { Text(store.t("Your profile, questionnaire and records will be removed from this app. This cannot be undone. Copies you already shared are not deleted.", "你的檔案、問卷和記錄將從此應用程式移除，無法復原。已分享的副本不會被刪除。")) }
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(store.t("Reliable places to turn.", "找到可靠的支援。"))
                    .font(.system(.title, design: .rounded).bold())
                Text(store.t("Official information to explore with the people supporting your family.", "與支援你家庭的專業人士一起了解官方資訊。"))
                    .foregroundStyle(.secondary)
                ForEach(OfficialResource.all) { resource in ResourceCard(resource: resource) }
                Card {
                    Label(store.t("You don’t have to figure it out alone", "不用獨自面對"), systemImage: "heart").font(.headline)
                    Text(store.t("Ask your social worker or assessment team about family support and available services. Eligibility and arrangements are confirmed by the service provider.", "可向社工或評估團隊了解家庭支援及服務，資格與安排以服務機構確認為準。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text(store.t("Links reviewed 15 October 2026. Official pages may be updated. External links open in your browser.", "連結於 2026 年 10 月 15 日核對。官方網頁內容可能更新，外部連結會在瀏覽器開啟。"))
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Community", "社區"))
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
