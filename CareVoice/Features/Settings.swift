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
    @State private var languageOpen = false
    @State private var profileOpen = false
    @State private var deleting = false
    var body: some View {
        List {
            Section(store.t("Preferences", "偏好設定")) {
                Button { profileOpen = true } label: { SettingsRow(title: store.t("Profile", "個人檔案"), icon: "person") }.accessibilityIdentifier("settings-preferences")
                Button { languageOpen = true } label: { SettingsRow(title: store.t("Language", "語言"), icon: "globe", value: store.language.displayName) }.accessibilityIdentifier("languagePicker")
            }
            Section(store.t("Care", "照顧工具")) {
                NavigationLink { QuestionnaireView() } label: { SettingsRow(title: store.t("Observation questions", "觀察問卷"), icon: "book", value: "\(store.data.answeredCount)/\(store.questions.count)", chevron: false) }.accessibilityIdentifier("openQuestionnaire")
                NavigationLink { ReportsView() } label: { SettingsRow(title: store.t("Reports & sharing", "報告同分享"), icon: "doc.text", chevron: false) }.accessibilityIdentifier("openReports")
            }
            NativeBackupControls()
            Section {
                Button(role: .destructive) { deleting = true } label: { Label(store.t("Delete all local data", "刪除所有本機資料"), systemImage: "trash") }.accessibilityIdentifier("deleteLocalData")
            }
            Section {
                DisclosureGroup(store.t("Privacy & storage", "私隱同儲存")) {
                    Text(store.t("Your child’s records stay on this device, protected by iOS. They are not synced to your account or included in device backups. Export a backup before changing devices or deleting the app.", "孩子的記錄受 iOS 保護並保留於此裝置，不會同步至帳戶或包括在裝置備份內。更換裝置或刪除應用程式前請匯出備份。")).font(.subheadline).foregroundStyle(Color.secondary)
                }
            }
            AccountSettingsRow(community: store.community)
        }.scrollContentBackground(.hidden).background(Brand.background)
            .navigationTitle(store.t("Settings", "設定"))
            .sheet(isPresented: $languageOpen) { LanguageSettingsView() }
            .sheet(isPresented: $profileOpen) { NavigationStack { ProfileEditor() } }
            .alert(store.t("Delete all local data?", "刪除所有本機資料？"), isPresented: $deleting) {
                Button(store.t("Cancel", "取消"), role: .cancel) {}
                Button(store.t("Delete everything", "全部刪除"), role: .destructive) { store.erase() }
            } message: { Text(store.t("This removes this account’s profile, records and answers from this device. Shared copies are not deleted.", "將刪除此帳戶在本裝置的檔案、記錄及答案，已分享的副本不會刪除。")) }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    var value = ""
    var chevron = true
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(Brand.blue).frame(width: 24)
            Text(title).foregroundStyle(Color.primary)
            Spacer(minLength: 8)
            if !value.isEmpty { Text(value).font(.subheadline).foregroundStyle(Color.secondary).multilineTextAlignment(.trailing) }
            if chevron { Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.secondary) }
        }.frame(minHeight: 48).contentShape(Rectangle())
    }
}

struct AccountSettingsRow: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    var body: some View {
        if let user = community.user {
            Section(store.t("Account", "帳戶")) {
                Text(user.email ?? "").font(.subheadline).foregroundStyle(Color.secondary).listRowBackground(Color.clear).listRowSeparator(.hidden)
                Button(role: .destructive) { Task { _ = await community.signOut() } } label: {
                    Text(community.busy ? store.t("Logging out…", "正在登出…") : store.t("Log out", "登出"))
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                }.disabled(community.busy).listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
        }
    }
}

