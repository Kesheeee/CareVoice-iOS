import SwiftUI
import UIKit
import CoreText

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @State private var professional = false
    @State private var export: ExportFile?
    @State private var lastURL: URL?
    private var report: String { ReportBuilder.text(data: store.data, questions: store.questions, professional: professional) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(store.t("Make the conversation easier.", "讓溝通更容易。"))
                    .font(.system(.title, design: .rounded).bold())
                Picker(store.t("Report format", "報告格式"), selection: $professional) {
                    Text(store.t("Family", "家庭版")).tag(false)
                    Text(store.t("Appointment", "會面版")).tag(true)
                }.pickerStyle(.segmented)
                Text(store.t("Review your report before sharing. It contains your child’s observations and will leave this device only through the destination you choose.", "分享前請檢查報告，當中包含孩子的觀察記錄。報告只會透過你選擇的方式分享。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                PrimaryButton(title: store.t("Share PDF report", "分享 PDF 報告"), symbol: "square.and.arrow.up") {
                    do {
                        let url = try PDFReport.make(text: report)
                        lastURL = url; export = ExportFile(url: url)
                    } catch { store.errorMessage = store.t("The report could not be created. Please try again.", "未能建立報告，請再試。") }
                }.accessibilityIdentifier("shareReport")
                Card { Text(report).font(.subheadline).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Reports", "報告")).navigationBarTitleDisplayMode(.inline)
            .sheet(item: $export, onDismiss: cleanup) { item in ShareSheet(url: item.url) }
    }
    private func cleanup() { if let lastURL { try? FileManager.default.removeItem(at: lastURL) }; lastURL = nil }
}

struct ExportFile: Identifiable { let id = UUID(); let url: URL }

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

@MainActor
enum PDFReport {
    static func make(text: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-\(UUID().uuidString).pdf")
        let style = NSMutableParagraphStyle(); style.lineSpacing = 5; style.paragraphSpacing = 8
        let attributed = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black, .paragraphStyle: style])
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let bytes = renderer.pdfData { context in
            var offset = 0
            var page = 1
            while offset < attributed.length {
                context.beginPage()
                let cg = context.cgContext
                cg.saveGState()
                cg.textMatrix = .identity
                cg.translateBy(x: 0, y: bounds.height)
                cg.scaleBy(x: 1, y: -1)
                let path = CGPath(rect: CGRect(x: 42, y: 50, width: 511, height: 750), transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
                CTFrameDraw(frame, cg)
                let visible = CTFrameGetVisibleStringRange(frame)
                cg.restoreGState()
                ("CareVoice · \(page)" as NSString).draw(at: CGPoint(x: 42, y: 812), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
                guard visible.length > 0 else { break }
                offset += visible.length; page += 1
            }
        }
        try bytes.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing = false
    @State private var deleting = false
    var body: some View {
        List {
            if let p = store.data.profile {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 48)).foregroundStyle(Brand.blue)
                        VStack(alignment: .leading, spacing: 5) { Text(p.displayName(store.language)).font(.headline); Text(p.age(store.language)).foregroundStyle(.secondary) }
                    }.padding(.vertical, 10)
                    Button(store.t("Edit profile", "編輯檔案")) { editing = true }
                    LabeledContent(store.t("Current stage", "目前階段")) { Text(p.stage.title(store.language)).multilineTextAlignment(.trailing) }
                }
            }
            Section(store.t("Preferences", "偏好設定")) {
                Picker(store.t("Language", "語言"), selection: Binding(get: { store.language }, set: { store.setLanguage($0) })) {
                    Text("English").tag(AppLanguage.english)
                    Text("繁體中文").tag(AppLanguage.traditionalChinese)
                }.accessibilityIdentifier("languagePicker")
                NavigationLink(store.t("Observation questionnaire", "情況問卷")) { QuestionnaireView() }
                NavigationLink(store.t("Reports", "報告")) { ReportsView() }
            }
            Section(store.t("Your privacy", "你的私隱")) {
                Label(store.t("Stored on this device", "儲存於此裝置"), systemImage: "iphone.and.arrow.forward")
                Text(store.t("No account, analytics, advertising or cloud sync. Records use iOS file protection and are excluded from device backups. Deleting the app or losing the device may lose your records. Share a report when you want to keep a copy.", "無帳戶、分析追蹤、廣告或雲端同步。記錄使用 iOS 檔案保護，並不會包含於裝置備份。刪除應用程式或遺失裝置可能導致記錄遺失，你可分享報告以保留副本。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section(store.t("About CareVoice", "關於 CareVoice")) {
                Text(store.t("A companion for observation and service navigation. This app does not diagnose, screen for ASD, infer severity or replace professional advice.", "協助觀察記錄及服務導航的工具，不提供診斷、自閉症篩查或嚴重程度判斷，亦不能替代專業意見。"))
                    .font(.footnote).foregroundStyle(.secondary)
                LabeledContent(store.t("Version", "版本"), value: "1.0 · MVP")
            }
            Section {
                Button(store.t("Delete all local data", "刪除所有本機資料"), role: .destructive) { deleting = true }
            }
        }.navigationTitle(store.t("Your space", "我的空間"))
            .sheet(isPresented: $editing) { NavigationStack { ProfileEditor() } }
            .alert(store.t("Delete all local data?", "刪除所有本機資料？"), isPresented: $deleting) {
                Button(store.t("Cancel", "取消"), role: .cancel) { }
                Button(store.t("Delete everything", "全部刪除"), role: .destructive) { store.erase() }
            } message: { Text(store.t("Your profile, questionnaire and records will be removed from this app. This cannot be undone. Copies you already shared are not deleted.", "你的檔案、問卷和記錄將從此應用程式移除，無法復原。已分享的副本不會被刪除。")) }
    }
}
