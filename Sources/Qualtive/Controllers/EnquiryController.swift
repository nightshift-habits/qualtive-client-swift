import Foundation

/// Fetches enquiry definitions from qualtive.io.
public protocol EnquiryControllerType: Sendable {

  /// Fetch an enquiry and its definition from qualtive.io.
  /// - Parameters:
  ///   - collection: The collection identifier for the enquiry.
  ///   - locale: The locale to use. If the enquiry is translated on Qualtive this specifies
  ///     which translation to use for localizable fields. Defaults to device locale.
  ///   - previewToken: Optional preview token for unpublished enquiry drafts.
  /// - Returns: Enquiry definition.
  /// - Throws: `FetchError`, or `CancellationError` when cancelled.
  func fetch(
    collection: Collection,
    locale: Locale,
    previewToken: String?
  ) async throws -> Enquiry
}

extension EnquiryControllerType {

  public func fetch(collection: Collection) async throws -> Enquiry {
    try await fetch(collection: collection, locale: .current, previewToken: nil)
  }

  public func fetch(collection: Collection, locale: Locale) async throws -> Enquiry {
    try await fetch(collection: collection, locale: locale, previewToken: nil)
  }

  public func fetch(collection: Collection, previewToken: String?) async throws -> Enquiry {
    try await fetch(collection: collection, locale: .current, previewToken: previewToken)
  }
}

/// Live enquiry fetching controller.
public struct EnquiryController: EnquiryControllerType {

  public enum FetchError: Error {
    case notFound
    case network(NetworkError)
  }

  private let networkController: any NetworkControllerType

  public init() {
    self.init(networkController: NetworkController())
  }

  package init(networkController: some NetworkControllerType) {
    self.networkController = networkController
  }

  public func fetch(
    collection: Collection,
    locale: Locale,
    previewToken: String?
  ) async throws -> Enquiry {
    do {
      return try await networkController.send(
        method: "GET",
        path: enquiryPath(enquiryId: collection.enquiryId, previewToken: previewToken),
        containerId: collection.containerId.rawValue,
        headers: [
          "Accept-Language": locale.identifier.replacingOccurrences(of: "_", with: "-")
        ]
      )
    } catch let error as NetworkError {
      throw mapFetchError(error)
    }
  }
}

private func enquiryPath(enquiryId: EnquiryId, previewToken: String?) -> String {
  var path = "/feedback/enquiries/\(enquiryId)/"
  if let previewToken, !previewToken.isEmpty {
    var components = URLComponents()
    components.queryItems = [URLQueryItem(name: "previewToken", value: previewToken)]
    if let query = components.percentEncodedQuery {
      path += "?\(query)"
    }
  }
  return path
}

private func mapFetchError(_ error: NetworkError) -> EnquiryController.FetchError {
  switch error {
  case .notFound:
    return .notFound
  default:
    return .network(error)
  }
}
