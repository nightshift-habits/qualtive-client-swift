import Foundation

/// Authorized / logged-in user metadata included when posting an entry.
public struct User: Sendable, Hashable {

  /// Your company defined user id.
  public var id: String?

  /// Name or alias for the user.
  public var name: String?

  /// Reachable email for the user.
  public var email: String?

  /// Initialize a user with defined properties.
  /// - Parameters:
  ///   - id: Your company defined user id.
  ///   - name: Name or alias for the user.
  ///   - email: Reachable email for the user.
  public init(id: String? = nil, name: String? = nil, email: String? = nil) {
    self.id = id
    self.name = name
    self.email = email
  }
}
