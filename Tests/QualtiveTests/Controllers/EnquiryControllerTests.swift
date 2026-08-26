import XCTest

@testable import Qualtive

final class EnquiryControllerTests: XCTestCase {

  func testFetchSuccess() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      XCTAssertEqual(method, "GET")
      XCTAssertEqual(path, "/feedback/enquiries/swift/")
      XCTAssertEqual(containerId, "ci-test")
      XCTAssertEqual(headers["Accept-Language"], "en-US")
      XCTAssertNil(body)
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

    XCTAssertEqual(enquiry.id, 6290486614556672)
    XCTAssertEqual(enquiry.slug, "swift")
    XCTAssertEqual(enquiry.name, "Swift?")
    XCTAssertEqual(enquiry.pages.count, 1)
    XCTAssertEqual(enquiry.pages[0].content.count, 3)

    switch enquiry.pages[0].content[0] {
    case .score:
      break
    default:
      XCTFail("Expected score")
    }
    switch enquiry.pages[0].content[1] {
    case .title(let content):
      XCTAssertEqual(content.text, "Thoughts on Swift?")
    default:
      XCTFail("Expected title")
    }
    switch enquiry.pages[0].content[2] {
    case .text(let content):
      XCTAssertEqual(content.placeholder, "Write here…")
    default:
      XCTFail("Expected text")
    }
  }

  func testFetchNotFound() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    let enquiryController = EnquiryController(networkController: mock)
    do {
      _ = try await enquiryController.fetch(collection: "ci-test/missing")
      XCTFail("Expected not found")
    } catch let error as EnquiryController.FetchError {
      if case .notFound = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testFetchConnectionError() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.notConnectedToInternet)
    }

    let enquiryController = EnquiryController(networkController: mock)
    do {
      _ = try await enquiryController.fetch(collection: "ci-test/swift")
      XCTFail("Expected connection error")
    } catch let error as EnquiryController.FetchError {
      if case .network(.connection) = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testFetchSkipsUnknownContentType() async throws {
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
    XCTAssertEqual(enquiry.pages[0].content.count, 2)
  }
}
