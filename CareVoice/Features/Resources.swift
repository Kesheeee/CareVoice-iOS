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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(store.t("Official resources & support", "官方資源與支援")).font(.subheadline.weight(.semibold)).foregroundStyle(Color.secondary)
                VStack(spacing: 0) {
                    resource("Child Assessment Service (CAS)", "兒童體能智力測驗服務（CAS）", "stethoscope", "https://www.dhcas.gov.hk/en/faq.html", chinese: "https://www.dhcas.gov.hk/tc/faq.html")
                    Divider()
                    resource("Assessment registration & appointments", "評估登記及預約", "calendar", "https://www.dhcas.gov.hk/en/registration_appointment.html", chinese: "https://www.dhcas.gov.hk/tc/registration_appointment.html")
                    Divider()
                    resource("Follow-up & service referrals", "跟進與服務轉介", "arrow.triangle.branch", "https://www.dhcas.gov.hk/en/management_referral.html", chinese: "https://www.dhcas.gov.hk/tc/management_referral.html")
                    Divider()
                    resource("Central referral system (CRSRS)", "康復服務中央轉介系統", "building.2", "https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/centralref/", chinese: "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_crsrehab/centralref/", health: false)
                }.background(.white, in: RoundedRectangle(cornerRadius: 22))
                Text(store.t("Support for parents", "家長資源")).font(.subheadline.weight(.semibold)).foregroundStyle(Color.secondary)
                VStack(spacing: 0) {
                    resource("Maternal & Child Health Centres", "母嬰健康院", "figure.and.child.holdinghands", "https://www.dh.gov.hk/english/main/main_fhs/main_fhs.html")
                    Divider()
                    resource("On-site pre-school support", "到校學前支援", "building.2", "https://www.swd.gov.hk/oprs/index_en.htm", health: false)
                }.background(.white, in: RoundedRectangle(cornerRadius: 22))
                Text(store.t("Common questions", "常見問題")).font(.subheadline.weight(.semibold)).foregroundStyle(Color.secondary)
                VStack(spacing: 20) {
                    DisclosureGroup(store.t("Where can I discuss my concerns?", "有疑問可以搵邊個？")) {
                        Text(store.t("Start with your family doctor or Maternal & Child Health Centre. They can discuss your observations and whether a referral is needed.", "可以先同家庭醫生或母嬰健康院傾吓你的觀察，以及是否需要轉介。")).padding(.top, 12)
                    }
                    DisclosureGroup(store.t("Does this questionnaire assess my child?", "這份問卷會評估小朋友嗎？")) {
                        Text(store.t("No. It records your observations without scores, diagnosis or a suggested clinical level. Only you choose your journey stage.", "不會。問卷只記錄觀察，不會評分、診斷或建議臨床程度。只有你能選擇目前階段。")).padding(.top, 12)
                    }
                    DisclosureGroup(store.t("What can I prepare while waiting?", "等候期間可以準備甚麼？")) {
                        Text(store.t("Keep your observations and questions together. Use your personal checklist and bring a report to your next professional appointment. Confirm service arrangements with your referring professional.", "整理日常觀察和問題，使用個人清單，會面時帶同記錄報告。請向轉介專業人士確認服務安排。")).padding(.top, 12)
                    }
                }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
                DisclosureGroup(store.t("About these resources", "關於這些資源")) {
                    Text(store.t("Sources: Department of Health and Social Welfare Department. Service providers confirm eligibility and arrangements. External links open in your browser.", "資料來源：衛生署及社會福利署。服務資格及安排由機構確認，外部連結會在瀏覽器開啟。")).font(.caption).padding(.top, 12)
                }
            }.padding(20)
        }.background(Brand.background).navigationTitle(store.t("Community", "社區"))
    }
    private func resource(_ en: String, _ zh: String, _ icon: String, _ url: String, chinese: String? = nil, health: Bool = true) -> some View {
        Link(destination: URL(string: store.language == .english ? url : (chinese ?? url))!) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title3).foregroundStyle(Brand.blue).frame(width: 26)
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.t(en, zh)).font(.subheadline.weight(.semibold)).foregroundStyle(Color.primary)
                    Text(health ? store.t("Department of Health", "衛生署") : store.t("Social Welfare Department", "社會福利署")).font(.caption).foregroundStyle(Color.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Brand.blue)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
        }
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
                    Image(systemName: "arrow.up.right").foregroundStyle(Color.secondary)
                }
                Text(store.t(resource.titleEN, resource.titleZH)).font(.headline).foregroundStyle(.primary)
                Text(store.t(resource.detailEN, resource.detailZH)).font(.subheadline).foregroundStyle(Color.secondary)
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
                        Text(profile.stage.nextStep(store.language)).foregroundStyle(Color.secondary)
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
                        .font(.caption).foregroundStyle(Color.secondary)
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
        case .receivingServices: return [l.text("Keep your service contact details", "記低服務單位嘅聯絡資料"), l.text("Record questions for your service team", "記低想問服務團隊嘅問題"), l.text("Keep recording everyday observations", "繼續記錄日常觀察")]
        case .registered, .waitingSupport: return [l.text("Keep your referring professional’s contact details", "保留轉介專業人士的聯絡資料"), l.text("Ask about support while waiting", "了解輪候期間的支援"), l.text("Continue recording everyday observations", "繼續記錄日常觀察")]
        }
    }
}
