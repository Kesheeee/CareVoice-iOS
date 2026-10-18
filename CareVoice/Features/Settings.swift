import SwiftUI

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
            // REVIEW_BACKUP_CONTROLS
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
