import SwiftUI

// MARK: - Service types

struct ServiceTypesView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.t("What the letters mean", "這些代號是甚麼")).font(.system(.title, design: .rounded).bold())
                Text(store.t("Government-funded pre-school rehabilitation services, in plain words.", "政府資助的學前康復服務，用淺白的話解釋。")).foregroundStyle(.secondary)
                ForEach(store.content.serviceTypes) { type in
                    Card {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(localized(type.aliasEn, type.aliasTc, store.language)).font(.title3.bold()).foregroundStyle(Brand.blue)
                            Text(localized(type.nameEn, type.nameTc, store.language)).font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        if let target = type.targetTc { row(store.t("Who it's for", "服務對象"), localized(type.targetEn, target, store.language)) }
                        if let intensity = type.intensityTc { row(store.t("What it is", "服務形式"), localized(type.intensityEn, intensity, store.language)) }
                        if let referral = type.referralTc { row(store.t("How to get it", "轉介方式"), localized(type.referralEn, referral, store.language)) }
                        if let fee = type.feeTc { row(store.t("Fee", "費用"), localized(type.feeEn, fee, store.language)) }
                        if let wait = type.waitNoteTc { row(store.t("Typical wait", "輪候情況"), localized(type.waitNoteEn, wait, store.language)) }
                    }
                }
                sourceNote()
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Service types", "服務種類")).navigationBarTitleDisplayMode(.inline)
    }
    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Brand.teal)
            Text(value).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }
    private func sourceNote() -> some View {
        Text(store.t("Compiled from official Social Welfare Department and Department of Health pages. Details are confirmed by the service provider.", "資料整理自社會福利署及衞生署官方網頁，詳情以服務機構確認為準。"))
            .font(.caption).foregroundStyle(.secondary)
    }
}

// MARK: - Glossary

