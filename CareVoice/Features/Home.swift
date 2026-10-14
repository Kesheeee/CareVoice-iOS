import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var recording = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.t("ONE MOMENT AT A TIME", "每天一點一滴")).font(.caption.weight(.semibold)).tracking(1.8).foregroundStyle(Brand.teal)
                        Text(store.t("You’re doing this\ntogether.", "陪伴成長\n一起向前。"))
                            .font(.system(.largeTitle, design: .rounded).bold())
                    }
                    Spacer()
                    Image(systemName: "sun.max.fill").font(.system(size: 38)).foregroundStyle(.orange.opacity(0.75)).padding(.top, 18).accessibilityHidden(true)
                }
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
                        Text(store.t("Your stage, chosen by you", "由你選擇的目前階段")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 14) {
                    stat("\(store.data.records.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count)", store.t("Moments this month", "本月記錄"), "text.bubble", Brand.blue)
                    stat("\(store.data.answeredCount)/\(store.questions.count)", store.t("Questions answered", "已回答題目"), "list.clipboard", Brand.teal)
                }
                PrimaryButton(title: store.t("Capture a moment", "記下這一刻"), symbol: "plus") { recording = true }.accessibilityIdentifier("captureMoment")
                SectionHeading(title: store.t("A little guidance", "給你一點指引"))
                NavigationLink { NavigatorView() } label: {
                    feature("safari", store.t("Your next step", "下一步"), store.t("Find your way through local services", "了解本地服務與輪候安排"), Brand.blue)
                }.buttonStyle(.plain)
                if store.data.profile?.stage == .noticed || !store.data.answers.isEmpty {
                    NavigationLink { QuestionnaireView() } label: {
                        feature("list.clipboard", store.t("Get to know their world", "了解孩子的日常"), store.t("30 gentle observation prompts · save as you go", "30 道觀察題目・隨時儲存進度"), Brand.teal)
                    }.buttonStyle(.plain).accessibilityIdentifier("openQuestionnaire")
                }
                NavigationLink { ReportsView() } label: {
                    feature("doc.text", store.t("Prepare for a conversation", "為會面做好準備"), store.t("Bring your observations together in a report", "將你的觀察整理成報告"), .purple)
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
            .navigationTitle("CareVoice").navigationBarTitleDisplayMode(.inline)
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
