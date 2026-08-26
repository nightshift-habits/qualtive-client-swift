import XCTest

@testable import Qualtive

final class QuestionFetchTests: XCTestCase {

  func testFetchSuccess() async throws {
    let question = try await Question.fetch(collection: ("ci-test", "swift"))

    XCTAssertEqual(question.id, "swift")
    XCTAssertEqual(question.name, "Swift?")
    XCTAssertEqual(question.content.count, 3)

    if question.content.count >= 1 {
      switch question.content[0] {
      case .score:
        break
      default:
        XCTFail("Expected content 0 to be score")
      }
    }
    if question.content.count >= 2 {
      switch question.content[1] {
      case .title(let content):
        XCTAssertEqual(content.text, "Thoughts on Swift?")
      default:
        XCTFail("Expected content 1 to be title")
      }
    }
    if question.content.count >= 3 {
      switch question.content[2] {
      case .text(let content):
        XCTAssertEqual(content.placeholder, "Write here…")
      default:
        XCTFail("Expected content 2 to be text")
      }
    }
  }

  func testFetchNotFound() async throws {
    do {
      _ = try await Question.fetch(collection: ("ci-test", "not-found"))
    } catch {
      switch error as? Question.FetchError {
      case .notFound:
        return
      default:
        XCTFail("\(error)")
        return
      }
    }

    XCTFail("Expected not found error")
  }

  func testFetchConnectionError() async throws {
    do {
      _ = try await Question.fetch(
        collection: ("ci-test", "not-found"),
        options: .init(_remoteURLString: "https://does-not-exists-qualtive.io/")
      )
    } catch {
      switch error as? Question.FetchError {
      case .general(.connection):
        return
      default:
        XCTFail("\(error)")
        return
      }
    }

    XCTFail("Expected connection error")
  }
}
