import XCTest
@testable import Qualtive

final class EntryCodingTests: XCTestCase {

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
}
