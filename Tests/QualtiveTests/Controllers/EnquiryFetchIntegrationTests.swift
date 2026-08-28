import Foundation
import Testing

@testable import Qualtive

@Suite
struct EnquiryFetchIntegrationTests {

  @Test func `should fetch an enquiry`() async throws {
    let enquiry = try await EnquiryController().fetch(collection: "ci-test/swift")

    #expect(enquiry.slug == "swift")
    #expect(enquiry.id > 0)
    #expect(!enquiry.pages.isEmpty)
    #expect(!enquiry.submittedPages.isEmpty)
    #expect(enquiry.container.id == "ci-test")
    #expect(enquiry.theme.cornerStyle == .rounded || enquiry.theme.cornerStyle == .square)
  }

  @Test func `should fetch an enquiry with a workspace`() async throws {
    let enquiry = try await EnquiryController().fetch(collection: "ci-test/ci-test-2/swift-2")

    #expect(enquiry.slug == "swift-2")
    #expect(enquiry.id > 0)
    #expect(!enquiry.pages.isEmpty)
    #expect(!enquiry.submittedPages.isEmpty)
    #expect(enquiry.container.id == "ci-test")
    #expect(enquiry.theme.cornerStyle == .rounded || enquiry.theme.cornerStyle == .square)
  }

  @Test func `should throw when enquiry is not found`() async {
    await #expect {
      _ = try await EnquiryController().fetch(collection: "ci-test/not-found")
    } throws: { error in
      guard let error = error as? EnquiryController.FetchError, case .notFound = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw on connection error`() async {
    let enquiryController = EnquiryController(
      networkController: NetworkController(
        baseURL: URL(string: "https://does-not-exists-qualtive.io/")!
      )
    )
    await #expect {
      _ = try await enquiryController.fetch(collection: "ci-test/swift")
    } throws: { error in
      guard let error = error as? EnquiryController.FetchError, case .network(.connection) = error
      else {
        return false
      }
      return true
    }
  }
}
