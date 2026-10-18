import Foundation

// Portable JSON uses the TypeScript data schema. Internal storage retains native date encoding.
enum BackupCodec {
    private static let languages = ["english": "en", "traditionalChinese": "zh", "simplifiedChinese": "zh-Hans"]
    private static func iso(_ date: Date) -> String { ISO8601DateFormatter().string(from: date) }
    private static func date(_ value: Any?) throws -> Date {
        guard let text = value as? String else { throw CocoaError(.coderReadCorrupt) }
        if let date = CommunityValidation.date(text) { return date }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"; formatter.isLenient = false
        guard let date = formatter.date(from: text), formatter.string(from: date) == text else { throw CocoaError(.coderReadCorrupt) }
        return date
    }
    static func encode(_ data: AppData) throws -> Data {
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(data)) as! [String: Any]
        object["language"] = languages[data.language.rawValue]
        // Swift encodes Int-keyed dictionaries as JSON objects, matching TS Record<number,...>.
        if var profile = object["profile"] as? [String: Any], let original = data.profile {
            profile["ageMonths"] = original.currentAgeMonths
            profile["firstConcernDate"] = iso(original.firstConcernDate)
            if let birthday = original.birthDate {
                let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
                profile["birthDate"] = formatter.string(from: birthday)
            }
            object["profile"] = profile
        } else { object["profile"] = NSNull() }
        object["records"] = try data.records.map { record -> [String: Any] in
            var value = try JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as! [String: Any]
            value["date"] = iso(record.date); value["durationMinutes"] = record.durationMinutes.map { $0 as Any } ?? NSNull()
            return value
        }
        return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }
    static func decode(_ bytes: Data) throws -> AppData {
        guard bytes.count < 20_000_000 else { throw CocoaError(.fileReadTooLarge) }
        if let native = try? JSONDecoder().decode(AppData.self, from: bytes) { return try validate(native) }
        guard var object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let code = object["language"] as? String, let language = languages.first(where: { $0.value == code })?.key else { throw CocoaError(.coderReadCorrupt) }
        object["language"] = language
        if var profile = object["profile"] as? [String: Any] {
            profile["firstConcernDate"] = try date(profile["firstConcernDate"]).timeIntervalSinceReferenceDate
            if profile["birthDate"] != nil { profile["birthDate"] = try date(profile["birthDate"]).timeIntervalSinceReferenceDate }
            object["profile"] = profile
        }
        guard let records = object["records"] as? [[String: Any]] else { throw CocoaError(.coderReadCorrupt) }
        object["records"] = try records.map { record -> [String: Any] in
            var value = record; value["date"] = try date(record["date"]).timeIntervalSinceReferenceDate; return value
        }
        return try validate(JSONDecoder().decode(AppData.self, from: JSONSerialization.data(withJSONObject: object)))
    }
    private static func validate(_ data: AppData) throws -> AppData {
        guard data.version == 1,
              data.profile.map({ (0...83).contains($0.ageMonths) && ($0.birthDate.map { $0 <= Date() } ?? true) }) ?? true,
              Set(data.records.map(\.id)).count == data.records.count,
              data.records.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ($0.durationMinutes.map { (0...1440).contains($0) } ?? true) }) else { throw CocoaError(.coderReadCorrupt) }
        return data
    }
}
