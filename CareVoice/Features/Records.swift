import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var category: RecordCategory?
    @State private var adding = false
    @State private var savedRecordID: UUID?
    private var filtered: [BehaviorRecord] {
        store.data.records.filter { r in
            (category == nil || r.category == category) && (search.isEmpty || r.text.localizedCaseInsensitiveContains(search) || r.location.localizedCaseInsensitiveContains(search))
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.t("The everyday moments tell a story.", "日常的點滴，訴說成長的故事。"))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterButton(store.t("All", "全部"), value: nil)
                        ForEach(RecordCategory.allCases) { c in filterButton(c.title(store.language), value: c) }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView(store.t(search.isEmpty ? "A fresh page" : "No matching moments", search.isEmpty ? "從第一則記錄開始" : "找不到相關記錄"), systemImage: "text.book.closed", description: Text(store.t("Tap + to capture an observation, a challenge or a little win.", "點按 + 記下觀察、困難或小小進步。")))
                }
                ForEach(filtered) { r in
                    NavigationLink { RecordDetail(recordID: r.id) } label: { RecordCard(record: r) }.buttonStyle(.plain)
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background)
            .navigationTitle(store.t("Records", "記錄"))
            .toolbar { NavigationLink { ReportsView() } label: { Label(store.t("Reports", "報告"), systemImage: "doc.text").labelStyle(.titleAndIcon) } }
            .searchable(text: $search, prompt: store.t("Search observations", "搜尋記錄"))
            .overlay(alignment: .bottomTrailing) {
                Button { adding = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).frame(width: 56, height: 56).background(Brand.blue, in: Circle()).shadow(color: .black.opacity(0.15), radius: 8, y: 4) }.padding(20).accessibilityLabel(store.t("New record", "新增記錄")).accessibilityIdentifier("addRecord")
            }
            .sheet(isPresented: $adding) { NavigationStack { RecordEditor(onSaved: { savedRecordID = $0.id }) } }
            .navigationDestination(item: $savedRecordID) { id in RecordDetail(recordID: id) }
    }
    private func filterButton(_ title: String, value: RecordCategory?) -> some View {
        Button { category = value } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 10)
                .background(category == value ? Brand.blue : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(category == value ? Color.white : .primary)
        }.buttonStyle(.plain).accessibilityAddTraits(category == value ? .isSelected : [])
    }
}

struct RecordCard: View {
    @EnvironmentObject var store: AppStore
    let record: BehaviorRecord
    var body: some View {
        Card {
            HStack {
                Label(record.category.title(store.language), systemImage: record.category.symbol).font(.caption.weight(.semibold)).foregroundStyle(record.category == .progress ? Brand.teal : Brand.blue)
                Spacer()
                Text(record.date, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary)
            }
            Text(record.text).font(.body).lineLimit(4).foregroundStyle(.primary)
            if !record.location.isEmpty { Label(record.location, systemImage: "mappin").font(.caption).foregroundStyle(.secondary) }
            Label(store.t("View details", "查看詳情"), systemImage: "chevron.right").font(.caption).foregroundStyle(Brand.blue)
        }
    }
}

