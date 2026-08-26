import Foundation

/// Posts feedback entries to qualtive.io.
public protocol PostControllerType: Sendable {

  /// Posts an entry to qualtive.io.
  /// - Throws: `PostError`, or `CancellationError` when cancelled.
  func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes,
    locale: Locale
  ) async throws -> Entry
}

extension PostControllerType {

  public func post(
    to collection: Collection,
    content: [Entry.Content]
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: User(),
      customAttributes: [:],
      locale: .current
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: user,
      customAttributes: [:],
      locale: .current
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    customAttributes: Attributes
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: User(),
      customAttributes: customAttributes,
      locale: .current
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: user,
      customAttributes: customAttributes,
      locale: .current
    )
  }
}

/// Live entry posting controller.
public struct PostController: PostControllerType {

  public enum PostError: Error {
    case enquiryNotFound
    case network(NetworkError)
  }

  private let networkController: any NetworkControllerType
  private let standardAttributesController: any StandardAttributesControllerType
  private let userClientIDController: any UserClientIDControllerType

  public init() {
    self.init(
      networkController: NetworkController(),
      standardAttributesController: StandardAttributesController(),
      userClientIDController: UserClientIDController()
    )
  }

  package init(networkController: some NetworkControllerType) {
    self.init(
      networkController: networkController,
      standardAttributesController: StandardAttributesController(),
      userClientIDController: UserClientIDController()
    )
  }

  package init(
    networkController: some NetworkControllerType,
    standardAttributesController: some StandardAttributesControllerType,
    userClientIDController: some UserClientIDControllerType
  ) {
    self.networkController = networkController
    self.standardAttributesController = standardAttributesController
    self.userClientIDController = userClientIDController
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes,
    locale: Locale
  ) async throws -> Entry {
    var attributes = await standardAttributesController.makeAttributes(locale: locale)
    attributes.merge(customAttributes)

    let request = PostEntryRequest(
      questionId: collection.enquiryId.rawValue,
      content: content,
      user: .init(
        clientId: userClientIDController.clientId(),
        timeZoneIdentifier: TimeZone.current.identifier,
        id: user.id,
        name: user.name,
        email: user.email
      ),
      attributes: attributes,
      attributeHints: .init(clientLibrary: "swift")
    )

    do {
      return try await networkController.send(
        method: "POST",
        path: "/feedback/entries/",
        containerId: collection.containerId.rawValue,
        body: request
      )
    } catch let error as NetworkError {
      throw mapPostError(error)
    }
  }
}

private func mapPostError(_ error: NetworkError) -> PostController.PostError {
  switch error {
  case .notFound:
    return .enquiryNotFound
  default:
    return .network(error)
  }
}

private struct PostEntryRequest: Encodable {

  let questionId: String
  let content: [Entry.Content]
  let user: UserPayload
  let attributes: Attributes
  let attributeHints: AttributeHints

  struct UserPayload: Encodable {
    let clientId: String
    let timeZoneIdentifier: String
    let id: String?
    let name: String?
    let email: String?
  }

  struct AttributeHints: Encodable {
    let clientLibrary: String
  }
}
