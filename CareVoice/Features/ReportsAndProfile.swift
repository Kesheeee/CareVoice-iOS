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
                Card { Text(report).font(.subheadline).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                PrimaryButton(title: store.t("Share or download report", "分享或下載報告"), symbol: "square.and.arrow.up") {
                    do {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareVoice-report-\(UUID().uuidString).txt")
                        try Data(report.utf8).write(to: url, options: [.atomic, .completeFileProtection])
                        lastURL = url; export = ExportFile(url: url)
                    } catch { store.errorMessage = store.t("The report could not be created. Please try again.", "未能建立報告，請再試。") }
                }.accessibilityIdentifier("shareReport")
                Button {
                    do { let url = try PDFReport.make(text: report); lastURL = url; export = ExportFile(url: url) }
                    catch { store.errorMessage = store.t("The report could not be created. Please try again.", "未能建立報告，請再試。") }
                } label: { Label(store.t("Print / save PDF", "列印／儲存 PDF"), systemImage: "doc.text").frame(maxWidth: .infinity, minHeight: 56) }.buttonStyle(.bordered).accessibilityIdentifier("sharePDF")
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
            Section(store.t("Your care tools", "你的照顧工具")) {
                NavigationLink(store.t("Observation questionnaire", "情況問卷")) { QuestionnaireView() }
                NavigationLink(store.t("Reports", "報告")) { ReportsView() }
            }
        }
        .navigationTitle(store.t("Profile", "我的檔案"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(store.t("Settings", "設定"))
                .accessibilityIdentifier("openSettings")
            }
        }
        .sheet(isPresented: $editing) { NavigationStack { ProfileEditor() } }
    }
}
