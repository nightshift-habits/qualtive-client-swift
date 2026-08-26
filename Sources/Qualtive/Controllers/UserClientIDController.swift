import Foundation

/// Provides a stable per-device client identifier for posted entries.
public protocol UserClientIDControllerType: Sendable {

  func clientId() -> String
}

/// Persists a unique client id in `UserDefaults`.
public struct UserClientIDController: UserClientIDControllerType {

  private let storageKey: String
  private let suiteName: String?

  public init() {
    self.init(storageKey: "_qualtiveCID", suiteName: nil)
  }

  package init(storageKey: String, suiteName: String?) {
    self.storageKey = storageKey
    self.suiteName = suiteName
  }

  public func clientId() -> String {
    let userDefaults = self.userDefaults()
    if let existing = userDefaults.string(forKey: storageKey), !existing.isEmpty {
      return existing
    }
    let id = UUID().uuidString
    userDefaults.set(id, forKey: storageKey)
    return id
  }
}

extension UserClientIDController {

  private func userDefaults() -> UserDefaults {
    if let suiteName {
      return UserDefaults(suiteName: suiteName)!
    }
    return .standard
  }
}
