import XCTest

@testable import Qualtive

final class EntryPostIntegrationTests: XCTestCase {

  func testPostSuccess() async throws {
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

    XCTAssertGreaterThan(entry.id, 0)
  }

  func testPostNotFound() async throws {
    do {
      _ = try await PostController()
        .post(
          to: "ci-test/not-found",
          content: [
            .score(.init(value: 0)),
            .text(.init(value: "Hello world!")),
          ]
        )
      XCTFail("Expected not found error")
    } catch let error as PostController.PostError {
      if case .enquiryNotFound = error {
        return
      }
      XCTFail("\(error)")
    }
  }

  func testPostConnectionError() async throws {
    let postController = PostController(
      networkController: NetworkController(
        baseURL: URL(string: "https://does-not-exists-qualtive.io/")!
      )
    )
    do {
      _ = try await postController.post(
        to: "ci-test/swift",
        content: [
          .score(.init(value: 0)),
          .text(.init(value: "Hello world!")),
        ]
      )
      XCTFail("Expected connection error")
    } catch let error as PostController.PostError {
      if case .network(.connection) = error {
        return
      }
      XCTFail("\(error)")
    }
  }
}
