import XCTest

@testable import Qualtive

final class NetworkControllerTests: XCTestCase {

  private struct SampleResponse: Decodable, Equatable {
    let id: Int
  }

  func testSendDecodableSuccess() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (jsonData(["id": 42] as TestJSON), makeHTTPURLResponse(statusCode: 200))
    }

    let result: SampleResponse = try await mock.send(
      method: "GET",
      path: "/sample/",
      containerId: "ci-test"
    )

    XCTAssertEqual(result, SampleResponse(id: 42))
  }

  func testSendDecodableInvalidJSON() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      ("not-json".data(using: .utf8)!, makeHTTPURLResponse(statusCode: 200))
    }

    do {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as NetworkError {
      if case .unexpected = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSendDecodableNotFound() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 404))
    }

    do {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as NetworkError {
      XCTAssertEqual(error.isNotFound, true)
    }
  }

  func testSendDecodableRemoteMaintenance() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 503))
    }

    do {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as NetworkError {
      XCTAssertEqual(error.isRemoteMaintenance, true)
    }
  }

  func testSendDecodableOtherStatus() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      (Data(), makeHTTPURLResponse(statusCode: 500))
    }

    do {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as NetworkError {
      if case .unexpected = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSendDecodableConnectionError() async throws {
    let mock = MockNetworkController()
    mock.pathHandler = { _, _, _, _, _ in
      throw URLError(.notConnectedToInternet)
    }

    do {
      let _: SampleResponse = try await mock.send(
        method: "GET",
        path: "/sample/",
        containerId: "ci-test"
      )
      XCTFail("Expected error")
    } catch let error as NetworkError {
      if case .connection = error {
        return
      }
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testNetworkControllerBuildsRequest() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RecordingURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let networkController = NetworkController(
      urlSession: session,
      baseURL: URL(string: "https://example.test/")!
    )

    RecordingURLProtocol.handler = { request in
      XCTAssertEqual(request.url?.absoluteString, "https://example.test/feedback/enquiries/swift/")
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Container"), "ci-test")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "en-US")
      XCTAssertEqual(request.httpBodyStream != nil || request.httpBody != nil, false)

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let data = jsonData(
        [
          "id": 1,
          "slug": "swift",
          "name": "Swift?",
          "pages": [],
        ] as TestJSON
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
    XCTAssertEqual(enquiry.slug, "swift")
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

extension NetworkError {
  fileprivate var isNotFound: Bool {
    if case .notFound = self { return true }
    return false
  }

  fileprivate var isRemoteMaintenance: Bool {
    if case .remoteMaintenance = self { return true }
    return false
  }
}
