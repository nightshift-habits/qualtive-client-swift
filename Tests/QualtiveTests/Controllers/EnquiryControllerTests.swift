import Foundation
import Testing

@testable import Qualtive

@Suite
struct EnquiryControllerTests {

  @Test func `should fetch an enquiry`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      #expect(method == "GET")
      #expect(path == "/feedback/enquiries/swift/")
      #expect(containerId == "ci-test")
      #expect(headers["Accept-Language"] == "en-US")
      #expect(body == nil)
      return (
        jsonData(
          [
            "id": 6290486614556672,
            "slug": "swift",
            "name": "Swift?",
            "pages": [
              [
                "content": [
                  ["type": "score", "scoreType": "smilies5"],
                  ["type": "title", "text": "Thoughts on Swift?"],
                  ["type": "text", "placeholder": "Write here…"],
                ]
              ]
            ],
          ] as TestJSON
        ),
        makeHTTPURLResponse(statusCode: 200)
      )
    }

    let enquiryController = EnquiryController(networkController: mock)
    let enquiry = try await enquiryController.fetch(
      collection: "ci-test/swift",
      locale: Locale(identifier: "en_US")
    )

    #expect(enquiry.id == 6290486614556672)
    #expect(enquiry.slug == "swift")
    #expect(enquiry.name == "Swift?")
    #expect(enquiry.pages.count == 1)
    #expect(enquiry.pages[0].content.count == 3)

    if case .score = enquiry.pages[0].content[0] {
    } else {
      Issue.record("Expected score")
    }
    if case .title(let content) = enquiry.pages[0].content[1] {
      #expect(content.text == "Thoughts on Swift?")
    } else {
      Issue.record("Expected title")
    }
    if case .text(let content) = enquiry.pages[0].content[2] {
      #expect(content.placeholder == "Write here…")
    } else {
      Issue.record("Expected text")
    }
  }

  @Test func `should throw when enquiry is not found`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    let enquiryController = EnquiryController(networkController: mock)
    await #expect {
      _ = try await enquiryController.fetch(collection: "ci-test/missing")
    } throws: { error in
      guard let error = error as? EnquiryController.FetchError, case .notFound = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw on connection error`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.notConnectedToInternet)
    }

    let enquiryController = EnquiryController(networkController: mock)
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

  @Test func `should skip unknown content types`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (
        jsonData(
          [
            "id": 1,
            "slug": "swift",
            "name": "Swift?",
            "pages": [
              [
                "content": [
                  ["type": "title", "text": "Hello"],
                  ["type": "future-content-type", "key": 123],
                  ["type": "text", "placeholder": "Write"],
                ]
              ]
            ],
          ] as TestJSON
        ),
        makeHTTPURLResponse(statusCode: 200)
      )
    }

    let enquiryController = EnquiryController(networkController: mock)
    let enquiry = try await enquiryController.fetch(collection: "ci-test/swift")
    #expect(enquiry.pages[0].content.count == 2)
  }
}
