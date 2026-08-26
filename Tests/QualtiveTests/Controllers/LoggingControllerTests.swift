import XCTest

@testable import Qualtive

final class LoggingControllerTests: XCTestCase {

  func testUnknownContentTypeLogsHint() throws {
    let loggingController = MockLoggingController()
    let decoder = JSONDecoder()
    decoder.userInfo[CodingUserInfoKey.loggingController] = loggingController

    let enquiry = try decoder.decode(
      Enquiry.self,
      from: jsonData(
        [
          "id": 1,
          "slug": "slug",
          "name": "Name",
          "pages": [
            [
              "content": [
                ["type": "future-content-type", "key": 123]
              ]
            ]
          ],
        ] as TestJSON
      )
    )

    XCTAssertEqual(enquiry.pages[0].content.count, 0)
    XCTAssertEqual(loggingController.hintNewVersionCallCount, 1)
  }

  func testUnknownScoreTypeLogsHint() throws {
    let loggingController = MockLoggingController()
    let decoder = JSONDecoder()
    decoder.userInfo[CodingUserInfoKey.loggingController] = loggingController

    let enquiry = try decoder.decode(
      Enquiry.self,
      from: jsonData(
        [
          "id": 1,
          "slug": "slug",
          "name": "Name",
          "pages": [
            [
              "content": [
                ["type": "score", "scoreType": "future-score"]
              ]
            ]
          ],
        ] as TestJSON
      )
    )

    XCTAssertEqual(enquiry.pages[0].content.count, 0)
    XCTAssertEqual(loggingController.hintNewVersionCallCount, 1)
  }
}

private final class MockLoggingController: LoggingControllerType, @unchecked Sendable {

  private(set) var hintNewVersionCallCount = 0

  func logHintNewVersion() {
    hintNewVersionCallCount += 1
  }
}
