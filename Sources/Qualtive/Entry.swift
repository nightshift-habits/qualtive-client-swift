import Foundation

/// Feedback entry
///
/// Can also be called response or post in some places.
public struct Entry: Sendable {

  /// Uniq id and reference to the entry.
  public let id: UInt64

  // MARK: - JSON

  init(json: Any) throws {
    guard let root = json as? [String: Any] else {
      throw ParseError(debugMessage: "Root object is not object")
    }
    guard let id = root["id"] as? UInt64 else {
      throw ParseError(debugMessage: "Id is not UInt64")
    }

    self.id = id
  }

  // MARK: - Post

  public enum PostError: Error {
    case questionNotFound
    case general(GeneralNetworkError)
  }

  /// Posts an entry to qualtive.io.
  /// - Parameters:
  ///   - collection: Collection to post to.
  ///   - content: Content of the entry.
  ///   - user: Authorized/logged in user that posted the entry.
  ///   - customAttributes: Optional custom attributes to include with the entry.
  ///   - locale: Locale that was used when user entered post. Defaults to the device locale.
  /// - Returns: Newly created entry.
  public static func post(
    to collection: Collection,
    content: [Content],
    user: User = User(),
    customAttributes: [String: String] = [:],
    locale: Locale = .current
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: user,
      customAttributes: customAttributes,
      locale: locale,
      options: .init(_remoteURLString: nil)
    )
  }

  static func post(
    to collection: Collection,
    content: [Content],
    user: User = User(),
    customAttributes: [String: String] = [:],
    locale: Locale = .current,
    options: PrivateOptions
  ) async throws -> Entry {
    var body: [String: Any] = [
      "questionId": collection.questionId,
      "content": content.map { (content) -> Any in
        var raw: [String: Any] = [:]
        switch content {
        case .title(let content):
          raw["type"] = "title"
          raw["text"] = content.text
        case .score(let content):
          raw["type"] = "score"
          if let value = content.value { raw["value"] = value }
          content.definition.kind.json.forEach { (key, value) in
            raw[key] = value
          }
        case .text(let content):
          raw["type"] = "text"
          if let value = content.value { raw["value"] = value }
        case .select(let content):
          raw["type"] = "select"
          if let value = content.value { raw["value"] = value }
        case .multiselect(let content):
          raw["type"] = "multiselect"
          raw["values"] = content.values
        case .attachments(let content):
          raw["type"] = "attachments"
          raw["values"] = content.values.map { ["id": $0.id] }
        }
        return raw
      },
      "attributeHints": [
        "clientLibrary": "swift"
      ],
    ]

    do {
      var rawUser: [String: Any] = [
        "clientId": user.clientId,
        "timeZoneIdentifier": TimeZone.current.identifier,
      ]
      if let value = user.id { rawUser["id"] = value }
      if let value = user.name { rawUser["name"] = value }
      if let value = user.email { rawUser["email"] = value }
      body["user"] = rawUser
    }

    do {
      var attributes = Attributes.defaultAttributes(locale: locale)
      for (key, value) in customAttributes {
        attributes[key] = value
      }
      body["attributes"] = attributes
    }

    var urlComponents = URLComponents(
      string: options._remoteURLString ?? Configuration.remoteURLString
    )!
    urlComponents.path = "/feedback/entries/"

    var urlRequest = URLRequest(
      url: urlComponents.url!,
      cachePolicy: .useProtocolCachePolicy,
      timeoutInterval: 30
    )
    urlRequest.httpMethod = "POST"
    urlRequest.addValue(collection.containerId, forHTTPHeaderField: "X-Container")
    urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body)

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.qualtive.data(for: urlRequest)
    } catch {
      throw mapPostNetworkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw PostError.general(.unexpected(ParseError(debugMessage: "Response is not HTTP")))
    }

    switch httpResponse.statusCode {
    case 200..<300:
      do {
        let json = try JSONSerialization.jsonObject(with: data)
        return try Entry(json: json)
      } catch {
        throw PostError.general(.unexpected(error))
      }
    case 404:
      throw PostError.questionNotFound
    case 503:
      throw PostError.general(.unexpected(UnexpectedError.remoteMaintenance))
    default:
      throw PostError.general(.unexpected(UnexpectedError.httpStatusCode(httpResponse.statusCode)))
    }
  }
}

private func mapPostNetworkError(_ error: Error) -> Entry.PostError {
  if error is CancellationError {
    return .general(.cancelled)
  }
  if let urlError = error as? URLError, urlError.code == .cancelled {
    return .general(.cancelled)
  }
  return .general(.connection(error))
}
