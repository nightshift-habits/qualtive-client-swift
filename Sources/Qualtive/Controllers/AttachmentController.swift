import Foundation

/// Creates and uploads attachments to qualtive.io.
public protocol AttachmentControllerType: Sendable {

  /// - Throws: `UploadError`, or `CancellationError` when cancelled.
  func create(
    from upload: Attachment.Upload,
    to containerId: ContainerId
  ) async throws -> Attachment
}

/// Live attachment upload controller.
public struct AttachmentController: AttachmentControllerType {

  public enum UploadError: Error {
    case network(NetworkError)
  }

  private let networkController: any NetworkControllerType

  public init() {
    self.init(networkController: NetworkController())
  }

  package init(networkController: some NetworkControllerType) {
    self.networkController = networkController
  }

  public func create(
    from upload: Attachment.Upload,
    to containerId: ContainerId
  ) async throws -> Attachment {
    let contentType: String
    switch upload {
    case .data(_, let kind):
      contentType = kind.mimeType
    }

    let created: CreatedAttachment
    do {
      created = try await networkController.send(
        method: "POST",
        path: "/feedback/attachments/",
        containerId: containerId.rawValue,
        body: CreateAttachmentRequest(contentType: contentType)
      )
    } catch let error as NetworkError {
      throw UploadError.network(error)
    }

    try await uploadBytes(upload, to: created.uploadURL)
    return Attachment(id: created.id)
  }

  private func uploadBytes(
    _ upload: Attachment.Upload,
    to uploadURL: URL
  ) async throws {
    let headers: [String: String]
    let body: Data
    switch upload {
    case .data(let data, let kind):
      headers = ["Content-Type": kind.mimeType]
      body = data
    }

    let response: HTTPURLResponse
    do {
      (_, response) = try await networkController.send(
        method: "PUT",
        url: uploadURL,
        headers: headers,
        body: body
      )
    } catch let error as NetworkError {
      throw UploadError.network(error)
    }

    switch response.statusCode {
    case 200..<300:
      return
    case 503:
      throw UploadError.network(.remoteMaintenance)
    default:
      throw UploadError.network(
        .unexpected(ParseError(debugMessage: "HTTP status code \(response.statusCode)"))
      )
    }
  }
}

private struct CreateAttachmentRequest: Encodable {

  let contentType: String
}

private struct CreatedAttachment: Decodable {

  let id: UInt64
  let uploadURL: URL

  private enum CodingKeys: String, CodingKey {
    case id
    case uploadUrl
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UInt64.self, forKey: .id)
    let uploadURLString = try container.decode(String.self, forKey: .uploadUrl)
    guard let uploadURL = URL(string: uploadURLString) else {
      throw ParseError(debugMessage: "uploadUrl is not a valid url")
    }
    self.uploadURL = uploadURL
  }
}
