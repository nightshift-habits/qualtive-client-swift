import Foundation
import Testing

@testable import Qualtive

@Suite
struct AttributesTests {

  @Test func `should support dictionary literal with typed keys`() {
    let attributes: Attributes = [
      .platform: "iOS",
      "Age": "32",
    ]

    #expect(attributes[.platform] == "iOS")
    #expect(attributes["Age"] == "32")
    #expect(attributes[.appId] == nil)
  }

  @Test func `should initialize from a string dictionary`() {
    let attributes = Attributes(["Platform": "macOS", "Region": "SE"])
    #expect(attributes[.platform] == "macOS")
    #expect(attributes[.region] == "SE")
    #expect(
      attributes.dictionary
        == ["Platform": "macOS", "Region": "SE"]
    )
  }

  @Test func `should initialize from a keyed dictionary`() {
    let attributes = Attributes([
      .os: "iOS",
      .language: "en",
    ])
    #expect(attributes[.os] == "iOS")
    #expect(attributes[.language] == "en")
  }

  @Test func `should set values via subscript`() {
    var attributes = Attributes()
    attributes[.deviceType] = "Phone"
    attributes["Custom"] = "Value"
    #expect(attributes[.deviceType] == "Phone")
    #expect(attributes["Custom"] == "Value")
  }

  @Test func `should replace existing keys when merging`() {
    var attributes: Attributes = [.platform: "iOS", "Age": "30"]
    attributes.merge([.platform: "macOS", "Age": "32", .region: "SE"])
    #expect(attributes[.platform] == "macOS")
    #expect(attributes["Age"] == "32")
    #expect(attributes[.region] == "SE")
  }

  @Test func `should return a copy when merging`() {
    let attributes: Attributes = [.os: "iOS"]
    let merged = attributes.merging(["Age": "23"])
    #expect(attributes.dictionary == ["OS": "iOS"])
    #expect(merged.dictionary == ["OS": "iOS", "Age": "23"])
  }

  @Test func `should express keys as string literals`() {
    let key: Attributes.Key = "Custom Key"
    #expect(key.rawValue == "Custom Key")
    #expect(Attributes.Key.platform.rawValue == "Platform")
  }

  @Test func `should initialize keys from raw values`() {
    #expect(Attributes.Key(rawValue: "Foo").rawValue == "Foo")
    #expect(Attributes.Key("Bar").rawValue == "Bar")
    #expect(Attributes.Key("Baz").description == "Baz")
  }

  @Test func `should encode as a string dictionary`() throws {
    let attributes: Attributes = [.platform: "iOS", "Age": "32"]
    let encoded = try JSONDecoder()
      .decode(
        [String: String].self,
        from: JSONEncoder().encode(attributes)
      )
    #expect(encoded == ["Platform": "iOS", "Age": "32"])
  }
}
