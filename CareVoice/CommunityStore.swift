import SwiftUI
import Security

enum CommunityConfiguration {
    // Publishable client configuration only. Never put a secret/service_role key here.
    static let projectURL = "https://lbbpuwtwhiectsmhhuej.supabase.co"
    static let publishableKey = "sb_publishable_uUt_7SQgMfPA0idY7ZBVHw_KOcWZHRY"
    static var current: (URL, String)? {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return nil }
        let address = Bundle.main.object(forInfoDictionaryKey: "CareVoiceCommunityURL") as? String ?? projectURL
        let key = Bundle.main.object(forInfoDictionaryKey: "CareVoiceCommunityPublishableKey") as? String ?? publishableKey
        guard let url = URL(string: address), url.scheme == "https", url.host != nil,
              key.hasPrefix("sb_publishable_") else { return nil }
        return (url, key)
    }
}

private enum CommunityKeychain {
    static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.carevoice.community.session", kSecAttrAccount as String: account]
    }
    static func read(_ account: String) throws -> Data? {
        var q = query(account); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw CommunityFailure.storage }
        return data
    }
    static func save(_ data: Data, account: String) throws {
        let attributes: [String: Any] = [kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query(account) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            guard SecItemAdd(query(account).merging(attributes) { _, new in new } as CFDictionary, nil) == errSecSuccess else { throw CommunityFailure.storage }
        } else if status != errSecSuccess { throw CommunityFailure.storage }
    }
    static func remove(_ account: String) throws {
        let status = SecItemDelete(query(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw CommunityFailure.storage }
    }
}

// Requests are serialized by CommunityStore, including refresh-token rotation.
@MainActor
final class CommunityAPI {
    let url: URL
    private let key: String
    private(set) var session: CommunitySession?
    private let decoder: JSONDecoder = { let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d }()
    private let encoder: JSONEncoder = { let e = JSONEncoder(); e.keyEncodingStrategy = .convertToSnakeCase; return e }()
    private let transport: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil; configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()
    init(url: URL, key: String) { self.url = url; self.key = key }
    func restore() throws {
        if let data = try CommunityKeychain.read(url.absoluteString) { session = try decoder.decode(CommunitySession.self, from: data) }
    }
    private func persist(_ value: CommunitySession) throws {
        try CommunityKeychain.save(encoder.encode(value), account: url.absoluteString)
        session = value
    }
    func clearSession() throws { try CommunityKeychain.remove(url.absoluteString); session = nil }
    private func send(_ path: String, method: String, body: [String: Any]?, token: String?, query: [URLQueryItem] = []) async throws -> Data {
        var parts = URLComponents(url: url.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        parts.queryItems = query.isEmpty ? nil : query
        var request = URLRequest(url: parts.url!); request.httpMethod = method
        request.setValue(key, forHTTPHeaderField: "apikey")
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if path.hasPrefix("rest/") { request.setValue("return=representation", forHTTPHeaderField: "Prefer") }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CommunityFailure.network }
        guard (200...299).contains(http.statusCode) else {
            // Never show raw server errors or tokens to the user.
            let message = String(data: data, encoding: .utf8) ?? ""
            if message.contains("over_email_send_rate_limit") { throw CommunityFailure.emailLimit }
            if message.contains("email_not_confirmed") { throw CommunityFailure.unconfirmed }
            if message.contains("invalid_credentials") { throw CommunityFailure.credentials }
            if message.contains("weak_password") { throw CommunityFailure.weakPassword }
            if message.contains("email_address_not_authorized") { throw CommunityFailure.emailUnavailable }
            if http.statusCode == 429 || message.contains("community_rate_limit") { throw CommunityFailure.rateLimit }
            if http.statusCode == 401 {
                if token != nil { try clearSession() }
                throw CommunityFailure.signIn
            }
            if http.statusCode == 403 || message.contains("42501") { throw CommunityFailure.denied }
            if http.statusCode == 409 { throw CommunityFailure.conflict }
            throw http.statusCode >= 500 ? CommunityFailure.network : CommunityFailure.invalid
        }
        return data
    }
    private func token() async throws -> String {
        guard let current = session else { throw CommunityFailure.signIn }
        if current.expiresAt > Date().timeIntervalSince1970 + 60 { return current.accessToken }
        do {
            let data = try await send("auth/v1/token", method: "POST", body: ["refresh_token": current.refreshToken], token: nil,
                query: [URLQueryItem(name: "grant_type", value: "refresh_token")])
            let updated = try decoder.decode(CommunitySession.self, from: data)
            try persist(updated); return updated.accessToken
        } catch CommunityFailure.invalid { try clearSession(); throw CommunityFailure.signIn }
          catch CommunityFailure.signIn { try clearSession(); throw CommunityFailure.signIn }
    }
    func passwordSignIn(email: String, password: String) async throws {
        let bytes = try await send("auth/v1/token", method: "POST", body: ["email": email, "password": password], token: nil,
                                   query: [URLQueryItem(name: "grant_type", value: "password")])
        try persist(decoder.decode(CommunitySession.self, from: bytes))
    }
    func createAccount(email: String, password: String) async throws {
        guard PasswordPolicy.accepts(password) else { throw CommunityFailure.weakPassword }
        let bytes = try await send("auth/v1/signup", method: "POST", body: ["email": email, "password": password], token: nil,
                                   query: [URLQueryItem(name: "redirect_to", value: "https://carevoice-preview-zeta.vercel.app/")])
        // An unconfirmed user is not a session. Never grant access just because signup returned 200.
        if let value = try? decoder.decode(CommunitySession.self, from: bytes) { try persist(value) }
    }
    func resetPassword(email: String) async throws {
        _ = try await send("auth/v1/recover", method: "POST", body: ["email": email], token: nil,
                           query: [URLQueryItem(name: "redirect_to", value: "https://carevoice-preview-zeta.vercel.app/")])
    }
    func validateSession() async throws {
        guard session != nil else { return }
        let bearer = try await token()
        _ = try decoder.decode(CommunityUser.self, from: await send("auth/v1/user", method: "GET", body: nil, token: bearer))
    }
    func signOut() async throws {
        do {
            if session != nil {
                let bearer = try await token()
                _ = try await send("auth/v1/logout", method: "POST", body: nil, token: bearer,
                    query: [URLQueryItem(name: "scope", value: "local")])
            }
        } catch {
            // Always remove credentials from this device, including when offline.
            try clearSession()
            throw error
        }
        try clearSession()
    }
    func rpc<T: Decodable>(_ name: String, body: [String: Any] = [:], as type: T.Type) async throws -> T {
        let bearer = try await token()
        return try decoder.decode(type, from: await send("rest/v1/rpc/" + name, method: "POST", body: body, token: bearer))
    }
    func rows<T: Decodable>(_ table: String, query: [URLQueryItem] = [], as type: T.Type) async throws -> T {
        let bearer = try await token()
        return try decoder.decode(type, from: await send("rest/v1/" + table, method: "GET", body: nil, token: bearer, query: query))
    }
    func mutate(_ table: String, method: String, body: [String: Any]? = nil, id: UUID? = nil, idColumn: String = "id") async throws {
        let bearer = try await token()
        let query = id.map { [URLQueryItem(name: idColumn, value: "eq." + $0.uuidString)] } ?? []
        let data = try await send("rest/v1/" + table, method: method, body: body, token: bearer, query: query)
        // RLS can turn a rejected update/delete into a successful HTTP response with zero rows.
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [Any], !rows.isEmpty else { throw CommunityFailure.denied }
    }
}

