import XCTest

@testable import Qualtive

final class StandardAttributesControllerTests: XCTestCase {

  func testMakeAttributesIncludesLocale() async {
    let controller = StandardAttributesController()
    let attributes = await controller.makeAttributes(
      locale: Locale(identifier: "sv_SE")
    )

    XCTAssertEqual(attributes[.language], "sv")
    XCTAssertEqual(attributes[.region], "SE")
    XCTAssertNotNil(attributes[.os])
    XCTAssertNotNil(attributes[.osVersion])
    XCTAssertNotNil(attributes[.platform])
  }

  func testMakeAttributesDefaultLocale() async {
    let attributes = await StandardAttributesController().makeAttributes()
    XCTAssertFalse(attributes.dictionary.isEmpty)
  }
}
