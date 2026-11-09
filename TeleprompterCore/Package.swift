// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TeleprompterCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TeleprompterCore", targets: ["TeleprompterCore"])
    ],
    targets: [
        .target(name: "TeleprompterCore"),
        .testTarget(name: "TeleprompterCoreTests", dependencies: ["TeleprompterCore"])
    ]
)
