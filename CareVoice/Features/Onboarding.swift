import SwiftUI

struct ProfileEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var isOnboarding = false
    @State private var profile = ChildProfile()
    var body: some View {
        Form {
            Section {
                TextField(store.t("Nickname (optional)", "暱稱（選填）"), text: $profile.nickname).textContentType(.nickname).accessibilityIdentifier("nickname")
                DatePicker(store.t("Birthday", "生日"), selection: Binding(get: { profile.birthDate ?? Calendar.current.date(byAdding: .month, value: -profile.ageMonths, to: Date())! }, set: { profile.birthDate = $0; profile.ageMonths = profile.currentAgeMonths }), in: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .year, value: -7, to: Calendar.current.startOfDay(for: Date()))!)!...Date(), displayedComponents: .date)
            } header: { Text(store.t("About your child", "關於你的孩子")) }
            footer: { Text(store.t("Use a nickname. Your child’s details stay on this device.", "使用暱稱即可。孩子的資料只儲存於此裝置。")) }
            Section {
                ForEach(JourneyStage.onboarding) { stage in
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
            if profile.stage == .diagnosed {
                Section(store.t("Details from your report (optional)", "報告資料（選填）")) {
                    TextField(store.t("Diagnosing organisation", "診斷機構"), text: Binding(get: { profile.diagnosingBody ?? "" }, set: { profile.diagnosingBody = $0 }))
                    TextField(store.t("Report date", "報告日期"), text: Binding(get: { profile.diagnosisDate ?? "" }, set: { profile.diagnosisDate = $0 }))
                    TextField(store.t("Support level (copied from report)", "支援程度（照報告填寫）"), text: Binding(get: { profile.reportedSupportLevel ?? "" }, set: { profile.reportedSupportLevel = $0 }))
                }
            }
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

struct NativeSurvey: View {
    @EnvironmentObject var store: AppStore
    @State private var showIntro = false
    @State private var pending: ChildProfile?
    var body: some View {
        CareVoiceSurveyReview(chinese: store.language == .traditionalChinese, simplifiedChinese: store.language == .simplifiedChinese, onClose: { Task { _ = await store.community.signOut() } }) { answer in
            var profile = ChildProfile()
            profile.nickname = answer.nickname; profile.birthDate = answer.birthDate
            profile.ageMonths = answer.ageMonths; profile.stage = JourneyStage(rawValue: answer.stage) ?? .noticed
            profile.supportGoals = answer.supportGoals; profile.concernNotes = answer.notes
            if profile.stage == .noticed { pending = profile; showIntro = true }
            else { _ = store.saveProfile(profile) }
        }.sheet(isPresented: $showIntro) {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "book").font(.largeTitle).foregroundStyle(Brand.blue)
                Text(store.t("Get to know their world", "了解孩子的日常")).font(.title.bold())
                Text(store.t("33 optional observation questions. Save as you go, skip any question, and return whenever you’re ready. There is no score or diagnosis.", "33 道選填觀察題目。隨時儲存、略過或稍後繼續，不會評分或診斷。"))
                PrimaryButton(title: store.t("Start questions", "開始回答")) { store.showQuestionnaire = true; finish() }
                Button(store.t("Maybe later", "稍後再說")) { finish() }.frame(maxWidth: .infinity, minHeight: 44)
            }.padding(24).presentationDetents([.medium, .large]).interactiveDismissDisabled()
        }
    }
    private func finish() { if let pending { _ = store.saveProfile(pending) }; showIntro = false }
}
