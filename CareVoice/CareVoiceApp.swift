import SwiftUI

@main
struct CareVoiceApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            Group {
                if store.storageUnavailable {
                    ContentUnavailableView("Saved data unavailable", systemImage: "lock.shield", description: Text("Your data is preserved. Unlock your device and restart CareVoice."))
                } else if store.data.profile == nil {
                    WelcomeView()
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
    static let blue = Color(red: 0.08, green: 0.36, blue: 0.72)
    static let teal = Color(red: 0.04, green: 0.52, blue: 0.48)
    static let background = Color(uiColor: .systemGroupedBackground)
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
        TabView(selection: $selection) {
            NavigationStack { HomeView() }.tabItem { Label(store.t("Home", "首頁"), systemImage: "house") }.tag(0)
            NavigationStack { RecordsView() }.tabItem { Label(store.t("Records", "記錄"), systemImage: "text.book.closed") }.tag(1)
            NavigationStack { ResourcesView() }.tabItem { Label(store.t("Resources", "資源"), systemImage: "person.2") }.tag(2)
            NavigationStack { ProfileView() }.tabItem { Label(store.t("Profile", "我的"), systemImage: "person.crop.circle") }.tag(3)
        }
    }
}
