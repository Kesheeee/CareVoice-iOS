import SwiftUI

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
    @State private var section = 0
    @State private var topic = "first"
    @State private var question = ""
    @State private var submittedQuestion: String?
    @FocusState private var typing: Bool

    private var relevantResources: [OfficialResource] {
        // Explicit topic selection, not AI matching or clinical suitability scoring.
        let ids: [String]
        switch topic {
        case "appointment": ids = ["appointment", "first"]
        case "referral": ids = ["referral", "support"]
        default: ids = ["first", "services"]
        }
        return OfficialResource.all.filter { ids.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(store.t("Community section", "社區分類"), selection: $section) {
                Text(store.t("Ask CareVoice", "問 CareVoice")).tag(0)
                Text(store.t("Resources", "資源")).tag(1)
                Text(store.t("Parents", "家長交流")).tag(2)
            }.pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 12)
            if section == 2 {
                ParentCommunityView(community: store.community)
            } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if section == 0 { askContent }
                    else if section == 1 {
                        Text(store.t("Official resources", "官方資源")).font(.title2.bold())
                        Text(store.t("Browse service information from the Department of Health and Social Welfare Department.", "瀏覽衛生署及社會福利署嘅服務資料。"))
                            .font(.subheadline).foregroundStyle(.secondary)
                        NavigationLink { ServiceTypesView() } label: { Label(store.t("Service types", "服務種類"), systemImage: "square.grid.2x2").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { ServiceDirectoryView() } label: { Label(store.t("Find a centre · waiting times", "尋找中心・輪候時間"), systemImage: "mappin.and.ellipse").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { GlossaryView() } label: { Label(store.t("Glossary", "術語對照"), systemImage: "character.book.closed").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        NavigationLink { CitableFactsView() } label: { Label(store.t("Cited information", "可引用資料"), systemImage: "checkmark.seal").frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 16)) }
                        ForEach(OfficialResource.all) { resource in ResourceCard(resource: resource) }
                        sourceNote
                    }
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.scrollDismissesKeyboard(.interactively)
            }
            if section == 0 { composer }
        }
        .background(Brand.background)
        .navigationTitle(store.t("Community", "社區"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var askContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill").font(.title2).foregroundStyle(Brand.blue)
                    .frame(width: 52, height: 52).background(Brand.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.t("A little help, one question at a time.", "一個問題，一齊搵方向。")).font(.headline)
                    Text(store.t("AI connection pending", "AI 尚未連接")).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(store.t("What would you like help with today?", "今日想了解邊方面？")).font(.title2.bold())
            Text(store.t("Choose a topic to browse official links, or try writing your question below. No question is sent while AI is disconnected.", "揀主題瀏覽官方連結，或者喺下面試寫問題。AI 未連接前，問題唔會傳送。"))
                .font(.subheadline).foregroundStyle(.secondary)
            VStack(spacing: 10) {
                topicButton("first", "Understanding my child’s needs", "了解小朋友嘅需要", "heart", .blue)
                topicButton("appointment", "Finding assessment services", "尋找評估服務", "stethoscope", .purple)
                topicButton("referral", "Support while waiting", "輪候期間嘅支援", "clock", .orange)
            }
            if let submittedQuestion {
                HStack { Spacer(minLength: 32); Text(submittedQuestion).padding(16).background(Brand.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20)) }
                Card {
                    Label(store.t("Not sent", "未傳送"), systemImage: "wifi.slash").font(.subheadline.bold())
                    Text(store.t("CareVoice AI is not connected yet. These links are selected by your topic, not an analysis of your situation.", "CareVoice AI 尚未連接。以下連結按你揀嘅主題顯示，並非對你情況嘅分析。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button(store.t("Clear question", "清除問題")) { self.submittedQuestion = nil }
                }
            }
            HStack { Text(store.t("Resources for this topic", "呢個主題嘅資源")).font(.headline); Spacer(); Image(systemName: "checkmark.shield").foregroundStyle(Brand.blue) }
            ForEach(relevantResources) { resource in ResourceCard(resource: resource) }
            sourceNote
            Text(store.t("Clinic matching will need verified location, service and referral data. CareVoice does not diagnose or confirm clinic availability.", "配對診所需要已核實嘅地區、服務同轉介資料。CareVoice 唔會診斷或確認診所名額。"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func topicButton(_ id: String, _ en: String, _ zh: String, _ symbol: String, _ color: Color) -> some View {
        Button { topic = id } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 24).foregroundStyle(Brand.blue)
                Text(store.t(en, zh)).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: topic == id ? "checkmark.circle.fill" : "circle").foregroundStyle(topic == id ? Brand.blue : Color.secondary)
            }.padding(16).frame(minHeight: 56).background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(topic == id ? Brand.blue : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain).accessibilityAddTraits(topic == id ? .isSelected : [])
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(store.t("Describe what’s happening…", "講吓你遇到嘅情況…"), text: $question, axis: .vertical)
                .lineLimit(1...4).focused($typing).padding(14)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                .onChange(of: question) { question = String($0.prefix(2000)) }
            Button {
                submittedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
                question = ""; typing = false
            } label: {
                Image(systemName: "arrow.up").font(.headline).foregroundStyle(.white)
                    .frame(width: 48, height: 48).background(Brand.blue, in: Circle())
            }.disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(store.t("Preview question locally", "本機預覽問題"))
        }.padding(16).background(.bar)
    }

    private var sourceNote: some View {
        Text(store.t("Official links open in your browser. Confirm eligibility, referral requirements and availability with the service provider.", "官方連結會喺瀏覽器開啟。資格、轉介要求同名額請向服務機構確認。"))
            .font(.caption).foregroundStyle(.secondary)
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
        case .registered: return [l.text("Keep your referring professional’s contact details", "保留轉介專業人士的聯絡資料"), l.text("Ask about support while waiting", "了解輪候期間的支援"), l.text("Continue recording everyday observations", "繼續記錄日常觀察")]
        }
    }
}
