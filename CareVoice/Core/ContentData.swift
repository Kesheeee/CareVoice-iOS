import Foundation

enum ContentData {
    // The review generator supplies these resources for a one-file Xcode target.
    static let embedded: [String: String] = [:]
    static func load(_ name: String) -> Data? {
        if let url = Bundle.main.url(forResource: name, withExtension: "json"),
           let data = try? Data(contentsOf: url) { return data }
        return embedded[name].flatMap { Data(base64Encoded: $0) }
    }
}
