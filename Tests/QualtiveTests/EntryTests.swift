import XCTest
@testable import Qualtive

final class EntryTests: XCTestCase {

    static var allTests = [
        ("testDecode", testDecode),
        ("testDecodeInvalid", testDecodeInvalid),
        ("testDecodeInvalidId", testDecodeInvalidId),
        ("testPostSuccess", testPostSuccess),
        ("testPostNotFound", testPostNotFound),
        ("testPostConnectionError", testPostConnectionError),
    ]

    // MARK: Decode

    func testDecode() throws {
        let result = try Entry(json: [
            "id": NSNumber(value: 123),
        ])
        XCTAssertEqual(result.id, 123)
    }

    func testDecodeInvalid() throws {
        do {
            _ = try Entry(json: [1])
        } catch { return }
        XCTFail("Did not throw")
    }

    func testDecodeInvalidId() throws {
        do {
            _ = try Question(json: [
                "id": "a",
            ])
        } catch { return }
        XCTFail("Did not throw")
    }

    // MARK: Fetch

    func testPostSuccess() {
        let expectation = self.expectation(description: "Post")

        Entry.post(to: ("ci-test", "swift"), content: [
            .score(.init(value: 75)),
            .text(.init(value: "Hello world!")),
        ], user: User(id: "ci-swift"), customAttributes: ["Age": "23"]) { result in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let entry):
                XCTAssertGreaterThan(entry.id, 0)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testPostNotFound() {
        let expectation = self.expectation(description: "Post")

        Entry.post(to: ("ci-test", "not-found"), content: [
            .score(.init(value: 0)),
            .text(.init(value: "Hello world!")),
        ]) { result in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                switch error {
                case .questionNotFound:
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

    func testPostConnectionError() {
        let expectation = self.expectation(description: "Post")

        Entry.post(to: ("ci-test", "not-found"), content: [
            .score(.init(value: 0)),
            .text(.init(value: "Hello world!")),
        ], options: .init(_remoteURLString: "https://does-not-exists.qualtive.io/")) { result in
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
