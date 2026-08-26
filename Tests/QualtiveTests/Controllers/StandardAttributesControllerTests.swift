import Foundation
import Testing

@testable import Qualtive

@Suite
struct StandardAttributesControllerTests {

  @Test func `should include locale in attributes`() async {
    let controller = StandardAttributesController()
    let attributes = await controller.makeAttributes(
      locale: Locale(identifier: "sv_SE")
    )

    #expect(attributes[.language] == "sv")
    #expect(attributes[.region] == "SE")
    #expect(attributes[.os] != nil)
    #expect(attributes[.osVersion] != nil)
    #expect(attributes[.platform] != nil)
  }

  @Test func `should make attributes with the default locale`() async {
    let attributes = await StandardAttributesController().makeAttributes()
    #expect(!attributes.dictionary.isEmpty)
  }
}
