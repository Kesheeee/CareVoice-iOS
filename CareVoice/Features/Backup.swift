import SwiftUI
import UniformTypeIdentifiers

struct NativeBackupControls: View {
    @EnvironmentObject var store: AppStore
    @State private var export: ExportFile?
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var pending: AppData?
    @State private var confirming = false
    var body: some View {
        Section(store.t("Data", "資料管理")) {
            Button(store.t("Download a backup", "下載備份")) {
                do {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-backup-\(UUID().uuidString).json")
                    try BackupCodec.encode(store.data).write(to: url, options: [.atomic, .completeFileProtection])
                    exportURL = url; export = ExportFile(url: url)
                } catch { store.errorMessage = error.localizedDescription }
            }
            Button(store.t("Restore a backup", "還原備份")) { importing = true }
        }
        .sheet(item: $export, onDismiss: { if let exportURL { try? FileManager.default.removeItem(at: exportURL) }; exportURL = nil }) { file in ShareSheet(url: file.url) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get(); let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url)
                guard bytes.count < 20_000_000 else { throw CocoaError(.fileReadTooLarge) }
                let data = try BackupCodec.decode(bytes)
                guard data.version == 1, data.profile.map({ (0...83).contains($0.ageMonths) }) ?? true,
                      Set(data.records.map(\.id)).count == data.records.count else { throw CocoaError(.coderReadCorrupt) }
                pending = data; confirming = true
            } catch { store.errorMessage = store.t("This native backup could not be restored. Your current data is unchanged.", "未能還原備份，現有資料保持不變。") }
        }
        .alert(store.t("Replace local data?", "取代本機資料？"), isPresented: $confirming) {
            Button(store.t("Cancel", "取消"), role: .cancel) { pending = nil }
            Button(store.t("Restore", "還原"), role: .destructive) { if let data = pending { store.update { $0 = data } }; pending = nil }
        } message: { Text(store.t("This replaces your profile, records and answers with the selected backup.", "呢個操作會以備份取代檔案、記錄同問卷答案。")) }
    }
}