struct RecordDetail: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @State private var editing = false
    @State private var expandDetails = false
    @State private var deleting = false
    var body: some View {
        Group {
            if let record = store.data.records.first(where: { $0.id == recordID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Card {
                            Label(record.category.title(store.language), systemImage: record.category.symbol).foregroundStyle(Brand.blue).font(.headline)
                            Text(record.date, format: .dateTime.year().month().day().hour().minute()).font(.subheadline).foregroundStyle(.secondary)
                            Text(store.t("What happened", "發生了甚麼")).font(.headline)
                            Text(record.text).textSelection(.enabled)
                            if !record.location.isEmpty { Label(record.location, systemImage: "mappin") }
                            if let n = record.durationMinutes { Label(store.t("\(n) minutes", "\(n) 分鐘"), systemImage: "clock") }
                        }
                        if !record.context.isEmpty { Card { SectionHeading(title: store.t("What happened before", "之前發生了甚麼")); Text(record.context) } }
                        if !record.helped.isEmpty { Card { SectionHeading(title: store.t("What helped", "有幫助的方法")); Text(record.helped) } }
                        if record.context.isEmpty || record.helped.isEmpty {
                            Card {
                                Text(store.t("Remember a little more?", "還記得更多細節嗎？")).font(.headline)
                                Text(store.t("Add what happened before or what helped, while it’s still fresh.", "趁記憶還清晰，補充之前發生的事或有幫助的方法。")).font(.subheadline).foregroundStyle(.secondary)
                                Button { expandDetails = true; editing = true } label: { Label(store.t("Add details", "補充詳情"), systemImage: "pencil").frame(minHeight: 44) }
                            }
                        }
                        let related = store.data.related(to: record)
                        if !related.isEmpty {
                            SectionHeading(title: store.t("Earlier records in this category", "同類別的過往記錄"))
                            Text(store.t("Grouped by the category you chose.", "按你選擇的類別分組。"))
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(related) { earlier in NavigationLink { RecordDetail(recordID: earlier.id) } label: { RecordCard(record: earlier) }.buttonStyle(.plain) }
                        }
                        NavigationLink { ReportsView() } label: { Label(store.t("Prepare a report", "準備報告"), systemImage: "doc.text").frame(maxWidth: .infinity, minHeight: 52) }.buttonStyle(.bordered)
                        Button(store.t("Delete record", "刪除記錄"), role: .destructive) { deleting = true }
                    }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
                }.background(Brand.background)
                    .toolbar { Button(store.t("Edit", "編輯")) { expandDetails = false; editing = true } }
                    .sheet(isPresented: $editing) { NavigationStack { RecordEditor(existing: record, expandDetails: expandDetails) } }
            }
        }
        .navigationTitle(store.t("Record details", "記錄詳情")).navigationBarTitleDisplayMode(.inline)
        .alert(store.t("Delete this record?", "刪除此記錄？"), isPresented: $deleting) {
            Button(store.t("Cancel", "取消"), role: .cancel) { }
            Button(store.t("Delete", "刪除"), role: .destructive) { store.deleteRecord(recordID); if !store.data.records.contains(where: { $0.id == recordID }) { dismiss() } }
        } message: { Text(store.t("This cannot be undone.", "此操作無法復原。")) }
    }
}

