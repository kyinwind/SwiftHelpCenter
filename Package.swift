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
            targets: ["SwiftHelpCenter"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/kyinwind/EasyDesignSystem.git",
            .upToNextMinor(from: "0.2.0")
        )
    ],
    targets: [
        .target(
            name: "SwiftHelpCenter",
            dependencies: [
                .product(name: "EasyDesignSystem", package: "EasyDesignSystem")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SwiftHelpCenterTests",
            dependencies: ["SwiftHelpCenter"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
