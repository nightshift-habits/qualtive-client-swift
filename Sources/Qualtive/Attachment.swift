import Foundation

public struct Attachment: Sendable {

    /// Uniq identifier.
    public let id: UInt64

    // MARK: - JSON

    init(json: [String: Any]) throws {
        guard let id = json["id"] as? UInt64 else {
            throw ParseError(debugMessage: "Id is not UInt64")
        }

        self.id = id
    }

    // MARK: - Upload

    public enum Upload: Sendable {
        case data(Data, kind: Kind)

        public enum Kind: Sendable {
            case png
            case jpeg

            fileprivate var mimeType: String {
                switch self {
                case .jpeg: return "image/jpeg"
                case .png: return "image/png"
                }
            }
        }
    }

    public enum UploadError: Error {
        case general(GeneralNetworkError)
    }

#if swift(>=5.5)
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public static func create(from upload: Upload, to containerId: String) async throws -> Attachment {
        try await withCheckedThrowingContinuation { continuation in
            create(from: upload, to: containerId) {
                continuation.resume(with: $0)
            }
        }
    }
#endif

    public static func create(from upload: Upload, to containerId: String, completion: (@Sendable (Result<Attachment, UploadError>) -> Void)? = nil) {
        var urlComponents = URLComponents(string: Configuration.remoteURLString)!
        urlComponents.path = "/feedback/attachments/"

        var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlRequest.httpMethod = "POST"

        let body: [String: Any]
        switch upload {
        case .data(_, let kind):
            body = [
                "contentType": kind.mimeType,
            ]
        }

        urlRequest.addValue(containerId, forHTTPHeaderField: "X-Container")
        urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body)

        let task = URLSession.qualtive.dataTask(with: urlRequest) { (data, response, connectionError) in
            if let response = response as? HTTPURLResponse, let data = data {
                switch response.statusCode {
                case 200..<300:
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        guard let root = json as? [String: Any] else {
                            throw ParseError(debugMessage: "Root object is not object")
                        }
                        guard let uploadURLString = root["uploadUrl"] as? String else {
                            throw ParseError(debugMessage: "uploadUrl is not a string")
                        }
                        guard let uploadURL = URL(string: uploadURLString) else {
                            throw ParseError(debugMessage: "uploadUrl is not a valid url")
                        }

                        let result = try Attachment(json: root)
                        result.update(from: upload, uploadURL: uploadURL, completion: completion)
                    } catch {
                        DispatchQueue.main.async {
                            completion?(.failure(.general(.unexpected(error))))
                        }
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

    private func update(from upload: Upload, uploadURL: URL, completion: (@Sendable (Result<Attachment, UploadError>) -> Void)? = nil) {
        var urlRequest = URLRequest(url: uploadURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlRequest.httpMethod = "PUT"

        switch upload {
        case .data(let data, let kind):
            urlRequest.addValue(kind.mimeType, forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data
        }

        let task = URLSession.qualtive.dataTask(with: urlRequest) { (data, response, connectionError) in
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200..<300:
                    DispatchQueue.main.async {
                        completion?(.success(self))
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
