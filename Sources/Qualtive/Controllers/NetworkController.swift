import Foundation

/// Network failure thrown by `NetworkController` and wrapped by higher-level controller errors.
public enum NetworkError: Error, Sendable {

  /// A connection failure (e.g. no internet), or another transport-level error.
  case connection(Error)

  /// Resource was not found (HTTP 404).
  case notFound

  /// Qualtive servers are currently undergoing maintenance (HTTP 503).
  case remoteMaintenance

  /// Unexpected error. This should never happen in normal operation.
  case unexpected(Error)
}

package protocol NetworkControllerType: Sendable {

  /// Performs an HTTP request against a path relative to the controller's base URL.
  ///
  /// Throws `NetworkError`, or `CancellationError` when the task/request is cancelled.
  func send(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse)

  /// Performs an HTTP request against an absolute URL (e.g. attachment upload).
  ///
  /// Throws `NetworkError`, or `CancellationError` when the task/request is cancelled.
  func send(
    method: String,
    url: URL,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse)

  /// Performs an HTTP request against an absolute URL, streaming the body from a local file.
  ///
  /// Throws `NetworkError`, or `CancellationError` when the task/request is cancelled.
  func send(
    method: String,
    url: URL,
    headers: [String: String],
    fileURL: URL
  ) async throws -> (Data, HTTPURLResponse)
}

extension NetworkControllerType {

  package func send(
    method: String,
    url: URL,
    headers: [String: String],
    fileURL: URL
  ) async throws -> (Data, HTTPURLResponse) {
    let body: Data
    do {
      body = try Data(contentsOf: fileURL)
    } catch {
      throw NetworkError.connection(error)
    }
    return try await send(
      method: method,
      url: url,
      headers: headers,
      body: body
    )
  }
}

extension NetworkControllerType {

  /// Sends a request and decodes a JSON response body on success.
  func send<Response: Decodable>(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String] = [:],
    body: Data? = nil
  ) async throws -> Response {
    try await sendAndDecode(
      method: method,
      path: path,
      containerId: containerId,
      headers: headers,
      body: body
    )
  }

  /// Encodes `body` as JSON, sends the request, and decodes a JSON response on success.
  func send<Response: Decodable, Body: Encodable>(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String] = [:],
    body: Body
  ) async throws -> Response {
    var headers = headers
    if headers["Content-Type"] == nil {
      headers["Content-Type"] = "application/json; charset=utf-8"
    }
    let bodyData: Data
    do {
      bodyData = try JSONEncoder().encode(body)
    } catch {
      throw NetworkError.unexpected(error)
    }
    // Must not call the Encodable overload again — `Data` is Encodable.
    return try await sendAndDecode(
      method: method,
      path: path,
      containerId: containerId,
      headers: headers,
      body: bodyData
    )
  }

  private func sendAndDecode<Response: Decodable>(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String],
    body: Data?
  ) async throws -> Response {
    let data: Data
    let response: HTTPURLResponse
    do {
      (data, response) = try await send(
        method: method,
        path: path,
        containerId: containerId,
        headers: headers,
        body: body
      )
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as NetworkError {
      throw error
    } catch {
      try mapNetworkTransportError(error)
    }

    switch response.statusCode {
    case 200..<300:
      do {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.loggingController] = LoggingController()
        return try decoder.decode(Response.self, from: data)
      } catch {
        throw NetworkError.unexpected(error)
      }
    case 404:
      throw NetworkError.notFound
    case 503:
      throw NetworkError.remoteMaintenance
    default:
      throw NetworkError.unexpected(
        ParseError(debugMessage: "HTTP status code \(response.statusCode)")
      )
    }
  }
}

package struct NetworkController: NetworkControllerType {

  private let urlSession: URLSession
  private let baseURL: URL

  package init() {
    self.init(
      urlSession: .shared,
      baseURL: URL(string: "https://user-api.qualtive.io/")!
    )
  }

  package init(baseURL: URL) {
    self.init(urlSession: .shared, baseURL: baseURL)
  }

  package init(urlSession: URLSession, baseURL: URL) {
    self.urlSession = urlSession
    self.baseURL = baseURL
  }

  package func send(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse) {
    let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
    let url = URL(string: relativePath, relativeTo: baseURL)!.absoluteURL

    var requestHeaders = headers
    requestHeaders["X-Container"] = containerId

    return try await send(
      method: method,
      url: url,
      headers: requestHeaders,
      body: body
    )
  }

  package func send(
    method: String,
    url: URL,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse) {
    var urlRequest = makeURLRequest(method: method, url: url, headers: headers)
    urlRequest.httpBody = body
    return try await execute(urlRequest)
  }

  package func send(
    method: String,
    url: URL,
    headers: [String: String],
    fileURL: URL
  ) async throws -> (Data, HTTPURLResponse) {
    let urlRequest = makeURLRequest(method: method, url: url, headers: headers)
    return try await execute(urlRequest, fromFile: fileURL)
  }
}

extension NetworkController {

  private func makeURLRequest(
    method: String,
    url: URL,
    headers: [String: String]
  ) -> URLRequest {
    var urlRequest = URLRequest(
      url: url,
      cachePolicy: .useProtocolCachePolicy,
      timeoutInterval: 30
    )
    urlRequest.httpMethod = method
    for (key, value) in headers {
      urlRequest.addValue(value, forHTTPHeaderField: key)
    }
    return urlRequest
  }

  private func execute(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await urlSession.data(for: urlRequest)
    } catch {
      try mapNetworkTransportError(error)
    }
    return try httpResponse(data, response)
  }

  private func execute(
    _ urlRequest: URLRequest,
    fromFile fileURL: URL
  ) async throws -> (Data, HTTPURLResponse) {
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await urlSession.upload(for: urlRequest, fromFile: fileURL)
    } catch {
      try mapNetworkTransportError(error)
    }
    return try httpResponse(data, response)
  }
}

private func httpResponse(_ data: Data, _ response: URLResponse) throws -> (Data, HTTPURLResponse) {
  guard let httpResponse = response as? HTTPURLResponse else {
    throw NetworkError.unexpected(
      ParseError(debugMessage: "Response is not HTTP")
    )
  }
  return (data, httpResponse)
}

private func mapNetworkTransportError(_ error: Error) throws -> Never {
  if error is CancellationError {
    throw CancellationError()
  }
  if let urlError = error as? URLError, urlError.code == .cancelled {
    throw CancellationError()
  }
  if let networkError = error as? NetworkError {
    throw networkError
  }
  throw NetworkError.connection(error)
}
