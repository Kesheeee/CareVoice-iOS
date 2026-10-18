import Foundation

enum PasswordPolicy {
    // Match mobile/src/platform/password.ts and the server policy, including ASCII symbols.
    static func requirements(_ password: String) -> [Bool] {
        let scalars = password.unicodeScalars.map(\.value)
        return [scalars.count >= 8,
                scalars.contains { (65...90).contains($0) },
                scalars.contains { (97...122).contains($0) },
                scalars.contains { (48...57).contains($0) },
                scalars.contains { (33...47).contains($0) || (58...64).contains($0) || (91...96).contains($0) || (123...126).contains($0) }]
    }
    static func accepts(_ password: String) -> Bool { requirements(password).allSatisfy { $0 } }
}
