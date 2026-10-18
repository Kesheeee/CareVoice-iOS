import SwiftUI

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
                        Menu { ForEach(AppLanguage.allCases) { l in Button(l.displayName) { store.setLanguage(l) } } } label: {
                            Label(store.language.shortName, systemImage: "globe")
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
                Stepper(value: $profile.ageMonths, in: 0...83) {
                    LabeledContent(store.t("Age", "年齡"), value: profile.age(store.language))
                }
            } header: { Text(store.t("About your child", "關於你的孩子")) }
            footer: { Text(store.t("Use a nickname. A full name, photo and exact birth date are not needed.", "使用暱稱即可，無須提供全名、相片或確實出生日期。")) }
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
