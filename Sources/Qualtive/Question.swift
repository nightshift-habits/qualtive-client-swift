import Foundation

/// Question defined on Qualtive on how an created entry's content should be defined.
public struct Question: Sendable {

  /// Identifier of the question. Can also be used as a slug.
  public let id: String

  /// Name of the question.
  public let name: String

  /// Content and struction of the question.
  public let content: [Content]

  /// Creates default/empty array of entry content; ready to be filled out by user.
  /// - Returns: Array of entry content without any pre-defined values.
  ///
  /// Note: This method only maps the question content to entry content. It is safe to asume the length of booth content will always be equal.
  public func entryContentTemplate() -> [Entry.Content] {
    content.map {
      switch $0 {
      case .title(let content): return Entry.Content.title(.init(questionContent: content))
      case .score(let content): return Entry.Content.score(.init(questionContent: content))
      case .text(let content): return Entry.Content.text(.init(questionContent: content))
      case .select(let content): return Entry.Content.select(.init(questionContent: content))
      case .multiselect(let content):
        return Entry.Content.multiselect(.init(questionContent: content))
      case .attachments(let content):
        return Entry.Content.attachments(.init(questionContent: content))
      }
    }
  }

  // MARK: - JSON

  init(json: Any) throws {
    guard let root = json as? [String: Any] else {
      throw ParseError(debugMessage: "Root object is not object")
    }
    guard let id = root["id"] as? String else {
      throw ParseError(debugMessage: "Id is not string")
    }
    guard let name = root["name"] as? String else {
      throw ParseError(debugMessage: "Name is not string")
    }
    guard let rawContent = root["content"] as? [[String: Any]] else {
      throw ParseError(debugMessage: "Content is not array of objects")
    }

    self.id = id
    self.name = name
    self.content = try rawContent.compactMap { try Content(json: $0) }
  }

  // MARK: - Fetch

  public enum FetchError: Error {
    case notFound
    case general(GeneralNetworkError)
  }

  /// Fetch a question and it's definition from qualtive.io.
  /// - Parameters:
  ///   - collection: The collection identifier for the question.
  ///   - locale: The locale to use for question. If the question is translated on Qualtive this specified which translation to use for localizable fields. Defaults to device locale.
  /// - Returns: Question definition.
  public static func fetch(
    collection: Collection,
    locale: Locale = .current
  ) async throws -> Question {
    try await fetch(
      collection: collection,
      options: .init(_remoteURLString: nil),
      locale: locale
    )
  }

  static func fetch(
    collection: Collection,
    options: PrivateOptions,
    locale: Locale = .current
  ) async throws -> Question {
    var urlComponents = URLComponents(
      string: options._remoteURLString ?? Configuration.remoteURLString
    )!
    urlComponents.path = "/feedback/questions/\(collection.questionId)/"

    var urlRequest = URLRequest(
      url: urlComponents.url!,
      cachePolicy: .useProtocolCachePolicy,
      timeoutInterval: 30
    )
    urlRequest.httpMethod = "GET"
    urlRequest.addValue(collection.containerId, forHTTPHeaderField: "X-Container")
    urlRequest.addValue(
      locale.identifier.replacingOccurrences(of: "_", with: "-"),
      forHTTPHeaderField: "Accept-Language"
    )

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.qualtive.data(for: urlRequest)
    } catch {
      throw mapFetchNetworkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw FetchError.general(.unexpected(ParseError(debugMessage: "Response is not HTTP")))
    }

    switch httpResponse.statusCode {
    case 200..<300:
      do {
        let json = try JSONSerialization.jsonObject(with: data)
        return try Question(json: json)
      } catch {
        throw FetchError.general(.unexpected(error))
      }
    case 404:
      throw FetchError.notFound
    case 503:
      throw FetchError.general(.unexpected(UnexpectedError.remoteMaintenance))
    default:
      throw FetchError.general(.unexpected(UnexpectedError.httpStatusCode(httpResponse.statusCode)))
    }
  }
}

private func mapFetchNetworkError(_ error: Error) -> Question.FetchError {
  if error is CancellationError {
    return .general(.cancelled)
  }
  if let urlError = error as? URLError, urlError.code == .cancelled {
    return .general(.cancelled)
  }
  return .general(.connection(error))
}
