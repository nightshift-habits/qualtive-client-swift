import XCTest

@testable import Qualtive

final class PostControllerTests: XCTestCase {

  func testPostSuccess() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      XCTAssertEqual(method, "POST")
      XCTAssertEqual(path, "/feedback/entries/")
      XCTAssertEqual(containerId, "ci-test")
      XCTAssertEqual(headers["Content-Type"], "application/json; charset=utf-8")

      let posted = decodeJSON(PostedEntryBody.self, from: body!)
      XCTAssertEqual(posted.questionId, "swift")
      XCTAssertEqual(posted.content.count, 2)
      XCTAssertEqual(posted.content[0].type, "score")
      XCTAssertEqual(posted.content[0].intValue, 75)
      XCTAssertEqual(posted.content[1].type, "text")
      XCTAssertEqual(posted.content[1].stringValue, "Hello")
      XCTAssertEqual(posted.attributes["Platform"], "TestOS")
      XCTAssertEqual(posted.attributes["Age"], "32")
      XCTAssertEqual(posted.user.clientId, "test-client-id")

      return (jsonData(EntryIDResponse(id: 123)), makeHTTPURLResponse(statusCode: 200))
    }

    let postController = PostController(
      networkController: mock,
      standardAttributesController: MockStandardAttributesController(
        attributes: [.platform: "TestOS"]
      ),
      userClientIDController: MockUserClientIDController(clientId: "test-client-id")
    )
    let entry = try await postController.post(
      to: "ci-test/swift",
      content: [
        .score(.init(value: 75)),
        .text(.init(value: "Hello")),
      ],
      customAttributes: ["Age": "32"]
    )

    XCTAssertEqual(entry.id, 123)
  }

  func testPostEnquiryNotFound() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    let postController = PostController(networkController: mock)
    do {
      _ = try await postController.post(
        to: "ci-test/missing",
        content: [.text(.init(value: "Hello"))]
      )
      XCTFail("Expected enquiry not found")
    } catch let error as PostController.PostError {
      if case .enquiryNotFound = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testPostConnectionError() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.notConnectedToInternet)
    }

    let postController = PostController(networkController: mock)
    do {
      _ = try await postController.post(
        to: "ci-test/swift",
        content: [.text(.init(value: "Hello"))]
      )
      XCTFail("Expected connection error")
    } catch let error as PostController.PostError {
      if case .network(.connection) = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }
}

private struct EntryIDResponse: Encodable {
  let id: UInt64
}

private struct PostedEntryBody: Decodable {
  let questionId: String
  let content: [ContentItem]
  let attributes: [String: String]
  let user: UserBody

  struct UserBody: Decodable {
    let clientId: String
  }

  struct ContentItem: Decodable {
    let type: String
    let value: FlexibleValue?

    var intValue: UInt8? {
      if case .int(let value) = value { return value }
      return nil
    }

    var stringValue: String? {
      if case .string(let value) = value { return value }
      return nil
    }
  }

  enum FlexibleValue: Decodable {
    case int(UInt8)
    case string(String)

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let value = try? container.decode(UInt8.self) {
        self = .int(value)
        return
      }
      self = .string(try container.decode(String.self))
    }
  }
}

private struct MockStandardAttributesController: StandardAttributesControllerType {

  let attributes: Attributes

  func makeAttributes(locale: Locale) async -> Attributes {
    attributes
  }
}

private struct MockUserClientIDController: UserClientIDControllerType {

  let id: String

  init(clientId: String) {
    self.id = clientId
  }

  func clientId() -> String {
    id
  }
}
