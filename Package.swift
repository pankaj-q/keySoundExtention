// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "keySoundExtension",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "keySoundExtension",
            resources: [.process("Resources")]
        )
    ]
)