struct RecordEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var existing: BehaviorRecord?
    var expandDetails = false
    var onSaved: (BehaviorRecord) -> Void = { _ in }
    @State private var record = BehaviorRecord(text: "")
    @StateObject private var speech = SpeechRecorder()
    @State private var beforeSpeech = ""
    @State private var duration = ""
    @State private var confirmDiscard = false
    @State private var voice = true
    @State private var moreDetails = false
    private var valid: Bool {
        !record.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (duration.isEmpty || (Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Picker(store.t("Record type", "記錄方式"), selection: $voice) {
                    Label(store.t("Voice record", "語音記錄"), systemImage: "mic").tag(true)
                    Label(store.t("Text record", "文字記錄"), systemImage: "pencil").tag(false)
                }.pickerStyle(.segmented).onChange(of: voice) { _, _ in speech.stop() }
                if voice {
                    VStack(spacing: 18) {
                        Image(systemName: speech.isRecording ? "waveform" : "mic.fill").font(.system(size: 36)).foregroundStyle(Brand.blue)
                            .frame(width: 88, height: 88).background(Color.pink.opacity(0.1), in: Circle())
                        Text(speech.isRecording ? store.t("Recording · \(speech.seconds) / 60 seconds", "錄音中 · \(speech.seconds) / 60 秒") : store.t("Tap to start recording (up to 60 seconds)", "點按開始錄音（最多 60 秒）")).font(.subheadline).foregroundStyle(.secondary)
                        Button {
                            if speech.isRecording { speech.stop() }
                            else { beforeSpeech = record.text; Task { await speech.start(language: store.language) } }
                        } label: { Text(store.t(speech.isRecording ? "Stop recording" : "Start recording", speech.isRecording ? "停止錄音" : "開始錄音")) }
                            .buttonStyle(AccountPrimaryStyle()).disabled(speech.isStarting)
                        if let error = speech.error { Text(error).font(.subheadline).foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity)
                }
                if !voice || !record.text.isEmpty {
                    TextField(store.t("What did you notice?", "你留意到甚麼？"), text: $record.text, axis: .vertical).lineLimit(5...12)
                        .padding(16).background(Brand.background, in: RoundedRectangle(cornerRadius: 18)).accessibilityIdentifier("recordText")
                        .disabled(speech.isRecording || speech.isStarting)
                }
                DisclosureGroup(isExpanded: $moreDetails) {
                    VStack(alignment: .leading, spacing: 18) {
                        Picker(store.t("Category", "類別"), selection: $record.category) { ForEach(RecordCategory.allCases) { c in Text(c.title(store.language)).tag(c) } }.pickerStyle(.menu)
                        VStack(alignment: .leading) { Text(store.t("When", "時間")).font(.subheadline); DatePicker(store.t("When", "時間"), selection: $record.date, in: ...Date()).labelsHidden() }
                        detail(store.t("Place (optional)", "地點（選填）"), text: $record.location)
                        TextField(store.t("Minutes (optional)", "分鐘（選填）"), text: $duration).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        if !duration.isEmpty && !(Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false) { Text(store.t("Enter a whole number from 0 to 1440.", "請輸入 0 至 1440 的整數。")).font(.caption).foregroundStyle(.red) }
                        detail(store.t("What happened before?", "之前發生了甚麼？"), text: $record.context)
                        detail(store.t("What helped?", "甚麼方法有幫助？"), text: $record.helped)
                    }.padding(.top, 18)
                } label: { Text(store.t("More details", "更多詳情")).font(.subheadline.weight(.semibold)) }
                Text(store.t("Review the transcript before saving. Speech is processed on your device; audio is not saved.", "儲存前請檢查文字。語音於裝置端處理，錄音不會保留。")).font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button(store.t("Cancel", "取消")) { speech.stop(); confirmDiscard = true }.frame(maxWidth: .infinity, minHeight: 56).background(Brand.background, in: Capsule())
                    Button(store.t("Save record", "儲存記錄")) {
                        speech.stop(); record.text = record.text.trimmingCharacters(in: .whitespacesAndNewlines); record.durationMinutes = Int(duration)
                        if store.saveRecord(record) { onSaved(record); dismiss() }
                    }.buttonStyle(AccountPrimaryStyle()).disabled(!valid || speech.isRecording || speech.isStarting).accessibilityIdentifier("saveRecord")
                }.padding(20).background(.bar)
            }
            .navigationTitle(store.t(existing == nil ? "Quick Record" : "Edit record", existing == nil ? "快速記錄" : "編輯記錄")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { speech.stop(); confirmDiscard = true } label: { Image(systemName: "xmark") }.accessibilityLabel(store.t("Close", "關閉")) } }
            .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
            .interactiveDismissDisabled()
            .confirmationDialog(store.t("Discard this draft?", "放棄此草稿？"), isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button(store.t("Discard", "放棄"), role: .destructive) { dismiss() }
                Button(store.t("Keep editing", "繼續編輯"), role: .cancel) {}
            }
            .onAppear { moreDetails = expandDetails; if let existing { record = existing; duration = existing.durationMinutes.map(String.init) ?? ""; voice = false } }
            .onChange(of: speech.transcript) { _, value in
                if !value.isEmpty { record.text = beforeSpeech + (beforeSpeech.isEmpty ? "" : "\n") + value }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { speech.stop() } }
            .onDisappear { speech.stop() }
    }
    private func detail(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(title).font(.subheadline); TextField(title, text: text, axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder) }
    }
}
