import SwiftUI

@main
struct CareVoiceApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            AppRoot(community: store.community)
            .environmentObject(store)
            .environment(\.locale, store.language.locale)
            .tint(Brand.blue)
            .preferredColorScheme(.light)
            .alert(store.t("Unable to complete action", "未能完成操作"), isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button(store.t("OK", "確定"), role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }
}

struct AppRoot: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    private var testing: Bool { ProcessInfo.processInfo.arguments.contains("--ui-testing") && !ProcessInfo.processInfo.arguments.contains("--auth-preview") }
    var body: some View {
        Group {
            if community.restoring && !testing { ProgressView() }
            else if community.user == nil && !testing { WelcomeView() }
            else if !testing && store.activeAccountID != community.user?.id { ProgressView() }
            else if store.storageUnavailable {
                ContentUnavailableView(store.t("Saved data unavailable", "未能讀取資料"), systemImage: "lock.shield", description: Text(store.t("Your data is preserved. Unlock your device and restart CareVoice.", "資料已保留。請解鎖裝置並重新啟動。")))
            } else if store.data.profile == nil { NativeSurvey() }
            else { MainView().id(community.user?.id) }
        }
        .task { await community.start(); store.activateAccount(community.user?.id) }
        .onChange(of: community.user?.id) { _, id in store.activateAccount(id) }
        .alert(store.t("Import your existing notes?", "匯入現有記錄？"), isPresented: $store.offerImport) {
            Button(store.t("Import", "匯入")) { store.importGuest() }
            Button(store.t("Start fresh", "重新開始"), role: .cancel) {}
        } message: { Text(store.t("Copy this device’s previous profile and records into this account? They will stay on this device.", "將此裝置原有的檔案及記錄複製到此帳戶？資料仍只保留於此裝置。")) }
    }
}

enum Brand {
    static let blue = Color(red: 0.082, green: 0.396, blue: 0.753)
    static let teal = Color(red: 0.04, green: 0.52, blue: 0.48)
    static let background = Color(red: 0.965, green: 0.970, blue: 0.985)
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { if !symbol.isEmpty { Image(systemName: symbol) }; Text(title).fontWeight(.semibold) }
                .padding(.horizontal, 18).frame(maxWidth: .infinity, minHeight: 56)
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
    @State private var addingRecord = false
    @State private var savedRecordID: UUID?
    var body: some View {
        NavigationStack {
            Group {
                switch selection {
                case 1: RecordsView()
                case 2: ResourcesView()
                case 3: SettingsView()
                default: HomeView()
                }
            }.safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    tab(0, "house", store.t("Home", "首頁"))
                    tab(1, "book", store.t("Tracker", "追蹤"))
                    Button { addingRecord = true } label: {
                        Image(systemName: "plus").font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 50, height: 50).background(Brand.blue, in: Circle())
                    }.frame(maxWidth: .infinity).accessibilityLabel(store.t("New record", "新增記錄")).accessibilityIdentifier("addRecord")
                    tab(2, "person.2", store.t("Community", "社區"))
                    tab(3, "gearshape", store.t("Settings", "設定"))
                }.padding(.vertical, 8).background(.bar)
            }
            .sheet(isPresented: $addingRecord) { NavigationStack { RecordEditor(onSaved: { savedRecordID = $0.id }) } }
            .navigationDestination(item: $savedRecordID) { id in RecordDetail(recordID: id) }
        }.id(selection)
    }
    private func tab(_ index: Int, _ icon: String, _ title: String) -> some View {
        Button { selection = index } label: {
            Image(systemName: selection == index ? "\(icon).fill" : icon).font(.system(size: 25, weight: .regular))
                .frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(selection == index ? Brand.blue : .secondary)
        }.accessibilityLabel(title).accessibilityIdentifier("tab-\(index)").accessibilityAddTraits(selection == index ? .isSelected : [])
    }
}
