import Foundation

@testable import Qualtive

final class MockNetworkController: NetworkControllerType, @unchecked Sendable {

  struct RecordedRequest: Sendable {
    let method: String
    let path: String?
    let url: URL?
    let containerId: String?
    let headers: [String: String]
    let body: Data?
  }

  private(set) var recordedRequests: [RecordedRequest] = []

  var pathHandler:
    (
      @Sendable (String, String, String, [String: String], Data?) async throws -> (
        Data, HTTPURLResponse
      )
    )?
  var urlHandler:
    (@Sendable (String, URL, [String: String], Data?) async throws -> (Data, HTTPURLResponse))?

  func send(
    method: String,
    path: String,
    containerId: String,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse) {
    recordedRequests.append(
      .init(
        method: method,
        path: path,
        url: nil,
        containerId: containerId,
        headers: headers,
        body: body
      )
    )
    guard let pathHandler else {
      throw NetworkError.unexpected(
        ParseError(debugMessage: "No path handler configured")
      )
    }
    do {
      return try await pathHandler(method, path, containerId, headers, body)
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as NetworkError {
      throw error
    } catch {
      try mapMockTransportError(error)
    }
  }

  func send(
    method: String,
    url: URL,
    headers: [String: String],
    body: Data?
  ) async throws -> (Data, HTTPURLResponse) {
    recordedRequests.append(
      .init(
        method: method,
        path: nil,
        url: url,
        containerId: nil,
        headers: headers,
        body: body
      )
    )
    guard let urlHandler else {
      throw NetworkError.unexpected(
        ParseError(debugMessage: "No url handler configured")
      )
    }
    do {
      return try await urlHandler(method, url, headers, body)
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as NetworkError {
      throw error
    } catch {
      try mapMockTransportError(error)
    }
  }
}

func makeHTTPURLResponse(
  url: URL = URL(string: "https://user-api.qualtive.io/")!,
  statusCode: Int
) -> HTTPURLResponse {
  HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

func jsonData<T: Encodable>(_ value: T) -> Data {
  try! JSONEncoder().encode(value)
}

func jsonData(_ utf8: String) -> Data {
  Data(utf8.utf8)
}

func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) -> T {
  try! JSONDecoder().decode(type, from: data)
}

private func mapMockTransportError(_ error: Error) throws -> Never {
  if let urlError = error as? URLError, urlError.code == .cancelled {
    throw CancellationError()
  }
  throw NetworkError.connection(error)
}
