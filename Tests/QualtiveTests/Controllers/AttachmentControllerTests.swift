import Foundation
import Testing

@testable import Qualtive

@Suite
struct AttachmentControllerTests {

  @Test func `should create an attachment`() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      #expect(method == "POST")
      #expect(path == "/feedback/attachments/")
      #expect(containerId == "ci-test")
      let request = decodeJSON(CreateAttachmentBody.self, from: body!)
      #expect(request.contentType == "image/png")
      return (
        jsonData(CreatedAttachmentBody(id: 99, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { method, url, headers, body in
      #expect(method == "PUT")
      #expect(url == uploadURL)
      #expect(headers["Content-Type"] == "image/png")
      #expect(body == Data([0x89, 0x50]))
      return (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 200))
    }

    let attachmentController = AttachmentController(networkController: mock)
    let attachment = try await attachmentController.create(
      from: .data(Data([0x89, 0x50]), kind: .png),
      to: "ci-test"
    )

    #expect(attachment.id == 99)
    #expect(mock.recordedRequests.count == 2)
  }

  @Test func `should throw when the create step fails`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 503))
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .jpeg),
        to: "ci-test"
      )
    } throws: { error in
      guard let error = error as? AttachmentController.UploadError,
        case .network(.remoteMaintenance) = error
      else {
        return false
      }
      return true
    }
  }

  @Test func `should throw when the put step fails`() async {
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
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .png),
        to: "ci-test"
      )
    } throws: { error in
      guard let error = error as? AttachmentController.UploadError,
        case .network(.unexpected) = error
      else {
        return false
      }
      return true
    }
  }

  @Test func `should throw on connection error`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.timedOut)
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .png),
        to: "ci-test"
      )
    } throws: { error in
      guard let error = error as? AttachmentController.UploadError,
        case .network(.connection) = error
      else {
        return false
      }
      return true
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
