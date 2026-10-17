import SwiftUI

// CareVoice web survey → standalone SwiftUI review, iOS 16+.
// Add this file to an iOS target and open the preview below.
// Usage: CareVoiceSurveyReview { answer in /* persist answer, then route */ }
// onComplete supplies the answers; this preview does not persist personal data.
// Route noticed to the optional questionnaire; other stages to Home.
// Not wired to the existing six-stage ChildProfile model: integrate the two new
// stages and birthday/supportGoals fields before replacing native onboarding.
// Phase 1 pathway reference: content fingerprint 0ae157aa8e0a22c8.

struct CareVoiceSurveyAnswer: Codable {
    var nickname: String
    var birthDate: Date
    var stage: String
    var supportGoals: [String]
    var notes: String
    var ageMonths: Int {
        Calendar.current.dateComponents([.month], from: Calendar.current.startOfDay(for: birthDate), to: Calendar.current.startOfDay(for: Date())).month ?? 0
    }
    var shouldOfferQuestionnaire: Bool { stage == "noticed" }
}

struct CareVoiceSurveyReview: View {
    var chinese = false
    var onClose: () -> Void = {}
    var onComplete: (CareVoiceSurveyAnswer) -> Void
    @State private var step = 0
    @State private var nickname = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
    @State private var birthdayChosen = false
    @State private var stage: String?
    @State private var goals: Set<String> = []
    @State private var notes = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    private let blue = Color(red: 0.082, green: 0.396, blue: 0.753)
    private let pastels: [Color] = [Color(red: 0.89, green: 0.95, blue: 0.99), Color(red: 0.90, green: 0.96, blue: 0.91), Color(red: 1, green: 0.96, blue: 0.88), Color(red: 0.98, green: 0.90, blue: 0.93), Color(red: 0.93, green: 0.90, blue: 0.97)]
    private let stages: [(String, String, String, String)] = [
        ("noticed", "Noticing differences", "留意到不同", "magnifyingglass"),
        ("professionalFollowUp", "Seeking a referral", "尋求專業轉介", "bubble.left"),
        ("awaitingAssessment", "Awaiting assessment", "等候評估", "clock"),
        ("assessed", "Assessment completed", "已完成評估", "doc.text"),
        ("registered", "Registered in the queue", "已登記中央輪候", "checkmark.clipboard"),
        ("waitingSupport", "Support while waiting", "輪候期間支援", "heart"),
        ("receivingServices", "Allocated a service", "已獲編配服務", "person.2")
    ]
    private let options: [(String, String, String, String)] = [
        ("nextSteps", "Understanding next steps", "了解下一步", "safari"),
        ("documents", "Preparing documents", "準備所需文件", "doc.text"),
        ("services", "Finding services", "尋找服務", "person.2"),
        ("waiting", "Support while waiting", "輪候期間嘅支援", "heart"),
        ("observations", "Recording observations", "記錄日常觀察", "magnifyingglass")
    ]
    private func t(_ en: String, _ zh: String) -> String { chinese ? zh : en }
    private var heading: String {
        [t("What should we call your child?", "點稱呼你嘅小朋友？"),
         t("When is your child’s birthday?", "小朋友嘅生日係幾時？"),
         t("Where are you now?", "你而家去到邊個階段？"),
         t("What would you like help with?", "你想獲得邊方面嘅幫助？"),
         t("Anything you’d like us to know?", "仲有冇想話畀我哋知嘅事？")][step]
    }
    private var dateRange: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: Date())
        let sevenYearsAgo = Calendar.current.date(byAdding: .year, value: -7, to: today)!
        return Calendar.current.date(byAdding: .day, value: 1, to: sevenYearsAgo)!...today
    }
    private var canContinue: Bool { step == 1 ? birthdayChosen : (step == 2 ? stage != nil : true) }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Button { if step > 0 { step -= 1 } else { onClose() } } label: {
                        Image(systemName: "arrow.left").frame(width: 44, height: 44)
                    }.accessibilityLabel(t("Back", "返回"))
                    ProgressView(value: Double(step + 1), total: 5).tint(blue)
                        .accessibilityLabel(t("Setup progress", "設定進度"))
                    Text("\(step + 1) / 5").font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 20).padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(heading).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        question(width: geometry.size.width, height: geometry.size.height)
                    }.padding(24)
                }.id(step)
                VStack(spacing: 8) {
                    if step == 0 || step == 4 {
                        Button(t("Skip", "略過")) {
                            if step == 0 { nickname = ""; step += 1 }
                            else { finish(notes: "") }
                        }.frame(minHeight: 44)
                    }
                    Button(step == 4 ? t("See my next steps", "睇吓下一步") : t("Continue", "繼續")) {
                        if step < 4 { step += 1 } else { finish(notes: notes) }
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(blue.opacity(canContinue ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 14))
                    .disabled(!canContinue)
                }.padding(.horizontal, 24).padding(.bottom, 12)
            }.background(Color(uiColor: .systemBackground)).tint(blue)
        }.environment(\.locale, Locale(identifier: chinese ? "zh_Hant_HK" : "en_HK"))
    }

    @ViewBuilder private func question(width: CGFloat, height: CGFloat) -> some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: 12) {
                Text(t("Nickname (optional)", "暱稱（選填）")).font(.subheadline.bold())
                TextField(t("Your child’s nickname", "小朋友嘅暱稱"), text: $nickname)
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.words)
                    .onChange(of: nickname) { nickname = String($0.prefix(40)) }
            }.padding(24).background(pastels[0], in: RoundedRectangle(cornerRadius: 24))
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                Text(t("Choose their date of birth. We’ll work out their age for you.", "揀出生日期，我哋會自動計算年齡。")).foregroundStyle(.secondary)
                DatePicker(t("Birthday", "生日"), selection: $birthday, in: dateRange, displayedComponents: .date)
                    .datePickerStyle(.wheel).labelsHidden()
                    .onChange(of: birthday) { _ in birthdayChosen = true }
                // Explicit confirmation supports accepting the initially displayed date.
                Toggle(t("Use this birthday", "使用呢個生日"), isOn: $birthdayChosen)
                if birthdayChosen {
                    Text(birthday, style: .date).font(.headline)
                }
            }.padding(20).background(pastels[2], in: RoundedRectangle(cornerRadius: 24))
        case 2, 3:
            let items = step == 2 ? stages : options
            let count = typeSize.isAccessibilitySize ? 1 : (width >= 400 ? 3 : 2)
            let rows = Int(ceil(Double(items.count) / Double(count)))
            let cardHeight = max(96, (height - 235 - CGFloat(rows - 1) * 12) / CGFloat(rows))
            VStack(alignment: .leading, spacing: 16) {
                if step == 3 { Text(t("Choose any that apply", "可選多項")).font(.subheadline).foregroundStyle(.secondary) }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: count), spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let selected = step == 2 ? stage == item.0 : goals.contains(item.0)
                        Button {
                            if step == 2 { stage = item.0 }
                            else if goals.contains(item.0) { goals.remove(item.0) }
                            else { goals.insert(item.0) }
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: item.3).font(.title3).foregroundStyle(blue)
                                Text(t(item.1, item.2)).font(.subheadline).foregroundStyle(Color.primary)
                                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            }.padding(.horizontal, 10).padding(.top, 28).padding(.bottom, 12)
                            .frame(maxWidth: .infinity, minHeight: cardHeight)
                            .background(pastels[index % pastels.count], in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? blue : Color.secondary.opacity(0.2), lineWidth: selected ? 2 : 1))
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundStyle(selected ? blue : Color.secondary).padding(10)
                            }
                        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                Text(t("Notes (optional)", "補充資料（選填）")).font(.subheadline.bold())
                TextEditor(text: $notes).frame(minHeight: 160).scrollContentBackground(.hidden)
                    .accessibilityLabel(t("Notes", "補充資料"))
                    .onChange(of: notes) { notes = String($0.prefix(4000)) }
            }.padding(20).background(pastels[4], in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func finish(notes: String) {
        guard let stage, birthdayChosen, dateRange.contains(birthday) else { return }
        onComplete(CareVoiceSurveyAnswer(nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), birthDate: birthday, stage: stage, supportGoals: goals.sorted(), notes: notes))
    }
}

struct CareVoiceSurveyReview_Previews: PreviewProvider {
    static var previews: some View {
        CareVoiceSurveyReview { _ in }.previewDisplayName("English")
        CareVoiceSurveyReview(chinese: true) { _ in }.previewDisplayName("繁體中文")
    }
}
