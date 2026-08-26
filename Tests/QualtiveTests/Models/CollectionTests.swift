import Testing

@testable import Qualtive

@Suite
struct CollectionTests {

  @Test func `should parse a string literal`() {
    let collection: Collection = "ci-test/swift"
    #expect(collection.containerId == "ci-test")
    #expect(collection.enquiryId == "swift")
  }

  @Test func `should initialize with typed ids`() {
    let collection = Collection(containerId: "ci-test", enquiryId: "swift")
    #expect(collection.containerId.rawValue == "ci-test")
    #expect(collection.enquiryId.rawValue == "swift")
  }

  @Test func `should create enquiry id from integer literal`() {
    let enquiryId: EnquiryId = 6290486614556672
    #expect(enquiryId.rawValue == "6290486614556672")

    let collection = Collection(containerId: "ci-test", enquiryId: 6290486614556672)
    #expect(collection.enquiryId.rawValue == "6290486614556672")
  }

  @Test func `should create enquiry id from string literal`() {
    let enquiryId: EnquiryId = "swift"
    #expect(enquiryId.rawValue == "swift")
  }

  @Test func `should create container id from string literal`() {
    let containerId: ContainerId = "ci-test"
    #expect(containerId.rawValue == "ci-test")
  }

  @Test func `should be hashable`() {
    let a: Collection = "a/b"
    let b: Collection = "a/b"
    let c: Collection = "a/c"
    #expect(a == b)
    #expect(a != c)
  }

  @Test func `should parse a string literal with a separator`() {
    // Exercise the happy path already covered; invalid literals cannot be
    // unit-tested without crashing the process (fatalError by design).
    let collection: Collection = "container/enquiry"
    #expect(collection.containerId.rawValue == "container")
    #expect(collection.enquiryId.rawValue == "enquiry")
  }

  @Test func `should describe typed ids`() {
    #expect(ContainerId("ci-test").description == "ci-test")
    #expect(EnquiryId("swift").description == "swift")
  }

  @Test func `should create enquiry id from a binary integer`() {
    let enquiryId = EnquiryId(UInt64(42))
    #expect(enquiryId.rawValue == "42")
  }
}
