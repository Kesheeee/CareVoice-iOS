import SwiftUI

// Same safety routing as mobile/src/components/SafetyRouting.tsx; never a clinical score.
struct SafetyGuidance: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Card {
            Label(store.t("Get medical help", "尋求醫療協助"), systemImage: "cross.case").font(.headline)
            Text(store.t("You answered Yes or Not sure about seizures or self-injury. If your child is in immediate danger, is seriously injured, or is having a seizure now, stop the questionnaire and seek emergency medical help. In Hong Kong, call 999 or go to A&E.", "你在抽搐或傷害自己的題目選了有或不確定。如孩子有即時危險、嚴重受傷或正在抽搐，請停止填問卷並立即尋求緊急醫療協助。在香港，請致電 999 或去急症室。"))
            Link(store.t("Call 999 · Hong Kong emergency", "致電 999 · 香港緊急求助"), destination: URL(string: "tel:999")!)
            Text(store.t("If there is no immediate danger, contact your child’s doctor promptly to discuss what you noticed. You can leave the questionnaire and return later. Outside Hong Kong, use your local emergency number.", "如無即時危險，請盡快聯絡孩子的醫生討論觀察。可先離開問卷，稍後再繼續。香港以外請致電當地緊急求助電話。"))
            Link(store.t("Hospital Authority · A&E departments", "醫院管理局 · 急症室"), destination: URL(string: "https://www.ha.org.hk/visitor/ha_visitor_index.asp?Content_ID=200246&Lang=ENG&Parent_ID=0")!)
        }.font(.subheadline).accessibilityIdentifier("safetyGuidance")
    }
}
