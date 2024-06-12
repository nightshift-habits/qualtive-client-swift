// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Qualtive",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "Qualtive",
            targets: ["Qualtive"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Qualtive",
            dependencies: []
        ),
        .testTarget(
            name: "QualtiveTests",
            dependencies: ["Qualtive"]
        ),
    ]
)
