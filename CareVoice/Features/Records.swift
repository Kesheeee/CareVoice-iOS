import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var category: RecordCategory?
    @State private var adding = false
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
            .navigationTitle(store.t("Your moments", "日常記錄"))
            .searchable(text: $search, prompt: store.t("Search observations", "搜尋記錄"))
            .toolbar { Button { adding = true } label: { Label(store.t("New record", "新增記錄"), systemImage: "plus") }.accessibilityIdentifier("addRecord") }
            .sheet(isPresented: $adding) { NavigationStack { RecordEditor() } }
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
        }
    }
}

struct RecordDetail: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @State private var editing = false
    @State private var deleting = false
    var body: some View {
        Group {
            if let record = store.data.records.first(where: { $0.id == recordID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Card {
                            Label(record.category.title(store.language), systemImage: record.category.symbol).foregroundStyle(Brand.blue).font(.headline)
                            Text(record.date, format: .dateTime.year().month().day().hour().minute()).font(.subheadline).foregroundStyle(.secondary)
                            Text(record.text).textSelection(.enabled)
                            if !record.location.isEmpty { Label(record.location, systemImage: "mappin") }
                            if let n = record.durationMinutes { Label(store.t("\(n) minutes", "\(n) 分鐘"), systemImage: "clock") }
                        }
                        if !record.context.isEmpty { Card { SectionHeading(title: store.t("What happened before", "之前發生了甚麼")); Text(record.context) } }
                        if !record.helped.isEmpty { Card { SectionHeading(title: store.t("What helped", "有幫助的方法")); Text(record.helped) } }
                        let related = store.data.related(to: record)
                        if !related.isEmpty {
                            SectionHeading(title: store.t("Earlier moments in this category", "同類別的過往記錄"))
                            Text(store.t("Grouped by your chosen category, not an inferred connection.", "按你選擇的類別分組，並非推斷因果關係。"))
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(related) { earlier in RecordCard(record: earlier) }
                        }
                        Button(store.t("Delete record", "刪除記錄"), role: .destructive) { deleting = true }
                    }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
                }.background(Brand.background)
                    .toolbar { Button(store.t("Edit", "編輯")) { editing = true } }
                    .sheet(isPresented: $editing) { NavigationStack { RecordEditor(existing: record) } }
            }
        }
        .navigationTitle(store.t("Moment details", "記錄詳情")).navigationBarTitleDisplayMode(.inline)
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
    @State private var record = BehaviorRecord(text: "")
    @StateObject private var speech = SpeechRecorder()
    @State private var beforeSpeech = ""
    @State private var duration = ""
    @State private var confirmDiscard = false
    private var valid: Bool {
        !record.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (duration.isEmpty || (Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false))
    }
    var body: some View {
        Form {
            Section {
                TextField(store.t("What did you notice?", "你留意到甚麼？"), text: $record.text, axis: .vertical).lineLimit(5...12).accessibilityIdentifier("recordText")
                Button {
                    if speech.isRecording { speech.stop() }
                    else {
                        beforeSpeech = record.text
                        Task { await speech.start(language: store.language) }
                    }
                } label: {
                    Label(speech.isRecording ? store.t("Stop · \(speech.seconds)s", "停止・\(speech.seconds)秒") : store.t("Use voice · up to 60 seconds", "語音輸入・最多 60 秒"), systemImage: speech.isRecording ? "stop.circle.fill" : "mic.fill")
                        .foregroundStyle(speech.isRecording ? .red : Brand.blue)
                }.disabled(speech.isStarting)
                if let message = speech.error { Text(message).font(.caption).foregroundStyle(.secondary) }
            } header: { Text(store.t("A moment worth remembering", "值得記下的片段")) }
            footer: { Text(store.t("Voice transcription runs on supported devices using Apple’s on-device speech recognition. Review the text before saving. Audio is not saved.", "語音轉文字使用 Apple 裝置端辨識，需裝置支援。儲存前請檢查文字，錄音不會被保留。")) }
            Section(store.t("Details", "詳情")) {
                Picker(store.t("Category", "類別"), selection: $record.category) { ForEach(RecordCategory.allCases) { c in Text(c.title(store.language)).tag(c) } }
                DatePicker(store.t("When", "時間"), selection: $record.date, in: ...Date())
                TextField(store.t("Place (optional)", "地點（選填）"), text: $record.location)
                TextField(store.t("Duration in minutes (optional)", "持續分鐘（選填）"), text: $duration).keyboardType(.numberPad)
                if !duration.isEmpty && !(Int(duration).map { $0 >= 0 && $0 <= 1440 } ?? false) {
                    Text(store.t("Enter a whole number from 0 to 1440.", "請輸入 0 至 1440 的整數。" )).foregroundStyle(.red).font(.caption)
                }
            }
            Section(store.t("A little more context (optional)", "補充情況（選填）")) {
                TextField(store.t("What happened before?", "之前發生了甚麼？"), text: $record.context, axis: .vertical).lineLimit(2...5)
                TextField(store.t("What helped?", "甚麼方法有幫助？"), text: $record.helped, axis: .vertical).lineLimit(2...5)
            }
        }
        .navigationTitle(store.t(existing == nil ? "Capture a moment" : "Edit moment", existing == nil ? "記下這一刻" : "編輯記錄"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(store.t("Cancel", "取消")) { speech.stop(); confirmDiscard = true } }
            ToolbarItem(placement: .confirmationAction) {
                Button(store.t("Save", "儲存")) {
                    speech.stop()
                    record.text = record.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    record.durationMinutes = Int(duration)
                    if store.saveRecord(record) { dismiss() }
                }.bold().disabled(!valid || speech.isRecording || speech.isStarting).accessibilityIdentifier("saveRecord")
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(store.t("Discard this draft?", "放棄此草稿？"), isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button(store.t("Discard", "放棄"), role: .destructive) { dismiss() }
            Button(store.t("Keep editing", "繼續編輯"), role: .cancel) { }
        }
        .onAppear { if let existing { record = existing; duration = existing.durationMinutes.map(String.init) ?? "" } }
        .onChange(of: speech.transcript) { _, value in record.text = beforeSpeech + (beforeSpeech.isEmpty ? "" : "\n") + value }
        .onChange(of: scenePhase) { _, phase in if phase != .active { speech.stop() } }
        .onDisappear { speech.stop() }
    }
}
