import XCTest

@testable import Qualtive

final class CollectionTests: XCTestCase {

  func testStringLiteral() {
    let collection: Collection = "ci-test/swift"
    XCTAssertEqual(collection.containerId, "ci-test")
    XCTAssertEqual(collection.enquiryId, "swift")
  }

  func testInitWithTypedIds() {
    let collection = Collection(containerId: "ci-test", enquiryId: "swift")
    XCTAssertEqual(collection.containerId.rawValue, "ci-test")
    XCTAssertEqual(collection.enquiryId.rawValue, "swift")
  }

  func testEnquiryIdFromIntegerLiteral() {
    let enquiryId: EnquiryId = 6290486614556672
    XCTAssertEqual(enquiryId.rawValue, "6290486614556672")

    let collection = Collection(containerId: "ci-test", enquiryId: 6290486614556672)
    XCTAssertEqual(collection.enquiryId.rawValue, "6290486614556672")
  }

  func testEnquiryIdFromStringLiteral() {
    let enquiryId: EnquiryId = "swift"
    XCTAssertEqual(enquiryId.rawValue, "swift")
  }

  func testContainerIdFromStringLiteral() {
    let containerId: ContainerId = "ci-test"
    XCTAssertEqual(containerId.rawValue, "ci-test")
  }

  func testHashable() {
    let a: Collection = "a/b"
    let b: Collection = "a/b"
    let c: Collection = "a/c"
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func testStringLiteralRequiresSeparator() {
    // Exercise the happy path already covered; invalid literals cannot be
    // unit-tested without crashing the process (fatalError by design).
    let collection: Collection = "container/enquiry"
    XCTAssertEqual(collection.containerId.rawValue, "container")
    XCTAssertEqual(collection.enquiryId.rawValue, "enquiry")
  }
}
