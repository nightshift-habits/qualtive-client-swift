import XCTest
@testable import Qualtive

final class EntryPostAsyncTests: XCTestCase {

    static var allTests = [
        ("testPostSuccess", testPostSuccess),
        ("testPostNotFound", testPostNotFound),
    ]

    func testPostSuccess() async throws {
        let entry = try await Entry.post(to: ("ci-test", "swift"), content: [
            .score(.init(value: 75)),
            .text(.init(value: "Hello world!")),
            .select(.init(value: "Selected")),
            .multiselect(.init(values: ["Multi 1", "Multi 2"])),
        ], user: User(id: "ci-swift"), customAttributes: ["Age": "23"])

        XCTAssertGreaterThan(entry.id, 0)
    }

    func testPostNotFound() async throws {
        do {
            _ = try await Entry.post(to: ("ci-test", "not-found"), content: [
                .score(.init(value: 0)),
                .text(.init(value: "Hello world!")),
            ])
        } catch {
            switch error as? Entry.PostError {
            case .questionNotFound:
                break
            default:
                XCTFail("\(error)")
            }
            return
        }

        XCTFail("Expected not found error")
    }
}
