import XCTest

@testable import Qualtive

final class EnquiryFetchIntegrationTests: XCTestCase {

  func testFetchSuccess() async throws {
    let enquiry = try await EnquiryController().fetch(collection: "ci-test/swift")

    XCTAssertEqual(enquiry.slug, "swift")
    XCTAssertGreaterThan(enquiry.id, 0)
    XCTAssertFalse(enquiry.pages.isEmpty)
  }

  func testFetchNotFound() async throws {
    do {
      _ = try await EnquiryController().fetch(collection: "ci-test/not-found")
      XCTFail("Expected not found error")
    } catch let error as EnquiryController.FetchError {
      if case .notFound = error {
        return
      }
      XCTFail("\(error)")
    }
  }

  func testFetchConnectionError() async throws {
    let enquiryController = EnquiryController(
      networkController: NetworkController(
        baseURL: URL(string: "https://does-not-exists-qualtive.io/")!
      )
    )
    do {
      _ = try await enquiryController.fetch(collection: "ci-test/swift")
      XCTFail("Expected connection error")
    } catch let error as EnquiryController.FetchError {
      if case .network(.connection) = error {
        return
      }
      XCTFail("\(error)")
    }
  }
}
