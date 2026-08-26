import Foundation

public struct Attachment: Sendable {

  /// Uniq identifier.
  public let id: UInt64

  // MARK: - JSON

  init(json: [String: Any]) throws {
    guard let id = json["id"] as? UInt64 else {
      throw ParseError(debugMessage: "Id is not UInt64")
    }

    self.id = id
  }

  // MARK: - Upload

  public enum Upload: Sendable {
    case data(Data, kind: Kind)

    public enum Kind: Sendable {
      case png
      case jpeg

      fileprivate var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        }
      }
    }
  }

  public enum UploadError: Error {
    case general(GeneralNetworkError)
  }

  public static func create(
    from upload: Upload,
    to containerId: String
  ) async throws -> Attachment {
    var urlComponents = URLComponents(string: Configuration.remoteURLString)!
    urlComponents.path = "/feedback/attachments/"

    var urlRequest = URLRequest(
      url: urlComponents.url!,
      cachePolicy: .useProtocolCachePolicy,
      timeoutInterval: 30
    )
    urlRequest.httpMethod = "POST"

    let body: [String: Any]
    switch upload {
    case .data(_, let kind):
      body = [
        "contentType": kind.mimeType
      ]
    }

    urlRequest.addValue(containerId, forHTTPHeaderField: "X-Container")
    urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body)

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.qualtive.data(for: urlRequest)
    } catch {
      throw mapUploadNetworkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw UploadError.general(.unexpected(ParseError(debugMessage: "Response is not HTTP")))
    }

    switch httpResponse.statusCode {
    case 200..<300:
      do {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any] else {
          throw ParseError(debugMessage: "Root object is not object")
        }
        guard let uploadURLString = root["uploadUrl"] as? String else {
          throw ParseError(debugMessage: "uploadUrl is not a string")
        }
        guard let uploadURL = URL(string: uploadURLString) else {
          throw ParseError(debugMessage: "uploadUrl is not a valid url")
        }

        let result = try Attachment(json: root)
        try await result.update(from: upload, uploadURL: uploadURL)
        return result
      } catch let error as UploadError {
        throw error
      } catch {
        throw UploadError.general(.unexpected(error))
      }
    case 503:
      throw UploadError.general(.unexpected(UnexpectedError.remoteMaintenance))
    default:
      throw UploadError.general(
        .unexpected(UnexpectedError.httpStatusCode(httpResponse.statusCode))
      )
    }
  }

  private func update(
    from upload: Upload,
    uploadURL: URL
  ) async throws {
    var urlRequest = URLRequest(
      url: uploadURL,
      cachePolicy: .useProtocolCachePolicy,
      timeoutInterval: 30
    )
    urlRequest.httpMethod = "PUT"

    switch upload {
    case .data(let data, let kind):
      urlRequest.addValue(kind.mimeType, forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = data
    }

    let response: URLResponse
    do {
      (_, response) = try await URLSession.qualtive.data(for: urlRequest)
    } catch {
      throw mapUploadNetworkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw UploadError.general(.unexpected(ParseError(debugMessage: "Response is not HTTP")))
    }

    switch httpResponse.statusCode {
    case 200..<300:
      return
    case 503:
      throw UploadError.general(.unexpected(UnexpectedError.remoteMaintenance))
    default:
      throw UploadError.general(
        .unexpected(UnexpectedError.httpStatusCode(httpResponse.statusCode))
      )
    }
  }
}

private func mapUploadNetworkError(_ error: Error) -> Attachment.UploadError {
  if error is CancellationError {
    return .general(.cancelled)
  }
  if let urlError = error as? URLError, urlError.code == .cancelled {
    return .general(.cancelled)
  }
  return .general(.connection(error))
}
