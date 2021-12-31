import Foundation

/// Question defined on Qualtive on how an created entry's content should be defined.
public struct Question {

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
            case .multiselect(let content): return Entry.Content.multiselect(.init(questionContent: content))
            case .attachments(let content): return Entry.Content.attachments(.init(questionContent: content))
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

#if swift(>=5.5)
    /// Fetch a question and it's definition from qualtive.io.
    /// - Parameters:
    ///   - collection: The collection identifier for the question.
    ///   - locale: The locale to use for question. If the question is translated on Qualtive this specified which translation to use for localizable fields. Defaults to device locale.
    /// - Returns: Question definition.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public static func fetch(collection: Collection, locale: Locale = .current) async throws -> Question {
        try await withCheckedThrowingContinuation { continuation in
            fetch(collection: collection, options: .init(_remoteURLString: nil)) {
                continuation.resume(with: $0)
            }
        }
    }
#endif

    /// Fetch a question and it's definition from qualtive.io.
    /// - Parameters:
    ///   - collection: The collection identifier for the question.
    ///   - locale: The locale to use for question. If the question is translated on Qualtive this specified which translation to use for localizable fields. Defaults to device locale.
    ///   - completion: Closure that is called with the result of the operation. Called on the main thread.
    public static func fetch(collection: Collection, locale: Locale = .current, completion: ((Result<Question, FetchError>) -> Void)? = nil) {
        fetch(collection: collection, options: .init(_remoteURLString: nil), completion: completion)
    }

    static func fetch(collection: Collection, options: PrivateOptions, locale: Locale = .current, completion: ((Result<Question, FetchError>) -> Void)? = nil) {
        var urlComponents = URLComponents(string: options._remoteURLString ?? Configuration.remoteURLString)!
        urlComponents.path = "/feedback/questions/\(collection.questionId)/"

        var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue(collection.containerId, forHTTPHeaderField: "X-Container")
        urlRequest.addValue(locale.identifier.replacingOccurrences(of: "_", with: "-"), forHTTPHeaderField: "Accept-Language")

        let task = URLSession.qualtive.dataTask(with: urlRequest) { (data, response, connectionError) in
            if let response = response as? HTTPURLResponse, let data = data {
                switch response.statusCode {
                case 200..<300:
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        let result = try Question(json: json)
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
                        completion?(.failure(.notFound))
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
