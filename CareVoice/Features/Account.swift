import SwiftUI
import AVKit

struct WelcomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: AccountMode?
    var body: some View {
        ZStack {
            WelcomeMovie().ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Menu { ForEach(AppLanguage.allCases) { language in Button(language.displayName) { store.setLanguage(language) } } } label: {
                        Image(systemName: "globe").padding(12).background(.thinMaterial, in: Circle())
                    }.accessibilityLabel(store.t("Language", "語言"))
                }
                Spacer()
                Text(store.t("Every little moment.\nA clearer picture.", "每個小日常，\n更清晰嘅了解。"))
                    .font(.largeTitle.bold()).multilineTextAlignment(.center)
                    .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                Button(store.t("Get started", "開始使用")) { mode = .choices }
                    .buttonStyle(AccountPrimaryStyle()).accessibilityIdentifier("getStarted")
                Button(store.t("I already have an account", "我已有帳戶")) { mode = .login }
                    .padding(12).background(.thinMaterial, in: Capsule())
            }.padding(24)
        }
        .sheet(item: $mode) { mode in AccountForm(community: store.community, initialMode: mode) }
    }
}

// A silent, full-bleed loop with the same poster/video files as mobile/src/components/SignInVideo.tsx.
struct WelcomeMovie: UIViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    final class Surface: UIView {
        let poster = UIImageView()
        let playerLayer = AVPlayerLayer()
        var queue: AVQueuePlayer?
        var looper: AVPlayerLooper?
        override func layoutSubviews() { super.layoutSubviews(); poster.frame = bounds; playerLayer.frame = bounds }
        deinit { queue?.pause() }
    }
    func makeUIView(context: Context) -> Surface {
        let view = Surface(); view.clipsToBounds = true
        view.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        if let url = Bundle.main.url(forResource: "carevoice-family-hd", withExtension: "jpg") { view.poster.image = UIImage(contentsOfFile: url.path) }
        else { view.poster.image = UIImage(systemName: "figure.and.child.holdinghands") }
        view.poster.contentMode = .scaleAspectFill; view.addSubview(view.poster)
        if let url = Bundle.main.url(forResource: "carevoice-family-hd", withExtension: "mp4") {
            let queue = AVQueuePlayer(); queue.isMuted = true
            view.queue = queue; view.looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            view.playerLayer.player = queue; view.playerLayer.videoGravity = .resizeAspectFill; view.layer.addSublayer(view.playerLayer)
        }
        return view
    }
    func updateUIView(_ view: Surface, context: Context) {
        view.playerLayer.isHidden = reduceMotion
        if reduceMotion || phase != .active { view.queue?.pause() } else { view.queue?.play() }
    }
    static func dismantleUIView(_ view: Surface, coordinator: ()) { view.queue?.pause(); view.looper = nil; view.queue = nil }
}

enum AccountMode: String, Identifiable { case choices, email, signup, login, recovery, confirmation; var id: String { rawValue } }

struct AccountPrimaryStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 56)
            .background(Brand.blue.opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45), in: Capsule())
    }
}

