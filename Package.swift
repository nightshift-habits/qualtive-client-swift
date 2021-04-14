// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Qualtive",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2),
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
