import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data = AppData()
    @Published var errorMessage: String?
    @Published private(set) var storageUnavailable = false
    let community = CommunityStore()
    let questions: [Question]
    let content: GovernmentContent
    private let fileURL: URL
    private let isUITest: Bool
    var language: AppLanguage { data.language }
    func t(_ en: String, _ zh: String) -> String { language.text(en, zh) }

    init() {
        content = GovernmentContent.load()
        isUITest = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CareVoice", isDirectory: true)
        fileURL = directory.appendingPathComponent(isUITest ? "ui-test-data.json" : "family-data.json")
        do {
            guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
            questions = try JSONDecoder().decode([Question].self, from: Data(contentsOf: url))
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
