import XCTest
@testable import Qualtive

@available(iOS 13.0, tvOS 13.0, *)
final class QuestionFetchAsyncTests: XCTestCase {

    static var allTests = [
        ("testFetchSuccess", testFetchSuccess),
        ("testFetchNotFound", testFetchNotFound),
    ]

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
            case .text(let content):
                XCTAssertEqual(content.placeholder, "Write here…")
            default:
                XCTFail("Expected content 0 to be text")
            }
        }
        if question.content.count >= 3 {
            switch question.content[2] {
            case .title(let content):
                XCTAssertEqual(content.text, "Thoughts on Swift?")
            default:
                XCTFail("Expected content 0 to be title")
            }
        }
    }

    func testFetchNotFound() async throws {
        do {
            _ = try await Question.fetch(collection: ("ci-test", "not-found"))
        } catch {
            switch error as? Question.FetchError {
            case .notFound:
                break
            default:
                XCTFail("\(error)")
            }
            return
        }

        XCTFail("Expected not found error")
    }
}