@MainActor
final class CommunityStore: ObservableObject {
    @Published private(set) var user: CommunityUser?
    @Published private(set) var profile: CommunityProfile?
    @Published private(set) var identityLoaded = false
    @Published private(set) var posts: [CommunityPost] = []
    @Published private(set) var moderator = false
    @Published private(set) var busy = false
    @Published private(set) var restoring = true
    @Published private(set) var hasMore = false
    @Published var error: CommunityFailure?
    @Published var topic: CommunityTopic?
    @Published var mine = false
    private let api: CommunityAPI?
    private var started = false
    // Simulator-only UI fixtures have no tokens, transport or production access.
    private var previewIdentity = false
    var configured: Bool { api != nil || previewIdentity }
    init() {
        api = CommunityConfiguration.current.map { CommunityAPI(url: $0.0, key: $0.1) }
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing") && arguments.contains("--community-member-preview") {
            previewIdentity = true; started = true; restoring = false; identityLoaded = true
            let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            user = CommunityUser(id: id, email: nil)
            if arguments.contains("--community-existing-profile") {
                profile = CommunityProfile(userId: id, displayName: "Preview parent")
            }
        }
        #endif
    }
    @discardableResult
    func perform(_ operation: (CommunityAPI) async throws -> Void) async -> Bool {
        guard !busy else { return false }
        guard let api else { error = .unavailable; return false }
        busy = true; error = nil
        defer { busy = false; user = api.session?.user }
        do { try await operation(api); return true }
        catch {
            self.error = error as? CommunityFailure ?? .network
            if api.session == nil { profile = nil; posts = []; moderator = false; identityLoaded = false }
            return false
        }
    }
    func start() async {
        guard !started else { return }; started = true
        defer { restoring = false }
        guard configured else { return }
        await perform { api in
            try api.restore()
            // Do not expose a cached identity before checking its token with Auth.
            do { try await api.validateSession() }
            catch { try api.clearSession(); throw error }
        }
    }
    func passwordSignIn(_ email: String, password: String) async -> Bool {
        await perform { try await $0.passwordSignIn(email: email, password: password) }
    }
    func createAccount(_ email: String, password: String) async -> Bool {
        await perform { try await $0.createAccount(email: email, password: password) }
    }
    func resetPassword(_ email: String) async -> Bool { await perform { try await $0.resetPassword(email: email) } }
    private func loadIdentity(_ api: CommunityAPI) async throws {
        guard let id = api.session?.user.id else { throw CommunityFailure.signIn }
        let profiles = try await api.rows("community_profiles", query: [URLQueryItem(name: "user_id", value: "eq." + id.uuidString)], as: [CommunityProfile].self)
        let isModerator = try await api.rpc("community_is_moderator", as: Bool.self)
        profile = profiles.first
        moderator = isModerator
        identityLoaded = true
    }
    func saveNickname(_ nickname: String) async -> Bool {
        guard CommunityValidation.validNickname(nickname) else { error = .invalid; return false }
        return await perform { api in
            guard let id = api.session?.user.id else { throw CommunityFailure.signIn }
            let body: [String: Any] = profile == nil ? ["user_id": id.uuidString, "display_name": CommunityValidation.clean(nickname)] : ["display_name": CommunityValidation.clean(nickname)]
            try await api.mutate("community_profiles", method: profile == nil ? "POST" : "PATCH", body: body,
                id: profile == nil ? nil : id, idColumn: "user_id")
            try await loadIdentity(api); try await fetchFeed(api, more: false)
        }
    }
    private func fetchFeed(_ api: CommunityAPI, more: Bool) async throws {
        var body: [String: Any] = ["p_mine": mine]
        if let topic { body["p_topic"] = topic.rawValue }
        if more, let last = posts.last { body["p_before"] = last.createdAt; body["p_before_id"] = last.id.uuidString }
        let result = try await api.rpc("community_feed", body: body, as: [CommunityPost].self)
        hasMore = result.count == 20
        if more { let existing = Set(posts.map(\.id)); posts += result.filter { !existing.contains($0.id) } }
        else { posts = result }
    }
    func refresh(more: Bool = false) async {
        guard !previewIdentity else { return }
        await perform { api in try await loadIdentity(api); try await fetchFeed(api, more: more) }
    }
    func savePost(id: UUID? = nil, topic: CommunityTopic, title: String, body: String) async -> Bool {
        guard CommunityValidation.validPost(title: title, body: body) else { error = .invalid; return false }
        return await perform { api in
            try await api.mutate("community_posts", method: id == nil ? "POST" : "PATCH",
                body: ["topic": topic.rawValue, "title": CommunityValidation.clean(title), "body": CommunityValidation.clean(body)], id: id)
        }
    }
    func delete(_ id: UUID, reply: Bool = false) async -> Bool {
        await perform { try await $0.mutate(reply ? "community_replies" : "community_posts", method: "DELETE", id: id) }
    }
    func saveReply(post: UUID, id: UUID? = nil, body: String) async -> Bool {
        guard CommunityValidation.validReply(body) else { error = .invalid; return false }
        return await perform { api in
            var values: [String: Any] = ["body": CommunityValidation.clean(body)]
            if id == nil { values["post_id"] = post.uuidString }
            try await api.mutate("community_replies", method: id == nil ? "POST" : "PATCH", body: values, id: id)
        }
    }
    func report(kind: String, id: UUID, reason: CommunityReason, detail: String) async -> Bool {
        guard CommunityValidation.length(detail) <= 1000 else { error = .invalid; return false }
        return await perform { api in
            try await api.mutate("community_reports", method: "POST", body: ["target_kind": kind, "target_id": id.uuidString,
                "reason": reason.rawValue, "detail": CommunityValidation.clean(detail)])
        }
    }
    func block(_ id: UUID) async -> Bool {
        await perform { api in try await api.mutate("community_blocks", method: "POST", body: ["blocked_id": id.uuidString]); posts = [] }
    }
    func signOut() async -> Bool {
        await perform { api in try await api.signOut(); profile = nil; posts = []; moderator = false; identityLoaded = false }
    }
    func deleteAccount() async -> Bool {
        await perform { api in
            _ = try await api.rpc("community_delete_account", as: Bool.self)
            try api.clearSession(); profile = nil; posts = []; moderator = false; identityLoaded = false
        }
    }
}
