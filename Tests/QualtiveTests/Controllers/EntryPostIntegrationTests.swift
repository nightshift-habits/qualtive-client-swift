import Foundation
import Testing

@testable import Qualtive

@Suite
struct EntryPostIntegrationTests {

  @Test func `should post an entry`() async throws {
    let entry = try await PostController()
      .post(
        to: "ci-test/swift",
        content: [
          .score(.init(value: 75)),
          .text(.init(value: "Hello world!")),
          .select(.init(value: "Selected")),
          .multiselect(.init(values: ["Multi 1", "Multi 2"])),
        ],
        user: User(id: "ci-swift"),
        customAttributes: ["Age": "23"]
      )

    #expect(entry.id > 0)
  }

  @Test func `should post an entry with a workspace`() async throws {
    let entry = try await PostController()
      .post(
        to: "ci-test/ci-test-2/swift-2",
        content: [
          .score(.init(value: 75)),
          .text(.init(value: "Hello world!")),
          .select(.init(value: "Selected")),
          .multiselect(.init(values: ["Multi 1", "Multi 2"])),
        ],
        user: User(id: "ci-swift"),
        customAttributes: ["Age": "23"]
      )

    #expect(entry.id > 0)
  }

  @Test func `should throw when enquiry is not found`() async {
    await #expect {
      _ = try await PostController()
        .post(
          to: "ci-test/not-found",
          content: [
            .score(.init(value: 0)),
            .text(.init(value: "Hello world!")),
          ]
        )
    } throws: { error in
      guard let error = error as? PostController.PostError, case .enquiryNotFound = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw on connection error`() async {
    let postController = PostController(
      networkController: NetworkController(
        baseURL: URL(string: "https://does-not-exists-qualtive.io/")!
      )
    )
    await #expect {
      _ = try await postController.post(
        to: "ci-test/swift",
        content: [
          .score(.init(value: 0)),
          .text(.init(value: "Hello world!")),
        ]
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
