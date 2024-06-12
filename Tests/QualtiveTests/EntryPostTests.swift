import XCTest
@testable import Qualtive

final class EntryPostTests: XCTestCase {

    func testPostSuccess() {
        let expectation = self.expectation(description: "Post")

        Entry.post(to: ("ci-test", "swift"), content: [
            .score(.init(value: 75)),
            .text(.init(value: "Hello world!")),
            .select(.init(value: "Selected")),
            .multiselect(.init(values: ["Multi 1", "Multi 2"])),
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
        ], options: .init(_remoteURLString: "https://does-not-exists-qualtive.io/")) { result in
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
                XCTFail("Expected not general connection error: \(question)")
            }
        }

        waitForExpectations(timeout: 5)
    }
}