struct LanguageSettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected = AppLanguage.english
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(store.t("Choose your language", "選擇語言")).font(.title2.bold())
                Text(store.t("Changes the app’s text. Your notes stay as you wrote them.", "更改應用程式文字，你的記錄會保留原文。")).foregroundStyle(Color.secondary)
                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        Button { selected = language } label: {
                            HStack {
                                Text(language.displayName).foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: selected == language ? "checkmark.circle.fill" : "circle").foregroundStyle(Brand.blue)
                            }.padding(20).frame(minHeight: 64)
                                .background(selected == language ? Brand.blue.opacity(0.08) : .white, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected == language ? Brand.blue : Color.gray.opacity(0.2)))
                        }.accessibilityIdentifier("language-" + language.rawValue).accessibilityAddTraits(selected == language ? .isSelected : [])
                    }
                }
                Spacer(minLength: 0)
                Button(store.t("Save language", "儲存語言")) { store.setLanguage(selected); dismiss() }.buttonStyle(AccountPrimaryStyle()).accessibilityIdentifier("saveLanguage")
            }.padding(24).background(Brand.background)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(store.t("Cancel", "取消")) { dismiss() } } }
        }.onAppear { selected = store.language }.presentationDetents([.large]).presentationDragIndicator(.visible)
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
            case .security, .community: CommunityAccountView(community: store.community)
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
                    .font(.footnote).foregroundStyle(Color.secondary)
            }
            NativeBackupControls()
            Section(store.t("AI sharing", "與 AI 分享")) {
                Label(store.t("AI is not connected", "AI 尚未連接"), systemImage: "lock.shield")
                Text(store.t("Questions and records are not sent to an AI service. Sharing controls will be available when the service is connected.", "問題及記錄不會傳送至 AI 服務。連接服務後才會提供分享控制。"))
                    .font(.subheadline).foregroundStyle(Color.secondary)
            }
            Section(store.t("Device storage", "裝置儲存")) {
                Text(store.t("Records use iOS file protection and are excluded from device backups. Deleting the app or losing this device may lose your records. Export a copy you want to keep.", "記錄使用 iOS 檔案保護，並不包含於裝置備份。刪除應用程式或遺失裝置可能導致記錄遺失。請匯出需要保留的副本。"))
                    .font(.subheadline).foregroundStyle(Color.secondary)
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
            Text(store.t(body, zhBody)).foregroundStyle(Color.secondary).fixedSize(horizontal: false, vertical: true)
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
                    paragraph("Can I ask the AI or publish a post?", "可以提問 AI 或發佈帖子嗎？", "AI is not connected yet. In Parents, sign in and choose a public nickname to share posts and replies once the community service is configured.", "AI 尚未連接。社區服務設定完成後，可於家長交流登入並選擇公開暱稱，分享帖子及回覆。")
                    paragraph("Contact support / report a problem", "聯絡支援／回報問題", "A support contact has not been configured. For this review build, share the steps to reproduce the problem with the person who provided the app. Avoid including your child's records.", "尚未設定支援聯絡方式。使用此審閱版本時，請向提供應用程式的人說明問題的重現步驟，避免附上孩子的記錄。")
                case .privacy:
                    paragraph("Current data handling", "目前的資料處理", "Child profiles, observations and answers stay on your device. Community sign-in uses your email; your chosen public nickname, posts and replies are stored in the community service and visible to signed-in members. Reports are visible to moderators and their author. AI questions are not sent to a server.", "孩子檔案、觀察及答案保留於裝置。社區登入使用電郵；公開暱稱、帖子及回覆會儲存於社區服務，並供已登入成員查看。舉報只供管理員及舉報者查看。AI 問題不會傳送至伺服器。")
                    paragraph("Sharing and external links", "分享及外部連結", "Reports and exports leave this device through the destination you choose. Opening an official resource visits an external website with its own privacy practices.", "報告及匯出資料只會透過你選擇的目的地離開裝置。開啟官方資源會前往外部網站，該網站有其私隱安排。")
                    paragraph("Policy publication pending", "私隱政策待發佈", "This describes the current review build. A published privacy policy and operator contact must be added before online accounts or community sharing launch.", "以上說明適用於目前的審閱版本。推出網上帳戶或社區分享前，須加入已發佈的私隱政策及營運者聯絡方式。")
                case .guidelines:
                    paragraph("Community guidelines — draft", "社區守則 — 草稿", "Be kind to other caregivers. Share your own experience without identifying another child or family. Peer stories should not be presented as a diagnosis or professional advice.", "請友善對待其他照顧者。分享自身經驗時，避免披露其他孩子或家庭的身份。個人經驗不應當作診斷或專業意見。")
                    paragraph("Before public posting opens", "開放公開發帖前", "Use the menu on a post or reply to report a concern or block its author. Moderators can review reports and remove content. Do not post emergencies or expect an immediate response. Final operating policies and a support contact are required before public launch.", "可於帖子或回覆選單舉報問題或封鎖作者。管理員可審核舉報並移除內容。請勿發佈緊急求助或期待即時回應。公開推出前須訂立最終營運政策及支援聯絡方式。")
                case .terms:
                    paragraph("Terms are not published yet", "使用條款尚未發佈", "This is a review build. Final service terms and the operator's contact details must be added before account and community services launch. No terms acceptance is collected on this page.", "此為審閱版本。推出帳戶及社區服務前，須加入最終服務條款及營運者聯絡資料。本頁不會收集條款同意。")
                case .about:
                    paragraph("CareVoice", "CareVoice", "A place to record everyday observations, prepare for conversations and find service information while caring for your child.", "照顧孩子時，記錄日常觀察、準備溝通內容及尋找服務資訊的地方。")
                    paragraph("Our role", "我們的角色", "CareVoice does not diagnose, screen for ASD, infer severity or replace professional advice.", "CareVoice 不提供診斷、自閉症篩查或嚴重程度判斷，亦不取代專業意見。")
                    Text(store.t("Version", "版本") + " " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                        .font(.footnote).foregroundStyle(Color.secondary)
                default: EmptyView()
                }
            }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(Brand.background)
    }
}
