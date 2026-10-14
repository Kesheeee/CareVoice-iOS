// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "CareVoiceCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "CareVoiceCore", targets: ["CareVoiceCore"])],
    targets: [
        .target(name: "CareVoiceCore", path: "CareVoice/Core"),
        .testTarget(name: "CareVoiceCoreTests", dependencies: ["CareVoiceCore"], path: "Tests/CareVoiceCoreTests")
    ]
)
