// swift-tools-version:6.0

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
      dependencies: ["Qualtive"],
      resources: [
        .process("Resources/1px.png"),
        .process("UI/form-takeover.html"),
      ]
    ),
  ]
)
