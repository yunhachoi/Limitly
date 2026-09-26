// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Limitly",
    defaultLocalization: "ko",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "LimitlyCore", targets: ["LimitlyCore"]),
        .executable(name: "Limitly", targets: ["LimitlyApp"])
    ],
    targets: [
        .target(
            name: "LimitlyCore",
            path: "Sources/LimitlyCore"
        ),
        .executableTarget(
            name: "LimitlyApp",
            dependencies: ["LimitlyCore"],
            path: "Sources/LimitlyApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LimitlyCoreTests",
            dependencies: ["LimitlyCore"],
            path: "Tests/LimitlyCoreTests"
        )
    ]
)
