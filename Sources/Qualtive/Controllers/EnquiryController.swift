import Foundation

/// Fetches enquiry definitions from qualtive.io.
public protocol EnquiryControllerType: Sendable {

  /// Fetch an enquiry and its definition from qualtive.io.
  /// - Parameters:
  ///   - collection: The collection identifier for the enquiry.
  ///   - locale: The locale to use. If the enquiry is translated on Qualtive this specifies
  ///     which translation to use for localizable fields. Defaults to device locale.
  /// - Returns: Enquiry definition.
  /// - Throws: `FetchError`, or `CancellationError` when cancelled.
  func fetch(
    collection: Collection,
    locale: Locale
  ) async throws -> Enquiry
}

extension EnquiryControllerType {

  public func fetch(collection: Collection) async throws -> Enquiry {
    try await fetch(collection: collection, locale: .current)
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
    locale: Locale
  ) async throws -> Enquiry {
    do {
      return try await networkController.send(
        method: "GET",
        path: "/feedback/enquiries/\(collection.enquiryId)/",
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

private func mapFetchError(_ error: NetworkError) -> EnquiryController.FetchError {
  switch error {
  case .notFound:
    return .notFound
  default:
    return .network(error)
  }
}
