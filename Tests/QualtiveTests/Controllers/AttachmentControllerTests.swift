import XCTest

@testable import Qualtive

final class AttachmentControllerTests: XCTestCase {

  func testCreateSuccess() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      XCTAssertEqual(method, "POST")
      XCTAssertEqual(path, "/feedback/attachments/")
      XCTAssertEqual(containerId, "ci-test")
      let request = decodeJSON(CreateAttachmentBody.self, from: body!)
      XCTAssertEqual(request.contentType, "image/png")
      return (
        jsonData(CreatedAttachmentBody(id: 99, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { method, url, headers, body in
      XCTAssertEqual(method, "PUT")
      XCTAssertEqual(url, uploadURL)
      XCTAssertEqual(headers["Content-Type"], "image/png")
      XCTAssertEqual(body, Data([0x89, 0x50]))
      return (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 200))
    }

    let attachmentController = AttachmentController(networkController: mock)
    let attachment = try await attachmentController.create(
      from: .data(Data([0x89, 0x50]), kind: .png),
      to: "ci-test"
    )

    XCTAssertEqual(attachment.id, 99)
    XCTAssertEqual(mock.recordedRequests.count, 2)
  }

  func testCreateCreateStepFailure() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 503))
    }

    let attachmentController = AttachmentController(networkController: mock)
    do {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .jpeg),
        to: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as AttachmentController.UploadError {
      if case .network(.remoteMaintenance) = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCreatePutFailure() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (
        jsonData(CreatedAttachmentBody(id: 1, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { _, _, _, _ in
      (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 500))
    }

    let attachmentController = AttachmentController(networkController: mock)
    do {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .png),
        to: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as AttachmentController.UploadError {
      if case .network(.unexpected) = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCreateConnectionError() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.timedOut)
    }

    let attachmentController = AttachmentController(networkController: mock)
    do {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .png),
        to: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as AttachmentController.UploadError {
      if case .network(.connection) = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }
}

private struct CreateAttachmentBody: Decodable {
  let contentType: String
}

private struct CreatedAttachmentBody: Encodable {
  let id: UInt64
  let uploadUrl: String
}
