import SwiftUI

// Hallmark · pre-emit critique: P4 H5 E4 S5 R5 V4
struct CommunityErrorNotice: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    var body: some View {
        if let error = community.error {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.circle")
                Text(error.message(store.language)).font(.subheadline)
                Spacer()
                Button { community.error = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel(store.t("Dismiss message", "關閉訊息"))
            }.padding(12).background(Brand.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("communityError")
        }
    }
}

struct ParentCommunityView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    @State private var composing = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.t("Together, through the everyday.", "日常照顧，一起同行。")).font(.title2.bold())
                        Text(store.t("Questions, experiences and small wins from other parents.", "與其他家長分享問題、經驗和小小進步。"))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    NavigationLink { CommunityAccountView(community: community) } label: {
                        Image(systemName: "person.crop.circle").font(.title2).frame(width: 44, height: 44)
                    }.accessibilityLabel(store.t("Community account", "社區帳戶"))
                }
                CommunityErrorNotice(community: community)
                if community.user == nil || community.profile == nil {
                    CommunityAccountView(community: community, embedded: true)
                } else {
                    HStack {
                        Picker(store.t("Posts", "帖子"), selection: $community.mine) {
                            Text(store.t("Latest", "最新")).tag(false)
                            Text(store.t("My posts", "我的帖子")).tag(true)
                        }.pickerStyle(.segmented).disabled(community.busy)
                        Button { composing = true } label: {
                            Image(systemName: "square.and.pencil").font(.title3).frame(width: 48, height: 44)
                        }.buttonStyle(.borderedProminent).accessibilityLabel(store.t("Create a post", "發佈帖子"))
                    }
                    Picker(store.t("Topic", "主題"), selection: $community.topic) {
                        Text(store.t("All topics", "全部主題")).tag(Optional<CommunityTopic>.none)
                        ForEach(CommunityTopic.allCases) { topic in Text(topic.title(store.language)).tag(Optional(topic)) }
                    }.pickerStyle(.menu).disabled(community.busy)
                    if community.busy && community.posts.isEmpty { ProgressView().frame(maxWidth: .infinity) }
                    else if community.posts.isEmpty {
                        ContentUnavailableView(store.t("A conversation can start with you", "由你開始一段交流"), systemImage: "bubble.left.and.bubble.right",
                            description: Text(store.t("No posts here yet. Share a question or an everyday moment.", "這裡還沒有帖子。分享一個問題或日常片段吧。")))
                    }
                    LazyVStack(spacing: 14) {
                        ForEach(community.posts) { post in
                            NavigationLink { CommunityDiscussionView(postId: post.id, community: community) } label: {
                                Card {
                                    HStack {
                                        Text(post.topic.title(store.language)).font(.caption.weight(.semibold)).foregroundStyle(Brand.blue)
                                        Spacer(); Text(post.authorName).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(post.title).font(.headline).foregroundStyle(.primary)
                                    Text(post.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                                    HStack {
                                        Label("\(post.replyCount)", systemImage: "bubble.right")
                                        if post.removed { Text(store.t("Removed by moderation", "已由管理員移除")) }
                                        Spacer()
                                        if let date = CommunityValidation.date(post.createdAt) { Text(date, style: .date) }
                                    }.font(.caption).foregroundStyle(.secondary)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    if community.hasMore {
                        Button(store.t("Load more", "載入更多")) { Task { await community.refresh(more: true) } }.disabled(community.busy)
                    }
                    Text(store.t("Shared experiences are personal perspectives, not professional advice.", "分享的經驗屬個人觀點，並非專業意見。"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(Brand.background)
        .scrollDismissesKeyboard(.interactively)
        .refreshable { if community.user != nil { await community.refresh() } }
        .task { await community.start(); if community.user != nil { await community.refresh() } }
        .onChange(of: community.mine) { _, _ in Task { await community.refresh() } }
        .onChange(of: community.topic) { _, _ in Task { await community.refresh() } }
        .sheet(isPresented: $composing) { NavigationStack { CommunityPostEditor(community: community) } }
        .onChange(of: composing) { _, value in if !value { Task { await community.refresh() } } }
        .navigationTitle(store.t("Parent conversations", "家長交流"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CommunityAccountView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    var embedded = false
    @State private var name = ""
    @State private var deleteAccount = false
    @State private var acceptedGuidelines = false
    @FocusState private var nicknameFocused: Bool
    var body: some View {
        Group {
            if embedded { content }
            else {
                ScrollView { content.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity) }
                    .scrollDismissesKeyboard(.interactively)
                    .navigationTitle(store.t("Community account", "社區帳戶"))
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task { await community.start(); if community.user != nil { await community.refresh() }; name = community.profile?.displayName ?? "" }
        .onChange(of: community.profile?.displayName) { _, value in name = value ?? "" }
        .alert(store.t("Delete your CareVoice account?", "刪除 CareVoice 帳戶？"), isPresented: $deleteAccount) {
            Button(store.t("Cancel", "取消"), role: .cancel) {}
            Button(store.t("Delete account", "刪除帳戶"), role: .destructive) { Task { _ = await community.deleteAccount() } }
        } message: { Text(store.t("This deletes your CareVoice sign-in, community profile, posts and replies. Export your child's records in Settings first; after deletion you cannot sign back into this account to open its local records.", "這會刪除你的 CareVoice 登入帳戶、社區檔案、帖子及回覆。請先在設定匯出孩子的記錄；刪除後將無法再登入此帳戶以開啟其本機記錄。")) }
    }
    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !embedded { CommunityErrorNotice(community: community) }
            if !community.configured {
                Card {
                    Label(store.t("Community setup is pending", "社區設定待完成"), systemImage: "person.2").font(.headline)
                    Text(store.t("The community screens are ready. Shared posts will be available after the account service is connected.", "社區頁面已準備好。連接帳戶服務後即可分享帖子。"))
                        .foregroundStyle(.secondary)
                    NavigationLink(store.t("Read community guidelines", "閱讀社區守則")) { SettingsDetailView(page: .guidelines) }
                }
            } else if community.user == nil {
                AccountForm(community: community, initialMode: .login)
            } else if !community.identityLoaded {
                if community.busy || community.restoring {
                    ProgressView(store.t("Loading your community profile…", "正在載入社區檔案…")).frame(maxWidth: .infinity)
                } else {
                    Button(store.t("Try again", "再試一次")) { Task { await community.refresh() } }.disabled(community.busy)
                }
            } else {
                Card {
                    if community.profile == nil {
                        Text(store.t("Join the conversation", "加入交流")).font(.title2.bold())
                        Text(store.t("You're signed in with CareVoice. Choose how your name appears to other parents.", "你已登入 CareVoice。請選擇向其他家長顯示的暱稱。")).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text(store.t("Your public nickname", "你的公開暱稱")).font(.headline)
                    TextField(store.t("Choose a nickname", "選擇暱稱"), text: $name).textFieldStyle(.roundedBorder)
                        .textContentType(.nickname).accessibilityIdentifier("communityNickname")
                        .focused($nicknameFocused).submitLabel(.done)
                        .onSubmit { nicknameFocused = false }
                    Text(store.t("Use 2–40 characters. This is separate from your child's profile and appears beside posts and replies.", "請使用 2–40 個字元。此暱稱與孩子的檔案分開，並會顯示於帖子及回覆旁。"))
                        .font(.caption).foregroundStyle(.secondary)
                    if community.profile == nil {
                        NavigationLink(store.t("Read community guidelines", "閱讀社區守則")) { SettingsDetailView(page: .guidelines) }
                        Toggle(store.t("I agree to the community guidelines", "我同意遵守社區守則"), isOn: $acceptedGuidelines)
                            .accessibilityIdentifier("acceptCommunityGuidelines")
                    }
                    Button(store.t(community.profile == nil ? "Join community" : "Save community profile", community.profile == nil ? "加入社區" : "儲存社區檔案")) { Task { _ = await community.saveNickname(name) } }
                        .buttonStyle(.borderedProminent)
                        .disabled(community.busy || !CommunityValidation.validNickname(name) || (community.profile == nil && !acceptedGuidelines))
                        .accessibilityIdentifier("saveCommunityProfile")
                }
                if community.profile != nil {
                    NavigationLink(store.t("Blocked accounts", "已封鎖帳戶")) { CommunityBlockedView(community: community) }
                    if community.moderator {
                        NavigationLink(store.t("Moderation queue", "待審核舉報")) { CommunityModerationView(community: community) }
                    }
                }
                if !embedded {
                    Button(store.t("Sign out of CareVoice", "登出 CareVoice")) { Task { _ = await community.signOut() } }.disabled(community.busy)
                    Button(store.t("Delete CareVoice account", "刪除 CareVoice 帳戶"), role: .destructive) { deleteAccount = true }.disabled(community.busy)
                }
            }
            if community.busy { ProgressView().frame(maxWidth: .infinity) }
        }
    }
}

struct CommunityPostEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var community: CommunityStore
    var post: CommunityPost?
    @State private var title = ""
    @State private var bodyText = ""
    @State private var topic: CommunityTopic = .everyday
    @State private var discard = false
    var body: some View {
        Form {
            CommunityErrorNotice(community: community)
            Section {
                Picker(store.t("Topic", "主題"), selection: $topic) {
                    ForEach(CommunityTopic.allCases) { Text($0.title(store.language)).tag($0) }
                }
                TextField(store.t("Give your question a title", "為問題加上標題"), text: $title, axis: .vertical).lineLimit(1...3)
                TextField(store.t("What would you like to share?", "你想分享甚麼？"), text: $bodyText, axis: .vertical).lineLimit(6...14)
                Text("\(CommunityValidation.length(title))/120 · \(CommunityValidation.length(bodyText))/3000").font(.caption).foregroundStyle(.secondary)
            } footer: {
                Text(store.t("This will be shared with signed-in community members. Leave out children's names, schools, contact details and medical documents.", "內容將與已登入的社區成員分享。請勿加入孩子姓名、學校、聯絡資料或醫療文件。"))
            }
        }.navigationTitle(store.t(post == nil ? "New discussion" : "Edit post", post == nil ? "新討論" : "編輯帖子"))
            .navigationBarTitleDisplayMode(.inline).interactiveDismissDisabled()
            .onAppear { if let post { title = post.title; bodyText = post.body; topic = post.topic } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("Cancel", "取消")) {
                        if title != (post?.title ?? "") || bodyText != (post?.body ?? "") || topic != (post?.topic ?? .everyday) { discard = true }
                        else { dismiss() }
                    }.disabled(community.busy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t(post == nil ? "Publish" : "Save", post == nil ? "發佈" : "儲存")) {
                        Task { if await community.savePost(id: post?.id, topic: topic, title: title, body: bodyText) { dismiss() } }
                    }.disabled(community.busy || !CommunityValidation.validPost(title: title, body: bodyText))
                }
            }
            .confirmationDialog(store.t("Discard your changes?", "放棄變更？"), isPresented: $discard, titleVisibility: .visible) {
                Button(store.t("Discard", "放棄"), role: .destructive) { dismiss() }
            }
    }
}

struct CommunityReportTarget: Identifiable { let kind: String; let id: UUID }
struct CommunityDiscussionView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let postId: UUID
    @ObservedObject var community: CommunityStore
    @State private var post: CommunityPost?
    @State private var replies: [CommunityReply] = []
    @State private var replyText = ""
    @State private var more = false
    @State private var loaded = false
    @State private var editing = false
    @State private var editingReply: CommunityReply?
    @State private var report: CommunityReportTarget?
    @State private var deleting: CommunityReportTarget?
    @State private var blocking: UUID?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CommunityErrorNotice(community: community)
                if let post {
                    HStack {
                        Text(post.authorName).font(.subheadline.weight(.semibold)); Spacer()
                        Menu {
                            if post.authorId == community.user?.id {
                                Button(store.t("Edit post", "編輯帖子")) { editing = true }
                                Button(store.t("Delete post", "刪除帖子"), role: .destructive) { deleting = .init(kind: "post", id: post.id) }
                            } else {
                                Button(store.t("Report post", "舉報帖子")) { report = .init(kind: "post", id: post.id) }
                                Button(store.t("Block this parent", "封鎖此家長"), role: .destructive) { blocking = post.authorId }
                            }
                        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.disabled(community.busy)
                    }
                    Text(post.topic.title(store.language)).font(.caption).foregroundStyle(Brand.blue)
                    Text(post.title).font(.title2.bold())
                    Text(post.body).textSelection(.enabled)
                    if post.removed { Text(store.t("This post was removed by moderation.", "此帖子已由管理員移除。")).foregroundStyle(.secondary) }
                    Divider()
                    Text(store.t("Replies", "回覆")).font(.headline)
                    ForEach(replies) { reply in
                        Card {
                            HStack {
                                Text(reply.authorName).font(.subheadline.bold()); Spacer()
                                Menu {
                                    if reply.authorId == community.user?.id {
                                        Button(store.t("Edit reply", "編輯回覆")) { editingReply = reply }
                                        Button(store.t("Delete reply", "刪除回覆"), role: .destructive) { deleting = .init(kind: "reply", id: reply.id) }
                                    } else {
                                        Button(store.t("Report reply", "舉報回覆")) { report = .init(kind: "reply", id: reply.id) }
                                        Button(store.t("Block this parent", "封鎖此家長"), role: .destructive) { blocking = reply.authorId }
                                    }
                                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.disabled(community.busy)
                            }
                            Text(reply.body).textSelection(.enabled)
                            if reply.status == "removed" { Text(store.t("Removed by moderation", "已由管理員移除")).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    if replies.isEmpty && !community.busy { Text(store.t("No replies yet. Be the first to respond.", "還沒有回覆，分享你的想法吧。")).foregroundStyle(.secondary) }
                    if more { Button(store.t("More replies", "更多回覆")) { Task { await load(more: true) } }.disabled(community.busy) }
                } else if loaded {
                    ContentUnavailableView(store.t("Discussion unavailable", "討論無法顯示"), systemImage: "bubble.left",
                        description: Text(store.t("It may have been deleted, removed or hidden by a block.", "此討論可能已刪除、移除或因封鎖而隱藏。")))
                }
                if community.busy { ProgressView().frame(maxWidth: .infinity) }
            }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(Brand.background).navigationTitle(store.t("Discussion", "討論")).navigationBarTitleDisplayMode(.inline)
            .task { await load() }.refreshable { await load() }
            .onChange(of: community.user?.id) { _, _ in post = nil; replies = []; more = false }
            .safeAreaInset(edge: .bottom) {
                if let post, !post.removed, community.profile != nil {
                    HStack(alignment: .bottom) {
                        TextField(store.t("Write a kind reply…", "寫下友善的回覆…"), text: $replyText, axis: .vertical).lineLimit(1...4)
                            .padding(12).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                        Button {
                            Task { if await community.saveReply(post: postId, body: replyText) { replyText = ""; await load() } }
                        } label: { Image(systemName: "arrow.up").frame(width: 44, height: 44) }
                            .buttonStyle(.borderedProminent).accessibilityLabel(store.t("Send reply", "傳送回覆"))
                            .disabled(community.busy || !CommunityValidation.validReply(replyText))
                    }.padding(12).background(.bar)
                }
            }
            .sheet(isPresented: $editing, onDismiss: { Task { await load() } }) {
                NavigationStack { CommunityPostEditor(community: community, post: post) }
            }
            .sheet(item: $editingReply, onDismiss: { Task { await load() } }) { reply in
                NavigationStack { CommunityReplyEditor(community: community, reply: reply) }
            }
            .sheet(item: $report) { target in NavigationStack { CommunityReportView(community: community, target: target) } }
            .confirmationDialog(store.t("Delete this content?", "刪除此內容？"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                if let target = deleting {
                    Button(store.t("Delete", "刪除"), role: .destructive) {
                        Task { if await community.delete(target.id, reply: target.kind == "reply") { if target.kind == "post" { dismiss() } else { await load() } } }
                    }
                }
            }
            .confirmationDialog(store.t("Block this parent? Their discussions and replies will be hidden from you, and yours from them.", "封鎖此家長？你們將無法查看彼此的討論及回覆。"), isPresented: Binding(get: { blocking != nil }, set: { if !$0 { blocking = nil } }), titleVisibility: .visible) {
                if let id = blocking {
                    Button(store.t("Block parent", "封鎖家長"), role: .destructive) { Task { if await community.block(id) { replies = []; if post?.authorId == id { post = nil }; await load() } } }
                }
            }
    }
    private func load(more loadMore: Bool = false) async {
        await community.perform { api in
            let results = try await api.rpc("community_feed", body: ["p_post_id": postId.uuidString], as: [CommunityPost].self)
            post = results.first; loaded = true
            guard post != nil else { replies = []; more = false; return }
            var body: [String: Any] = ["p_post_id": postId.uuidString]
            if loadMore, let last = replies.last { body["p_after"] = last.createdAt; body["p_after_id"] = last.id.uuidString }
            let result = try await api.rpc("community_thread", body: body, as: [CommunityReply].self)
            more = result.count == 30
            if loadMore { let ids = Set(replies.map(\.id)); replies += result.filter { !ids.contains($0.id) } } else { replies = result }
        }
    }
}

struct CommunityReplyEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var community: CommunityStore
    let reply: CommunityReply
    @State private var text = ""
    @State private var discard = false
    var body: some View {
        Form {
            CommunityErrorNotice(community: community)
            TextField(store.t("Your reply", "你的回覆"), text: $text, axis: .vertical).lineLimit(5...12)
            Text("\(CommunityValidation.length(text))/1500").font(.caption).foregroundStyle(.secondary)
        }.navigationTitle(store.t("Edit reply", "編輯回覆")).navigationBarTitleDisplayMode(.inline)
            .onAppear { text = reply.body }.interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("Cancel", "取消")) { if text == reply.body { dismiss() } else { discard = true } }.disabled(community.busy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("Save", "儲存")) { Task { if await community.saveReply(post: reply.postId, id: reply.id, body: text) { dismiss() } } }
                        .disabled(community.busy || !CommunityValidation.validReply(text))
                }
            }.confirmationDialog(store.t("Discard changes?", "放棄變更？"), isPresented: $discard, titleVisibility: .visible) {
                Button(store.t("Discard", "放棄"), role: .destructive) { dismiss() }
            }
    }
}

struct CommunityReportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var community: CommunityStore
    let target: CommunityReportTarget
    @State private var reason: CommunityReason = .privacy
    @State private var detail = ""
    @State private var sent = false
    var body: some View {
        Form {
            CommunityErrorNotice(community: community)
            if sent {
                Label(store.t("Report received", "已收到舉報"), systemImage: "checkmark.shield")
                Text(store.t("A moderator can review it. Reporting does not automatically remove content.", "管理員可審核此舉報。舉報不會自動移除內容。"))
                Button(store.t("Done", "完成")) { dismiss() }
            } else {
                Picker(store.t("Reason", "原因"), selection: $reason) {
                    ForEach(CommunityReason.allCases) { Text($0.title(store.language)).tag($0) }
                }
                TextField(store.t("Details (optional)", "詳細說明（選填）"), text: $detail, axis: .vertical).lineLimit(3...6)
                Text(store.t("Only moderators can review your report. Avoid adding identifying details about a child.", "只有管理員可審核你的舉報。請避免加入可識別孩子身份的資料。"))
                    .font(.caption).foregroundStyle(.secondary)
                Button(store.t("Submit report", "提交舉報")) {
                    Task { if await community.report(kind: target.kind, id: target.id, reason: reason, detail: detail) { sent = true } }
                }.disabled(community.busy || CommunityValidation.length(detail) > 1000)
            }
        }.navigationTitle(store.t("Report content", "舉報內容")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(store.t("Close", "關閉")) { dismiss() }.disabled(community.busy) } }
    }
}

struct CommunityBlockedView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    @State private var people: [CommunityProfile] = []
    var body: some View {
        List {
            CommunityErrorNotice(community: community)
            if people.isEmpty { Text(store.t("No blocked accounts", "沒有已封鎖帳戶")).foregroundStyle(.secondary) }
            ForEach(people) { person in
                HStack {
                    Text(person.displayName); Spacer()
                    Button(store.t("Unblock", "解除封鎖")) { Task {
                        if await community.perform({ try await $0.mutate("community_blocks", method: "DELETE", id: person.userId, idColumn: "blocked_id") }) { await load() }
                    } }.disabled(community.busy)
                }
            }
        }.navigationTitle(store.t("Blocked accounts", "已封鎖帳戶")).navigationBarTitleDisplayMode(.inline)
            .task { await load() }.refreshable { await load() }
            .onChange(of: community.user?.id) { _, _ in people = [] }
    }
    private func load() async {
        await community.perform { api in
            let blocks = try await api.rows("community_blocks", as: [CommunityBlock].self)
            if blocks.isEmpty { people = []; return }
            people = try await api.rows("community_profiles", query: [URLQueryItem(name: "user_id", value: "in.(" + blocks.map { $0.blockedId.uuidString }.joined(separator: ",") + ")")], as: [CommunityProfile].self)
        }
    }
}

struct CommunityModerationView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var community: CommunityStore
    @State private var reports: [CommunityReport] = []
    var body: some View {
        List {
            CommunityErrorNotice(community: community)
            if reports.isEmpty { Text(store.t("No open reports", "沒有待處理舉報")).foregroundStyle(.secondary) }
            ForEach(reports) { report in
                NavigationLink { CommunityModerationDetail(community: community, report: report) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(CommunityReason(rawValue: report.reason)?.title(store.language) ?? report.reason).font(.headline)
                        Text(report.detail).font(.subheadline).lineLimit(2)
                    }
                }
            }
        }.navigationTitle(store.t("Moderation queue", "待審核舉報")).navigationBarTitleDisplayMode(.inline)
            .task { await load() }.refreshable { await load() }
            .onChange(of: community.moderator) { _, value in if !value { reports = [] } }
    }
    private func load() async {
        await community.perform { api in
            guard community.moderator else { throw CommunityFailure.denied }
            reports = try await api.rows("community_reports", query: [URLQueryItem(name: "state", value: "eq.open"),
                URLQueryItem(name: "order", value: "created_at.asc"), URLQueryItem(name: "limit", value: "20")], as: [CommunityReport].self)
        }
    }
}

struct CommunityModerationDetail: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var community: CommunityStore
    let report: CommunityReport
    @State private var content = ""
    @State private var action: String?
    var body: some View {
        List {
            CommunityErrorNotice(community: community)
            Section(store.t("Reported content", "被舉報內容")) { Text(content) }
            Section(store.t("Report details", "舉報詳情")) {
                Text(CommunityReason(rawValue: report.reason)?.title(store.language) ?? report.reason)
                Text(report.detail)
            }
            Button(store.t("Remove content", "移除內容"), role: .destructive) { action = "removed" }.disabled(community.busy)
            Button(store.t("Dismiss report", "不採取行動")) { action = "dismissed" }.disabled(community.busy)
        }.navigationTitle(store.t("Review report", "審核舉報")).navigationBarTitleDisplayMode(.inline)
            .task {
                await community.perform { api in
                    guard community.moderator else { throw CommunityFailure.denied }
                    let rows = try await api.rows(report.targetKind == "post" ? "community_posts" : "community_replies",
                        query: [URLQueryItem(name: "id", value: "eq." + report.targetId.uuidString), URLQueryItem(name: "select", value: "body")], as: [[String: String]].self)
                    content = rows.first?["body"] ?? store.t("The author has deleted this content.", "作者已刪除此內容。")
                }
            }
            .onChange(of: community.moderator) { _, value in if !value { content = "" } }
            .confirmationDialog(store.t("Confirm this moderation decision?", "確認此審核決定？"), isPresented: Binding(get: { action != nil }, set: { if !$0 { action = nil } }), titleVisibility: .visible) {
                if let action {
                    Button(store.t("Confirm", "確認"), role: action == "removed" ? .destructive : nil) { Task {
                        if await community.perform({ api in _ = try await api.rpc("community_resolve_report", body: ["p_report_id": report.id.uuidString, "p_action": action], as: Bool.self) }) { dismiss() }
                    } }
                }
            }
    }
}
