import XCTest
@testable import Qualtive

final class QuestionTests: XCTestCase {

    static var allTests = [
        ("testDecodeNoContent", testDecodeNoContent),
        ("testDecodeContentTitle", testDecodeContentTitle),
        ("testDecodeContentScore", testDecodeContentScore),
        ("testDecodeContentText", testDecodeContentText),
        ("testDecodeContentTextNoPlaceholder", testDecodeContentTextNoPlaceholder),
        ("testDecodeContentSelect", testDecodeContentSelect),
        ("testDecodeContentMultiselect", testDecodeContentMultiselect),
        ("testDecodeContentFuture", testDecodeContentFuture),
        ("testDecodeInvalid", testDecodeInvalid),
        ("testDecodeInvalidId", testDecodeInvalidId),
        ("testDecodeInvalidName", testDecodeInvalidName),
        ("testDecodeInvalidContent", testDecodeInvalidContent),
        ("testDecodeInvalidContentType", testDecodeInvalidContentType),
        ("testDecodeInvalidContentTitleText", testDecodeInvalidContentTitleText),
        ("testFetchSuccess", testFetchSuccess),
        ("testFetchNotFound", testFetchNotFound),
        ("testFetchConnectionError", testFetchConnectionError),
    ]

    // MARK: Decode

    func testDecodeNoContent() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 0)
    }

    func testDecodeContentTitle() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "title",
                "text": "Your thoughts?",
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .title(let content):
            XCTAssertEqual(content.text, "Your thoughts?")
        default:
            XCTFail("Expected content to be title: \(content)")
        }
    }

    func testDecodeContentScore() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "score",
                "scoreType": "smilies5",
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .score:
            break
        default:
            XCTFail("Expected content to be score: \(content)")
        }
    }

    func testDecodeContentText() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "text",
                "placeholder": "Write here…",
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .text(let content):
            XCTAssertEqual(content.placeholder, "Write here…")
        default:
            XCTFail("Expected content to be text: \(content)")
        }
    }

    func testDecodeContentTextNoPlaceholder() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "text",
                "placeholder": NSNull(),
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .text(let content):
            XCTAssertNil(content.placeholder)
        default:
            XCTFail("Expected content to be text: \(content)")
        }
    }

    func testDecodeContentSelect() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "select",
                "options": ["A", "B", "C"],
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .select(let content):
            XCTAssertEqual(content.options, ["A", "B", "C"])
        default:
            XCTFail("Expected content to be select: \(content)")
        }
    }

    func testDecodeContentMultiselect() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "multiselect",
                "options": ["1", "2", "3"],
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 1)
        let content = try XCTUnwrap(result.content.first)
        switch content {
        case .multiselect(let content):
            XCTAssertEqual(content.options, ["1", "2", "3"])
        default:
            XCTFail("Expected content to be multiselect: \(content)")
        }
    }

    func testDecodeContentFuture() throws {
        let result = try Question(json: [
            "id": "question-id",
            "name": "Question Name",
            "content": [[
                "type": "future-content-type",
                "key": 123,
            ]],
        ])
        XCTAssertEqual(result.id, "question-id")
        XCTAssertEqual(result.name, "Question Name")
        XCTAssertEqual(result.content.count, 0)
    }

    func testDecodeInvalid() {
        do {
            _ = try Question(json: [1, 2, 3])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidId() {
        do {
            _ = try Question(json: [
                "id": 1,
                "name": "Question Name",
                "content": [],
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidName() {
        do {
            _ = try Question(json: [
                "id": "question-id",
                "name": 1,
                "content": [],
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidContent() {
        do {
            _ = try Question(json: [
                "id": "question-id",
                "name": "Question Name",
                "content": [1, 2, 3],
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidContentType() {
        do {
            _ = try Question(json: [
                "id": "question-id",
                "name": "Question Name",
                "content": [[
                    "type": 1,
                ]],
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidContentTitleText() {
        do {
            _ = try Question(json: [
                "id": "question-id",
                "name": "Question Name",
                "content": [[
                    "type": "title",
                ]],
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    // MARK: Fetch

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
