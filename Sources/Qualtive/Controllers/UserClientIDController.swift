import Foundation

/// Provides a stable per-device client identifier for posted entries.
protocol UserClientIDControllerType: Sendable {

  func clientId() -> String
}

/// Persists a unique client id in `UserDefaults`.
struct UserClientIDController: UserClientIDControllerType {

  private let storageKey: String
  private let suiteName: String?

  init() {
    self.init(storageKey: "_qualtiveCID", suiteName: nil)
  }

  init(storageKey: String, suiteName: String?) {
    self.storageKey = storageKey
    self.suiteName = suiteName
  }

  func clientId() -> String {
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
