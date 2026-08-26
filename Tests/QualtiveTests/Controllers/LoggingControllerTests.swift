import Foundation
import Testing

@testable import Qualtive

@Suite
struct LoggingControllerTests {

  @Test func `should log a hint for unknown content type`() throws {
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

    #expect(enquiry.pages[0].content.count == 0)
    #expect(loggingController.hintNewVersionCallCount == 1)
  }

  @Test func `should log a hint for unknown score type`() throws {
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

    #expect(enquiry.pages[0].content.count == 0)
    #expect(loggingController.hintNewVersionCallCount == 1)
  }
}

private final class MockLoggingController: LoggingControllerType, @unchecked Sendable {

  private(set) var hintNewVersionCallCount = 0

  func logHintNewVersion() {
    hintNewVersionCallCount += 1
  }
}
