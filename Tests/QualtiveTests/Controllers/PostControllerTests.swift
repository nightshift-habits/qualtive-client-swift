import Foundation
import Testing

@testable import Qualtive

@Suite
struct PostControllerTests {

  @Test func `should post an entry`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      #expect(method == "POST")
      #expect(path == "/feedback/entries/")
      #expect(containerId == "ci-test")
      #expect(headers["Content-Type"] == "application/json; charset=utf-8")

      let posted = decodeJSON(PostedEntryBody.self, from: body!)
      #expect(posted.questionId == "swift")
      #expect(posted.content.count == 2)
      #expect(posted.content[0].type == "score")
      #expect(posted.content[0].intValue == 75)
      #expect(posted.content[1].type == "text")
      #expect(posted.content[1].stringValue == "Hello")
      #expect(posted.attributes["Platform"] == "TestOS")
      #expect(posted.attributes["Age"] == "32")
      #expect(posted.user.clientId == "test-client-id")

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

    #expect(entry.id == 123)
  }

  @Test func `should post with a user`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, body in
      let posted = decodeJSON(PostedEntryBody.self, from: body!)
      #expect(posted.user.id == "user-1")
      #expect(posted.user.name == "Ada")
      #expect(posted.user.email == "ada@example.com")
      return (jsonData(EntryIDResponse(id: 5)), makeHTTPURLResponse(statusCode: 200))
    }

    let postController = PostController(
      networkController: mock,
      standardAttributesController: MockStandardAttributesController(attributes: [:]),
      userClientIDController: MockUserClientIDController(clientId: "cid")
    )
    let entry = try await postController.post(
      to: "ci-test/swift",
      content: [.text(.init(value: "Hi"))],
      user: User(id: "user-1", name: "Ada", email: "ada@example.com")
    )
    #expect(entry.id == 5)
  }

  @Test func `should throw when enquiry is not found`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    let postController = PostController(networkController: mock)
    await #expect {
      _ = try await postController.post(
        to: "ci-test/missing",
        content: [.text(.init(value: "Hello"))]
      )
    } throws: { error in
      guard let error = error as? PostController.PostError, case .enquiryNotFound = error else {
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

    let postController = PostController(networkController: mock)
    await #expect {
      _ = try await postController.post(
        to: "ci-test/swift",
        content: [.text(.init(value: "Hello"))]
      )
    } throws: { error in
      guard let error = error as? PostController.PostError, case .network(.connection) = error
      else {
        return false
      }
      return true
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
    let id: String?
    let name: String?
    let email: String?
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
