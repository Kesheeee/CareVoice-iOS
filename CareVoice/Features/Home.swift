import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var recording = false
    @State private var profileOpen = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let profile = store.data.profile {
                    Card {
                        HStack(spacing: 14) {
                            Text(String(profile.displayName(store.language).prefix(1))).font(.title2.bold()).foregroundStyle(Brand.blue)
                                .frame(width: 48, height: 48).background(Brand.blue.opacity(0.08), in: Circle())
                            VStack(alignment: .leading, spacing: 5) {
                                Text(profile.displayName(store.language)).font(.title3.bold())
                                Text(profile.age(store.language)).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { profileOpen = true } label: { Label(store.t("Edit", "編輯"), systemImage: "pencil") }.font(.subheadline)
                        }
                    }
                }
                PrimaryButton(title: store.t("Add an observation", "新增觀察"), symbol: "plus") { recording = true }.accessibilityIdentifier("captureMoment")
                HStack(spacing: 14) {
                    NavigationLink { NavigatorView() } label: { shortcut("safari", store.t("Your next step", "下一步")) }
                    NavigationLink { ReportsView() } label: { shortcut("doc.text", store.t("Reports", "報告")) }
                }.buttonStyle(.plain)
                NavigationLink { QuestionnaireView() } label: {
                    Card { SettingsRow(title: store.t("Questionnaire", "觀察問卷"), icon: "book", value: "\(store.data.reviewedCount)/\(store.questions.count)") }
                }.buttonStyle(.plain).accessibilityIdentifier("openQuestionnaire")
                HStack {
                    Text(store.t("Recent records", "最近記錄")).font(.title3.bold())
                    Spacer()
                    NavigationLink(store.t("View all", "查看全部")) { RecordsView() }.font(.subheadline)
                }
                if store.data.records.isEmpty {
                    ContentUnavailableView(store.t("No records yet", "仲未有記錄"), systemImage: "book")
                } else {
                    ForEach(store.data.records.sorted { $0.date > $1.date }.prefix(3)) { record in
                        NavigationLink { RecordDetail(recordID: record.id) } label: { RecordCard(record: record) }.buttonStyle(.plain)
                    }
                }
            }.padding(20)
        }.background(Brand.background).navigationTitle(store.t("Home", "首頁"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { SettingsView() } label: { Image(systemName: "gearshape").frame(width: 44, height: 44) }.accessibilityLabel(store.t("Settings", "設定")).accessibilityIdentifier("openSettings") } }
            .sheet(isPresented: $recording) { NavigationStack { RecordEditor() } }
            .sheet(isPresented: $profileOpen) { NavigationStack { ProfileEditor() } }
            .navigationDestination(isPresented: $store.showQuestionnaire) { QuestionnaireView() }
    }
    private func shortcut(_ icon: String, _ title: String) -> some View {
        Card {
            HStack { Image(systemName: icon).font(.title2).foregroundStyle(Brand.blue); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
            Text(title).font(.headline)
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
                    if store.data.needsSafetyRouting { SafetyGuidance() }
                    ForEach(store.questions) { q in
                        Button { index = store.questions.firstIndex(where: { $0.id == q.id }) ?? 0; summary = false } label: {
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
                                if [29, 30, 131].contains(q.id) && (answer == .yes || answer == .unsure) { followUp = true }
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
                    if (q.id == 132 || q.id == 133), store.data.answers[q.id] == .yes || store.data.answers[q.id] == .unsure { SafetyGuidance() }
                    if q.id == 131, store.data.answers[q.id] == .yes || store.data.answers[q.id] == .unsure {
                        TextField(store.t("When did you notice this? (optional)", "何時留意到？（選填）"), text: Binding(get: { store.data.regressionWhen?[q.id] ?? "" }, set: { value in store.update { if $0.regressionWhen == nil { $0.regressionWhen = [:] }; $0.regressionWhen?[q.id] = value } })).textFieldStyle(.roundedBorder)
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
