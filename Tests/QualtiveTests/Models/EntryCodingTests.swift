import XCTest

@testable import Qualtive

final class EntryCodingTests: XCTestCase {

  func testDecode() throws {
    let result = try JSONDecoder()
      .decode(
        Entry.self,
        from: jsonData(["id": 123] as TestJSON)
      )
    XCTAssertEqual(result.id, 123)
  }

  func testDecodeInvalid() {
    XCTAssertThrowsError(
      try JSONDecoder().decode(Entry.self, from: jsonData([1] as TestJSON))
    )
  }

  func testDecodeInvalidId() {
    XCTAssertThrowsError(
      try JSONDecoder().decode(Entry.self, from: jsonData(["id": "a"] as TestJSON))
    )
  }
}
