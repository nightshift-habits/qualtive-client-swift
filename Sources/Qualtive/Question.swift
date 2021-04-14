import Foundation

public struct Question {

    public let id: String
    public let name: String
    public let content: [Content]

    public enum Content {
        case title(TitleContent)
        case score(ScoreContent)
        case text(TextContent)

        init?(json: [String: Any]) throws {
            guard let type = json["type"] as? String else {
                throw ParseError(debugMessage: "Type is not string")
            }

            switch type {
            case "title": self = .title(try .init(json: json))
            case "score": self = .score(try .init(json: json))
            case "text":  self = .text (try .init(json: json))
            default:
                // TODO: Log to developers and hint about updated version
                return nil
            }
        }
    }

    public struct TitleContent {

        let text: String

        init(json: [String: Any]) throws {
            guard let text = json["text"] as? String else {
                throw ParseError(debugMessage: "Text is not string")
            }

            self.text = text
        }
    }

    public struct TextContent {

        let placeholder: String?

        init(json: [String: Any]) throws {
            self.placeholder = json["placeholder"] as? String
        }
    }

    public struct ScoreContent {

        init(json: [String: Any]) throws {}
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
        guard let rawContent = root["content"] as? [[String: String]] else {
            throw ParseError(debugMessage: "Content is not array of objects")
        }

        self.id = id
        self.name = name
        self.content = try rawContent.compactMap { try Content(json: $0) }
    }

    // MARK: - Fetch

    public enum FetchError: Error {
        case connection(Error)
        case notFound
        case cancelled
        case unexpected(Error)
        case remoteMaintenance
    }

    public struct FetchOptions {

        public let _remoteURLString: String?
    }

    public static func fetch(collection: Collection, completion: ((Result<Question, FetchError>) -> Void)? = nil) {
        fetch(collection: collection, options: .init(_remoteURLString: nil), completion: completion)
    }

    static func fetch(collection: Collection, options: FetchOptions, completion: ((Result<Question, FetchError>) -> Void)? = nil) {
        var urlComponents = URLComponents(string: options._remoteURLString ?? Configuration.remoteURLString)!
        urlComponents.path = "/feedback/questions/\(collection.questionId)/"

        var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue(collection.containerId, forHTTPHeaderField: "X-Container")

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
                            completion?(.failure(.unexpected(error)))
                        }
                    }
                case 404:
                    DispatchQueue.main.async {
                        completion?(.failure(.notFound))
                    }
                case 503:
                    DispatchQueue.main.async {
                        completion?(.failure(.unexpected(UnexpectedError.remoteMaintenance)))
                    }
                default:
                    DispatchQueue.main.async {
                        completion?(.failure(.unexpected(UnexpectedError.httpStatusCode(response.statusCode))))
                    }
                }

            } else if let error = connectionError {
                DispatchQueue.main.async {
                    completion?(.failure(.connection(error)))
                }
            } else {
                DispatchQueue.main.async {
                    completion?(.failure(.cancelled))
                }
            }
        }
        task.resume()
    }
}
