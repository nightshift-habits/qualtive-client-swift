#if canImport(WebKit)
  import Foundation
  import Testing
  import WebKit

  @testable import Qualtive

  #if os(macOS)
    import AppKit
  #endif

  @Suite
  @MainActor
  struct WebViewFormTakeoverHandlerTests {

    @Test func `should present a collection and return the entry id`() async throws {
      let webView = try await FormTakeoverWebView()
      webView.handleQualtiveFormTakeover { collection, continuation in
        #expect(collection.containerId.rawValue == "ci-test")
        #expect(collection.enquiryId.rawValue == "swift")
        continuation.resume(returning: Entry(id: 42))
      }

      let reply = try await webView.send(["collection": ["ci-test", "swift"]])
      #expect(reply.ok)
      #expect(reply.error == nil)
      #expect(reply.entryId == 42)
    }

    @Test func `should return an error when presentation fails`() async throws {
      let webView = try await FormTakeoverWebView()
      webView.handleQualtiveFormTakeover { _, continuation in
        continuation.resume(throwing: PresentationError())
      }

      let reply = try await webView.send(["collection": ["ci-test", "swift"]])
      #expect(!reply.ok)
      #expect(reply.error?.contains("cancelled by host") == true)
    }

    @Test func `should reject a non-dictionary message`() async throws {
      let webView = try await FormTakeoverWebView()
      webView.handleQualtiveFormTakeover { _, continuation in
        continuation.resume(returning: Entry(id: 1))
      }

      let reply = try await webView.send("not-a-dictionary")
      #expect(!reply.ok)
      #expect(reply.error?.contains("Message must be a dictionary") == true)
    }

    @Test func `should reject a missing collection`() async throws {
      let webView = try await FormTakeoverWebView()
      webView.handleQualtiveFormTakeover { _, continuation in
        continuation.resume(returning: Entry(id: 1))
      }

      let reply = try await webView.send(["foo": "bar"])
      #expect(!reply.ok)
      #expect(reply.error?.contains("Collection must be an array of strings") == true)
    }

    @Test func `should reject a collection with too few parts`() async throws {
      let webView = try await FormTakeoverWebView()
      webView.handleQualtiveFormTakeover { _, continuation in
        continuation.resume(returning: Entry(id: 1))
      }

      let reply = try await webView.send(["collection": ["only-container"]])
      #expect(!reply.ok)
      #expect(reply.error?.contains("Collection is invalid") == true)
    }
  }

  @MainActor
  private final class FormTakeoverWebView {
    let webView: WKWebView
    private let navigationDelegate = LoadNavigationDelegate()

    init() async throws {
      #if os(macOS)
        _ = NSApplication.shared
      #endif

      let htmlURL = try #require(
        Bundle.module.url(forResource: "form-takeover", withExtension: "html")
      )
      let html = try String(contentsOf: htmlURL, encoding: .utf8)

      let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
      webView.navigationDelegate = navigationDelegate
      self.webView = webView
      try await navigationDelegate.load(html: html, in: webView)
    }

    func handleQualtiveFormTakeover(
      didPresent present: @escaping (Collection, CheckedContinuation<Entry, Error>) -> Void
    ) {
      webView.handleQualtiveFormTakeover(didPresent: present)
    }

    func send(_ body: Any) async throws -> TakeoverReply {
      let raw = try await webView.callAsyncJavaScript(
        "return await send(body);",
        arguments: ["body": body],
        contentWorld: .page
      )
      return try TakeoverReply(raw)
    }
  }

  @MainActor
  private final class LoadNavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    func load(html: String, in webView: WKWebView) async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        webView.loadHTMLString(html, baseURL: nil)
      }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      finish()
    }

    func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation!,
      withError error: Error
    ) {
      fail(error)
    }

    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      fail(error)
    }

    private func finish() {
      continuation?.resume()
      continuation = nil
    }

    private func fail(_ error: Error) {
      continuation?.resume(throwing: error)
      continuation = nil
    }
  }

  private struct TakeoverReply {
    let ok: Bool
    let error: String?
    let entryId: UInt64?

    init(_ raw: Any?) throws {
      let dictionary = try #require(raw as? [String: Any])
      ok = dictionary["ok"] as? Bool ?? false
      error = dictionary["error"] as? String
      let result = dictionary["result"] as? [String: Any]
      if let id = result?["id"] as? NSNumber {
        entryId = id.uint64Value
      } else {
        entryId = result?["id"] as? UInt64
      }
    }
  }

  private struct PresentationError: Error, LocalizedError {
    var errorDescription: String? { "cancelled by host" }
  }
#endif