struct AccountForm: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var community: CommunityStore
    var initialMode: AccountMode = .login
    @State private var mode = AccountMode.login
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var showPassword = false
    @State private var notice: String?
    private var validEmail: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
    private var heading: String {
        switch mode {
        case .choices: return store.t("Let’s get started", "開始使用")
        case .email: return store.t("Enter your email", "輸入電郵")
        case .signup: return store.t("Create your account", "建立帳戶")
        case .login: return store.t("Welcome back", "歡迎返嚟")
        case .recovery: return store.t("Reset your password", "重設密碼")
        case .confirmation: return store.t("Check your email", "查看電郵")
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button { if mode == .signup { move(.email) } else { dismiss() } } label: { Label(store.t("Back", "返回"), systemImage: "arrow.left") }.frame(minHeight: 44)
                Text(heading).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                if mode == .choices {
                    Text(store.t("Your observations, memories and next steps, in one place.", "觀察、回憶及下一步，都在這裡。")).foregroundStyle(.secondary)
                    provider("Google", symbol: "g.circle")
                    provider("Apple", symbol: "apple.logo")
                    Button(store.t("Continue with email", "使用電郵繼續")) { move(.email) }.buttonStyle(AccountPrimaryStyle())
                } else if mode == .confirmation {
                    Text(store.t("If this address can receive an account email, check your inbox and confirm it. Then return here to sign in. No access is granted until your account is confirmed.", "如可向此地址寄送帳戶電郵，請檢查收件箱並確認，然後返回登入。確認前不會開放帳戶。"))
                    Button(store.t("Back to sign in", "返回登入")) { move(.login) }.buttonStyle(AccountPrimaryStyle())
                } else {
                    field(store.t("Email", "電郵"), symbol: "envelope") {
                        TextField("you@example.com", text: $email).keyboardType(.emailAddress).textContentType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("authEmail")
                    }
                    if mode == .signup || mode == .login {
                        field(store.t("Password", "密碼"), symbol: "lock") {
                            Group {
                                if showPassword { TextField(store.t("Your password", "密碼"), text: $password) }
                                else { SecureField(store.t("Your password", "密碼"), text: $password) }
                            }.textContentType(mode == .signup ? .newPassword : .password).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("authPassword")
                            Button { showPassword.toggle() } label: { Image(systemName: showPassword ? "eye.slash" : "eye") }.accessibilityLabel(store.t(showPassword ? "Hide password" : "Show password", showPassword ? "隱藏密碼" : "顯示密碼"))
                        }
                    }
                    if mode == .signup {
                        PasswordChecklist(password: password)
                        field(store.t("Confirm password", "確認密碼"), symbol: "lock") {
                            SecureField(store.t("Confirm password", "確認密碼"), text: $confirm).textContentType(.newPassword).accessibilityIdentifier("authConfirm")
                        }
                    }
                    if mode == .login {
                        Button(store.t("Forgot password?", "忘記密碼？")) { move(.recovery) }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if let error = community.error { Text(error.message(store.language)).font(.subheadline).padding(16).background(Brand.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16)).accessibilityIdentifier("authError") }
                    Button(community.busy ? store.t("Please wait…", "請稍候…") : primaryTitle) { submit() }
                        .buttonStyle(AccountPrimaryStyle()).disabled(community.busy || !validEmail)
                        .accessibilityIdentifier("authSubmit")
                }
                if let notice { Text(notice).font(.subheadline).foregroundStyle(.secondary) }
                if mode == .signup || mode == .email || mode == .choices {
                    Button(store.t("I already have an account", "我已有帳戶")) { move(.login) }.frame(maxWidth: .infinity, minHeight: 44)
                } else if mode == .login {
                    Button(store.t("Create an account", "建立帳戶")) { move(.signup) }.frame(maxWidth: .infinity, minHeight: 44)
                }
            }.padding(24).disabled(community.busy)
        }.interactiveDismissDisabled(community.busy).background(Brand.background).presentationDetents(mode == .signup ? [.large] : [.fraction(0.65), .large]).presentationDragIndicator(.visible).presentationCornerRadius(32)
            .onAppear { mode = initialMode; community.error = nil }
            .onDisappear { password = ""; confirm = "" }
    }
    private var primaryTitle: String {
        switch mode {
        case .signup: return store.t("Create account", "建立帳戶")
        case .login: return store.t("Sign in", "登入")
        case .recovery: return store.t("Send reset link", "寄送重設連結")
        default: return store.t("Continue", "繼續")
        }
    }
    private func field<Content: View>(_ label: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if mode == .signup { Text(label).font(.subheadline.weight(.semibold)) }
            HStack(spacing: 12) { Image(systemName: symbol).foregroundStyle(.secondary); content() }
                .padding(18).frame(minHeight: 56).background(.white, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.gray.opacity(0.18)))
        }
    }
    private func provider(_ name: String, symbol: String) -> some View {
        Button { notice = store.t("This provider is not connected yet. Please continue with email.", "此登入方式尚未連接，請使用電郵繼續。") } label: {
            HStack(spacing: 12) {
                if name == "Google", let url = Bundle.main.url(forResource: "google-g", withExtension: "png"), let image = UIImage(contentsOfFile: url.path) { Image(uiImage: image).resizable().scaledToFit().frame(width: 22, height: 22) }
                else { Image(systemName: symbol).frame(width: 22, height: 22) }
                Text(store.t("Continue with \(name)", "使用 \(name) 繼續")).font(.headline)
            }.foregroundStyle(Color.primary).frame(maxWidth: .infinity, minHeight: 56).background(.white, in: Capsule()).overlay(Capsule().stroke(Color.gray.opacity(0.2)))
        }
    }
    private func move(_ next: AccountMode) { mode = next; notice = nil; community.error = nil; password = ""; confirm = "" }
    private func submit() {
        notice = nil
        guard validEmail, !community.busy else { return }
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .email { mode = .signup; return }
        if mode == .signup {
            guard PasswordPolicy.accepts(password) else { community.error = .weakPassword; return }
            guard password == confirm else { notice = store.t("Passwords do not match.", "兩次輸入的密碼不相符。"); return }
        }
        if mode == .login && password.isEmpty { notice = store.t("Enter your password.", "請輸入密碼。"); return }
        Task {
            let successful: Bool
            switch mode {
            case .signup: successful = await community.createAccount(address, password: password)
            case .recovery: successful = await community.resetPassword(address)
            default: successful = await community.passwordSignIn(address, password: password)
            }
            if successful {
                password = ""; confirm = ""
                if community.user != nil { dismiss() }
                else if mode == .recovery { notice = store.t("If an account exists, check your email. Open the reset link to choose a new password, then return to this app.", "如帳戶存在，請檢查電郵。開啟重設連結設定新密碼，再返回此應用程式。") }
                else { mode = .confirmation }
            }
        }
    }
}

struct PasswordChecklist: View {
    @EnvironmentObject var store: AppStore
    let password: String
    private var labels: [String] { [store.t("At least 8 characters", "至少八個字元"), store.t("Uppercase letter (A–Z)", "大寫字母（A–Z）"), store.t("Lowercase letter (a–z)", "小寫字母（a–z）"), store.t("Number (0–9)", "數字（0–9）"), store.t("Symbol (e.g. ! @ #)", "符號（例如 ! @ #）")] }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(labels.indices, id: \.self) { index in
                Label(labels[index], systemImage: PasswordPolicy.requirements(password)[index] ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(PasswordPolicy.requirements(password)[index] ? Brand.blue : .secondary)
                    .accessibilityValue(store.t(PasswordPolicy.requirements(password)[index] ? "Met" : "Not met", PasswordPolicy.requirements(password)[index] ? "已符合" : "未符合"))
            }
        }.font(.caption)
    }
}
