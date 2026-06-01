// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftHelpCenter",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftHelpCenter",
            targets: ["SwiftHelpCenter", "SHCDesignSystem"]
        ),
    ],
    targets: [
        .target(
            name: "SHCDesignSystem",
            resources: [
                .process("SHCDefaultTheme.json")
            ]
        ),
        .target(
            name: "SwiftHelpCenter",
            dependencies: ["SHCDesignSystem"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SwiftHelpCenterTests",
            dependencies: ["SwiftHelpCenter", "SHCDesignSystem"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
