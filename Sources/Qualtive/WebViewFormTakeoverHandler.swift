#if canImport(WebKit)
import WebKit

extension WKWebView {

    @available(iOS 14.0, macOS 11.0, *)
    public func handleQualtiveFormTakeover(didPresent present: @escaping (Collection, CheckedContinuation<Entry, Error>) -> Void) {
        configuration.userContentController.addScriptMessageHandler(
            ScriptMessageHandler(present: present),
            contentWorld: .page,
            name: "qualtive"
        )
    }
}

@available(iOS 14.0, macOS 11.0, *)
private final class ScriptMessageHandler: NSObject, WKScriptMessageHandlerWithReply {

    private let present: (Collection, CheckedContinuation<Entry, Error>) -> Void

    fileprivate init(present: @escaping (Collection, CheckedContinuation<Entry, Error>) -> Void) {
        self.present = present

        super.init()
    }

    // MARK: - WKScriptMessageHandlerWithReply

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let dictionary = message.body as? [String: Any] else {
            return (nil, "Message must be a dictionary")
        }
        guard let rawCollection = dictionary["collection"] as? [String] else {
            return (nil, "Collection must be an array of strings")
        }
        guard rawCollection.count >= 2 else {
            return (nil, "Collection is invalid")
        }
        let collection: Collection = (rawCollection[0], rawCollection[1])

        do {
            let entry = try await withCheckedThrowingContinuation { present(collection, $0) }
            return (["id": entry.id], nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}

#endif
