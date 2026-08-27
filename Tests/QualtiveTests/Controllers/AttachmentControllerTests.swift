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
      from: .data(Data([0x89, 0x50]), contentType: .png),
      to: "ci-test"
    )

    #expect(attachment.id == 99)
    #expect(mock.recordedRequests.count == 2)
  }

  @Test func `should create a jpeg attachment`() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { method, path, containerId, headers, body in
      #expect(method == "POST")
      let request = decodeJSON(CreateAttachmentBody.self, from: body!)
      #expect(request.contentType == "image/jpeg")
      return (
        jsonData(CreatedAttachmentBody(id: 3, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { method, url, headers, body in
      #expect(headers["Content-Type"] == "image/jpeg")
      return (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 200))
    }

    let attachment = try await AttachmentController(networkController: mock)
      .create(
        from: .data(Data([0xFF, 0xD8]), contentType: .jpeg),
        to: "ci-test"
      )
    #expect(attachment.id == 3)
  }

  @Test func `should throw when the upload url is invalid`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (
        jsonData(CreatedAttachmentBody(id: 1, uploadUrl: "")),
        makeHTTPURLResponse(statusCode: 200)
      )
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), contentType: .png),
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

  @Test func `should throw when the create step fails`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 503))
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), contentType: .jpeg),
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

  @Test func `should throw remote maintenance when the put step returns 503`() async {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (
        jsonData(CreatedAttachmentBody(id: 1, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { _, _, _, _ in
      (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 503))
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), contentType: .png),
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
        from: .data(Data(), contentType: .png),
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
        from: .data(Data(), contentType: .png),
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

  @Test func `should upload an arbitrary mime type`() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, body in
      let request = decodeJSON(CreateAttachmentBody.self, from: body!)
      #expect(request.contentType == "application/pdf")
      return (
        jsonData(CreatedAttachmentBody(id: 8, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { _, _, headers, body in
      #expect(headers["Content-Type"] == "application/pdf")
      #expect(body == Data([0x25, 0x50, 0x44, 0x46]))
      return (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 200))
    }

    let attachment = try await AttachmentController(networkController: mock)
      .create(
        from: .data(Data([0x25, 0x50, 0x44, 0x46]), contentType: "application/pdf"),
        to: "ci-test"
      )
    #expect(attachment.id == 8)
  }

  @Test func `should upload a file url`() async throws {
    let uploadURL = URL(string: "https://uploads.example/put")!
    let bytes = Data([0x00, 0x01, 0x02])
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("qualtive-upload-\(UUID().uuidString).bin")
    try bytes.write(to: fileURL)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, body in
      let request = decodeJSON(CreateAttachmentBody.self, from: body!)
      #expect(request.contentType == "video/mp4")
      return (
        jsonData(CreatedAttachmentBody(id: 11, uploadUrl: uploadURL.absoluteString)),
        makeHTTPURLResponse(statusCode: 200)
      )
    }
    mock.urlHandler = { _, _, headers, body in
      #expect(headers["Content-Type"] == "video/mp4")
      #expect(body == bytes)
      return (Data(), makeHTTPURLResponse(url: uploadURL, statusCode: 200))
    }

    let attachment = try await AttachmentController(networkController: mock)
      .create(
        from: .file(fileURL, contentType: "video/mp4"),
        to: "ci-test"
      )
    #expect(attachment.id == 11)
  }

  @Test func `should throw when the file url is not a file url`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (
        jsonData(
          CreatedAttachmentBody(id: 1, uploadUrl: "https://uploads.example/put")
        ),
        makeHTTPURLResponse(statusCode: 200)
      )
    }

    let attachmentController = AttachmentController(networkController: mock)
    await #expect {
      _ = try await attachmentController.create(
        from: .file(URL(string: "https://example.com/a.png")!, contentType: .png),
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
}

private struct CreateAttachmentBody: Decodable {
  let contentType: String
}

private struct CreatedAttachmentBody: Encodable {
  let id: UInt64
  let uploadUrl: String
}