struct GlossaryView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""

    private var filtered: [GlossaryTerm] {
        guard !search.isEmpty else { return store.content.glossary }
        return store.content.glossary.filter { t in
            t.term.localizedCaseInsensitiveContains(search)
            || (t.termEn ?? "").localizedCaseInsensitiveContains(search)
            || t.fullTc.localizedCaseInsensitiveContains(search)
            || (t.fullEn ?? "").localizedCaseInsensitiveContains(search)
            || t.plainTc.localizedCaseInsensitiveContains(search)
            || (t.plainEn ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("Jargon, decoded", "行話對照")).font(.system(.title, design: .rounded).bold())
                if filtered.isEmpty {
                    ContentUnavailableView(store.t("No matching terms", "沒有符合的詞語"), systemImage: "magnifyingglass")
                }
                ForEach(filtered) { term in
                    Card {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(localized(term.termEn, term.term, store.language)).font(.headline).foregroundStyle(Brand.blue)
                            Text(localized(term.fullEn, term.fullTc, store.language)).font(.subheadline.weight(.semibold))
                        }
                        Text(localized(term.plainEn, term.plainTc, store.language)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Glossary", "術語對照")).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: store.t("Search terms", "搜尋詞語"))
    }
}

// MARK: - Service directory

struct ServiceDirectoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var district = "all"
    @State private var serviceCode = "all"

    private var filtered: [ServiceUnit] {
        var units = store.content.serviceUnits
        if district != "all" { units = units.filter { $0.district == district } }
        if serviceCode != "all" { units = units.filter { $0.serviceCode == serviceCode } }
        if !search.isEmpty {
            units = units.filter { $0.nameTc.localizedCaseInsensitiveContains(search) || ($0.nameEn ?? "").localizedCaseInsensitiveContains(search) }
        }
        return units.sorted { ($0.district ?? "") < ($1.district ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Menu {
                        Picker(store.t("District", "地區"), selection: $district) {
                            Text(store.t("All districts", "所有地區")).tag("all")
                            ForEach(store.content.districts, id: \.self) { d in
                                Text(districtName(d)).tag(d)
                            }
                        }
                    } label: {
                        Label(district == "all" ? store.t("District", "地區") : districtName(district), systemImage: "mappin.and.ellipse")
                    }
                    Menu {
                        Picker(store.t("Service", "服務"), selection: $serviceCode) {
                            Text(store.t("All services", "所有服務")).tag("all")
                            ForEach(store.content.serviceCodes, id: \.self) { c in
                                Text(serviceLabel(c)).tag(c)
                            }
                        }
                    } label: {
                        Label(serviceCode == "all" ? store.t("Service", "服務") : serviceLabel(serviceCode), systemImage: "building.2")
                    }
                    Spacer()
                }.font(.subheadline)
                ForEach(filtered) { unit in
                    Card {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localized(unit.nameEn, unit.nameTc, store.language)).font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            if let code = unit.serviceCode {
                                Text(serviceLabel(code))
                                    .font(.caption.bold()).foregroundStyle(Brand.teal)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Brand.teal.opacity(0.12), in: Capsule())
                            }
                        }
                        if let d = unit.district { Text(localized(unit.districtEn, d, store.language)).font(.caption).foregroundStyle(.secondary) }
                        if let address = unit.address, !address.isEmpty { Text(address).font(.subheadline) }
                        HStack(spacing: 16) {
                            if let phone = unit.phone, !phone.isEmpty {
                                Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                    Label(phone, systemImage: "phone").font(.subheadline).foregroundStyle(Brand.blue)
                                }
                            }
                            if let wait = store.content.waitMonths(for: unit.unitId) {
                                Label(store.t("\(wait) mo wait", "輪候約 \(wait) 個月"), systemImage: "clock").font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView(store.t("No centres match", "沒有符合的中心"), systemImage: "magnifyingglass")
                }
                Text(store.t("Waiting figures are a snapshot (as of 2026-08-31) recalculated from official datasets — not live availability.", "輪候數字為截至 2026-08-31 的快照，由官方數據集逐間復算，並非實時名額。"))
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Find a centre", "服務機構・輪候")).navigationBarTitleDisplayMode(.inline)
    }

    private func serviceLabel(_ code: String) -> String {
        guard let st = store.content.serviceType(code: code) else { return code }
        return localized(st.aliasEn, st.aliasTc, store.language)
    }

    private func districtName(_ d: String) -> String {
        if store.language == .english {
            if let unit = store.content.serviceUnits.first(where: { $0.district == d }), let en = unit.districtEn, !en.isEmpty { return en }
        }
        return d
    }
}

// MARK: - Citable facts

struct CitableFactsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""

    private var topics: [String] {
        Array(Set(store.content.assertions.map { $0.topic })).sorted()
    }

    private var searchResults: [CitableAssertion] {
        guard !search.isEmpty else { return [] }
        return store.content.assertions.filter { a in
            localized(a.plainEn, a.plainTc, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.quoteEn, a.quote, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.titleEn, a.titleTc, store.language).localizedCaseInsensitiveContains(search)
            || localized(a.orgEn, a.org, store.language).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(store.t("Every fact, with its source", "每條資料都有出處")).font(.system(.title, design: .rounded).bold())
                Text(store.t("These are verbatim official statements, each linking back to the original page.", "以下為官方原文逐字摘錄，每條均可點回原始網頁。")).foregroundStyle(.secondary)
                if store.language == .english {
                    Text(store.t("English text is a translation, not an official quote.", "英文內容為翻譯，並非官方原文。"))
                        .font(.caption).foregroundStyle(.orange)
                }
                if search.isEmpty {
                    ForEach(topics, id: \.self) { topic in
                        let items = store.content.assertions.filter { $0.topic == topic }
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(items) { a in assertionCard(a) }
                            }.padding(.top, 6)
                        } label: {
                            HStack {
                                Text(topicLabel(topic, store.language)).font(.headline)
                                Spacer()
                                Text("\(items.count)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    if searchResults.isEmpty {
                        ContentUnavailableView(store.t("No matching information", "沒有符合的資料"), systemImage: "magnifyingglass")
                    }
                    ForEach(searchResults) { a in assertionCard(a, showTopic: true) }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Cited information", "可引用資料")).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: store.t("Search cited information", "搜尋可引用資料"))
    }

    private func assertionCard(_ a: CitableAssertion, showTopic: Bool = false) -> some View {
        Card {
            if showTopic {
                Text(topicLabel(a.topic, store.language)).font(.caption.bold()).foregroundStyle(Brand.teal)
            }
            Text(localized(a.plainEn, a.plainTc, store.language)).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Divider()
            Text("「\(localized(a.quoteEn, a.quote, store.language))」").font(.footnote).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(localized(a.orgEn, a.org, store.language)).font(.caption.bold()).foregroundStyle(Brand.teal)
                Text(localized(a.titleEn, a.titleTc, store.language)).font(.caption).foregroundStyle(.secondary)
                Spacer()
                if !a.url.isEmpty {
                    Link(store.t("Source", "來源"), destination: URL(string: a.url)!).font(.caption).foregroundStyle(Brand.blue)
                }
            }
        }
    }
}

private func topicLabel(_ topic: String, _ l: AppLanguage) -> String {
    switch topic {
    case "waiting": return l.text("Waiting times", "輪候時間")
    case "waiting_support": return l.text("Support while waiting", "輪候期間支援")
    case "subsidy": return l.text("Subsidy", "津貼")
    case "eligibility": return l.text("Eligibility", "資格")
    case "service": return l.text("Services", "服務")
    case "cost": return l.text("Cost", "費用")
    case "transition": return l.text("Transition support", "過渡支援")
    case "referral_route": return l.text("Referral", "轉介")
    case "materials": return l.text("Documents", "所需材料")
    case "right": return l.text("Rights", "權益")
    case "redflag": return l.text("Red flags", "紅旗")
    default: return topic
    }
}
