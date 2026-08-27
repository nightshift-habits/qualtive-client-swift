import Foundation
import Testing

@testable import Qualtive

@Suite(.serialized)
struct NetworkControllerTests {

  private struct SampleResponse: Decodable, Equatable {
    let id: Int
  }

  @Test func `should send and decode a successful response`() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (jsonData(["id": 42] as TestJSON), makeHTTPURLResponse(statusCode: 200))
    }

    let result: SampleResponse = try await mock.send(
      method: "GET",
      path: "/sample/",
      containerId: "ci-test"
    )

    #expect(result == SampleResponse(id: 42))
  }

  @Test func `should throw when response JSON is invalid`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      ("not-json".data(using: .utf8)!, makeHTTPURLResponse(statusCode: 200))
    }

    await #expect {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
    } throws: { error in
      guard let error = error as? NetworkError, case .unexpected = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw not found for 404`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    await #expect {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
    } throws: { error in
      guard let error = error as? NetworkError, case .notFound = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw remote maintenance for 503`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 503))
    }

    await #expect {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
    } throws: { error in
      guard let error = error as? NetworkError, case .remoteMaintenance = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw unexpected for other status codes`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 500))
    }

    await #expect {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
    } throws: { error in
      guard let error = error as? NetworkError, case .unexpected = error else {
        return false
      }
      return true
    }
  }

  @Test func `should throw connection error`() async {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.notConnectedToInternet)
    }

    await #expect {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
    } throws: { error in
      guard let error = error as? NetworkError, case .connection = error else {
        return false
      }
      return true
    }
  }

  @Test func `should build the request`() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RecordingURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let networkController = NetworkController(
      urlSession: session,
      baseURL: URL(string: "https://example.test/")!
    )

    RecordingURLProtocol.handler = { request in
      #expect(request.url?.absoluteString == "https://example.test/feedback/enquiries/swift/")
      #expect(request.httpMethod == "GET")
      #expect(request.value(forHTTPHeaderField: "X-Container") == "ci-test")
      #expect(request.value(forHTTPHeaderField: "Accept-Language") == "en-US")
      #expect(request.httpBodyStream == nil && request.httpBody == nil)

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let data = jsonData(
        enquiryJSON(slug: "swift", name: "Swift?", pages: [])
      )
      return (data, response)
    }
    defer { RecordingURLProtocol.handler = nil }

    let enquiry: Enquiry = try await networkController.send(
      method: "GET",
      path: "/feedback/enquiries/swift/",
      containerId: "ci-test",
      headers: ["Accept-Language": "en-US"]
    )
    #expect(enquiry.slug == "swift")
  }

  @Test func `should send a path without a leading slash`() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RecordingURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let networkController = NetworkController(
      urlSession: session,
      baseURL: URL(string: "https://example.test/")!
    )

    RecordingURLProtocol.handler = { request in
      #expect(request.url?.absoluteString == "https://example.test/feedback/enquiries/swift/")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      return (jsonData(["id": 1] as TestJSON), response)
    }
    defer { RecordingURLProtocol.handler = nil }

    let result: SampleResponse = try await networkController.send(
      method: "GET",
      path: "feedback/enquiries/swift/",
      containerId: "ci-test"
    )
    #expect(result.id == 1)
  }
}

private final class RecordingURLProtocol: URLProtocol, @unchecked Sendable {

  nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.unknown))
      return
    }
    do {
      let (data, response) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
