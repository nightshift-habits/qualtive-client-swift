// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "Qualtive",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8),
  ],
  products: [
    .library(
      name: "Qualtive",
      targets: ["Qualtive"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Qualtive",
      dependencies: [],
      resources: [
        .process("Resources/PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "QualtiveTests",
      dependencies: ["Qualtive"]
    ),
  ]
)
