import XCTest

@testable import Qualtive

final class AttributesTests: XCTestCase {

  func testDictionaryLiteralWithTypedKeys() {
    let attributes: Attributes = [
      .platform: "iOS",
      "Age": "32",
    ]

    XCTAssertEqual(attributes[.platform], "iOS")
    XCTAssertEqual(attributes["Age"], "32")
    XCTAssertEqual(attributes[.appId], nil)
  }

  func testInitFromStringDictionary() {
    let attributes = Attributes(["Platform": "macOS", "Region": "SE"])
    XCTAssertEqual(attributes[.platform], "macOS")
    XCTAssertEqual(attributes[.region], "SE")
    XCTAssertEqual(
      attributes.dictionary,
      ["Platform": "macOS", "Region": "SE"]
    )
  }

  func testInitFromKeyedDictionary() {
    let attributes = Attributes([
      .os: "iOS",
      .language: "en",
    ])
    XCTAssertEqual(attributes[.os], "iOS")
    XCTAssertEqual(attributes[.language], "en")
  }

  func testSubscriptSet() {
    var attributes = Attributes()
    attributes[.deviceType] = "Phone"
    attributes["Custom"] = "Value"
    XCTAssertEqual(attributes[.deviceType], "Phone")
    XCTAssertEqual(attributes["Custom"], "Value")
  }

  func testMergeReplacesExistingKeys() {
    var attributes: Attributes = [.platform: "iOS", "Age": "30"]
    attributes.merge([.platform: "macOS", "Age": "32", .region: "SE"])
    XCTAssertEqual(attributes[.platform], "macOS")
    XCTAssertEqual(attributes["Age"], "32")
    XCTAssertEqual(attributes[.region], "SE")
  }

  func testMergingReturnsCopy() {
    let attributes: Attributes = [.os: "iOS"]
    let merged = attributes.merging(["Age": "23"])
    XCTAssertEqual(attributes.dictionary, ["OS": "iOS"])
    XCTAssertEqual(merged.dictionary, ["OS": "iOS", "Age": "23"])
  }

  func testKeyExpressibleByStringLiteral() {
    let key: Attributes.Key = "Custom Key"
    XCTAssertEqual(key.rawValue, "Custom Key")
    XCTAssertEqual(Attributes.Key.platform.rawValue, "Platform")
  }
}
