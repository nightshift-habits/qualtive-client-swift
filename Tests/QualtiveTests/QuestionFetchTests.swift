import XCTest
@testable import Qualtive

final class QuestionFetchTests: XCTestCase {

    static var allTests = [
        ("testFetchSuccess", testFetchSuccess),
        ("testFetchNotFound", testFetchNotFound),
        ("testFetchConnectionError", testFetchConnectionError),
    ]

    func testFetchSuccess() {
        let expectation = self.expectation(description: "Fetch")

        Question.fetch(collection: ("ci-test", "swift")) { result in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let question):
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
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchNotFound() {
        let expectation = self.expectation(description: "Fetch")

        Question.fetch(collection: ("ci-test", "not-found")) { result in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                switch error {
                case .notFound:
                    break
                default:
                    XCTFail("\(error)")
                }
            case .success(let question):
                XCTFail("Expected not found error: \(question)")
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchConnectionError() {
        let expectation = self.expectation(description: "Fetch")

        Question.fetch(collection: ("ci-test", "not-found"), options: .init(_remoteURLString: "https://does-not-exists-qualtive.io/")) { result in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                switch error {
                case .general(.connection):
                    break
                default:
                    XCTFail("\(error)")
                }
            case .success(let question):
                XCTFail("Expected not found error: \(question)")
            }
        }

        waitForExpectations(timeout: 5)
    }
}
