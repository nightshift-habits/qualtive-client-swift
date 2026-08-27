import Foundation

/// Posts feedback entries to qualtive.io.
public protocol PostControllerType: Sendable {

  /// Posts an entry to qualtive.io.
  ///
  /// Text sections whose enquiry definition uses `storageTarget` `.attribute` are sent as
  /// attributes, not as text content.
  /// - Throws: `PostError`, or `CancellationError` when cancelled.
  func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes,
    locale: Locale,
    options: PostOptions
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
      locale: .current,
      options: PostOptions()
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
      locale: .current,
      options: PostOptions()
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
      locale: .current,
      options: PostOptions()
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
      locale: .current,
      options: PostOptions()
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes,
    locale: Locale
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: user,
      customAttributes: customAttributes,
      locale: locale,
      options: PostOptions()
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    options: PostOptions
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: User(),
      customAttributes: [:],
      locale: .current,
      options: options
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    customAttributes: Attributes,
    options: PostOptions
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: User(),
      customAttributes: customAttributes,
      locale: .current,
      options: options
    )
  }

  public func post(
    to collection: Collection,
    content: [Entry.Content],
    user: User,
    customAttributes: Attributes,
    options: PostOptions
  ) async throws -> Entry {
    try await post(
      to: collection,
      content: content,
      user: user,
      customAttributes: customAttributes,
      locale: .current,
      options: options
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

  init(
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
    locale: Locale,
    options: PostOptions
  ) async throws -> Entry {
    var attributes = Attributes()
    if options.metadataCollection == .nonPersonal {
      attributes = await standardAttributesController.makeAttributes(locale: locale)
    }
    attributes.merge(customAttributes)
    attributes.merge(attributesFromContent(content))

    let clientId: String?
    if options.userTrackingConsent == .granted {
      clientId = userClientIDController.clientId()
    } else {
      clientId = nil
    }

    let request = PostEntryRequest(
      questionId: collection.enquiryId.rawValue,
      content: contentForPost(content),
      user: .init(
        clientId: clientId,
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

private func contentForPost(_ content: [Entry.Content]) -> [Entry.Content] {
  content.filter { section in
    if case .text(let text) = section,
      case .attribute = text.definition.storageTarget
    {
      return false
    }
    return true
  }
}

private func attributesFromContent(_ content: [Entry.Content]) -> Attributes {
  var result = Attributes()
  for section in content {
    guard case .text(let text) = section,
      case .attribute(let name) = text.definition.storageTarget
    else { continue }
    guard let value = text.value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { continue }
    result[name] = value
  }
  return result
}

private struct PostEntryRequest: Encodable {

  let questionId: String
  let content: [Entry.Content]
  let user: UserPayload
  let attributes: Attributes
  let attributeHints: AttributeHints

  struct UserPayload: Encodable {
    let clientId: String?
    let timeZoneIdentifier: String
    let id: String?
    let name: String?
    let email: String?

    private enum CodingKeys: String, CodingKey {
      case clientId
      case timeZoneIdentifier
      case id
      case name
      case email
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(clientId, forKey: .clientId)
      try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
      try container.encodeIfPresent(id, forKey: .id)
      try container.encodeIfPresent(name, forKey: .name)
      try container.encodeIfPresent(email, forKey: .email)
    }
  }

  struct AttributeHints: Encodable {
    let clientLibrary: String
  }
}
