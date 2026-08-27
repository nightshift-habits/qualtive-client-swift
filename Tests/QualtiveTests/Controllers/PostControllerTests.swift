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

  @Test func `should post attribute-targeted text as attributes`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, body in
      let posted = decodeJSON(PostedEntryBody.self, from: body!)
      #expect(posted.content.count == 2)
      #expect(posted.content[0].type == "score")
      #expect(posted.content[1].type == "text")
      #expect(posted.content[1].stringValue == "Hello")
      #expect(posted.attributes["Age"] == "32")
      #expect(posted.attributes["Skip"] == nil)
      return (jsonData(EntryIDResponse(id: 1)), makeHTTPURLResponse(statusCode: 200))
    }

    var age = Entry.TextContent(
      enquiryContent: .init(storageTarget: .attribute("Age"))
    )
    age.value = "32"
    var skipped = Entry.TextContent(
      enquiryContent: .init(storageTarget: .attribute("Skip"))
    )
    skipped.value = "   "
    var note = Entry.TextContent(
      enquiryContent: .init(storageTarget: .text)
    )
    note.value = "Hello"

    let postController = PostController(
      networkController: mock,
      standardAttributesController: MockStandardAttributesController(attributes: [:]),
      userClientIDController: MockUserClientIDController(clientId: "cid")
    )
    _ = try await postController.post(
      to: "ci-test/swift",
      content: [
        .score(.init(value: 75)),
        .text(age),
        .text(skipped),
        .text(note),
      ],
      customAttributes: ["Age": "99"]
    )
  }

  @Test func `should omit device attributes and client id when options deny them`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, body in
      let posted = decodeJSON(PostedEntryBody.self, from: body!)
      #expect(posted.attributes["Platform"] == nil)
      #expect(posted.attributes["Age"] == "32")
      #expect(posted.user.clientId == nil)
      return (jsonData(EntryIDResponse(id: 2)), makeHTTPURLResponse(statusCode: 200))
    }

    let attributes = TrackingStandardAttributesController(attributes: [.platform: "TestOS"])
    let clientId = TrackingUserClientIDController(clientId: "should-not-be-used")
    let postController = PostController(
      networkController: mock,
      standardAttributesController: attributes,
      userClientIDController: clientId
    )
    _ = try await postController.post(
      to: "ci-test/swift",
      content: [.text(.init(value: "Hello"))],
      customAttributes: ["Age": "32"],
      options: PostOptions(
        metadataCollection: .none,
        userTrackingConsent: .denied
      )
    )

    #expect(attributes.makeAttributesCallCount == 0)
    #expect(clientId.clientIdCallCount == 0)
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
    let clientId: String?
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

private final class TrackingStandardAttributesController: StandardAttributesControllerType,
  @unchecked Sendable
{

  let attributes: Attributes
  private(set) var makeAttributesCallCount = 0

  init(attributes: Attributes) {
    self.attributes = attributes
  }

  func makeAttributes(locale: Locale) async -> Attributes {
    makeAttributesCallCount += 1
    return attributes
  }
}

private final class TrackingUserClientIDController: UserClientIDControllerType, @unchecked Sendable
{

  let id: String
  private(set) var clientIdCallCount = 0

  init(clientId: String) {
    self.id = clientId
  }

  func clientId() -> String {
    clientIdCallCount += 1
    return id
  }
}
