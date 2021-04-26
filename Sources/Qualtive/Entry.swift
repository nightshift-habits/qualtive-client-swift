import Foundation

/// Feedback entry
///
/// Can also be called response or post in some places.
public struct Entry {

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
    ///   - completion: Closure that is called with the result of the operation. Called on the main thread.
    public static func post(
        to collection: Collection,
        content: [Content],
        user: User = User(),
        customAttributes: [String: String] = [:],
        locale: Locale = .current,
        completion: ((Result<Entry, PostError>) -> Void)? = nil
    ) {
        post(to: collection, content: content, user: user, customAttributes: customAttributes, locale: locale, options: .init(_remoteURLString: nil), completion: completion)
    }

    static func post(
        to collection: Collection,
        content: [Content],
        user: User = User(),
        customAttributes: [String: String] = [:],
        locale: Locale = .current,
        options: PrivateOptions,
        completion: ((Result<Entry, PostError>) -> Void)? = nil
    ) {
        // Base and content
        var body: [String: Any] = [
            "questionId": collection.questionId,
            "content": content.map { (content) -> Any in
                var raw = [String: Any]()
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
                "clientLibrary": "swift",
            ]
        ]

        // User
        do {
            var rawUser: [String: Any] = [
                "clientId": user.clientId,
            ]
            if let value = user.id { rawUser["id"] = value }
            if let value = user.name { rawUser["name"] = value }
            if let value = user.email { rawUser["email"] = value }
            body["user"] = rawUser
        }

        // Attributes
        do {
            var attributes = Attributes.defaultAttributes(locale: locale)
            for (key, value) in customAttributes {
                attributes[key] = value
            }
            body["attributes"] = attributes
        }

        // Make request
        var urlComponents = URLComponents(string: options._remoteURLString ?? Configuration.remoteURLString)!
        urlComponents.path = "/feedback/entries/"

        var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue(collection.containerId, forHTTPHeaderField: "X-Container")
        urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body)

        let task = URLSession.qualtive.dataTask(with: urlRequest) { (data, response, connectionError) in
            if let response = response as? HTTPURLResponse, let data = data {
                switch response.statusCode {
                case 200..<300:
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let result = try Entry(json: json)
                        DispatchQueue.main.async {
                            completion?(.success(result))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion?(.failure(.general(.unexpected(error))))
                        }
                    }
                case 404:
                    DispatchQueue.main.async {
                        completion?(.failure(.questionNotFound))
                    }
                case 503:
                    DispatchQueue.main.async {
                        completion?(.failure(.general(.unexpected(UnexpectedError.remoteMaintenance))))
                    }
                default:
                    DispatchQueue.main.async {
                        completion?(.failure(.general(.unexpected(UnexpectedError.httpStatusCode(response.statusCode)))))
                    }
                }

            } else if let error = connectionError {
                DispatchQueue.main.async {
                    completion?(.failure(.general(.connection(error))))
                }
            } else {
                DispatchQueue.main.async {
                    completion?(.failure(.general(.cancelled)))
                }
            }
        }
        task.resume()
    }
}
