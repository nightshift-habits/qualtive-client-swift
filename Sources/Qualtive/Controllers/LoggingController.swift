import Foundation
import os

/// Logs library diagnostics such as hints about newer SDK versions.
public protocol LoggingControllerType: Sendable {

  /// Logs that the client may need updating when an unknown API value is encountered.
  func logHintNewVersion()
}

/// Default logging using the system unified logging facility.
public struct LoggingController: LoggingControllerType {

  public init() {}

  public func logHintNewVersion() {
    let text: StaticString =
      "There may be a new version of the Qualtive Client Library - Swift. Please update to get the latest features and fixes."
    os_log(text, log: .qualtive)
  }
}

extension CodingUserInfoKey {

  /// `JSONDecoder.userInfo` key for a `LoggingControllerType` used while decoding enquiry content.
  package static let loggingController = CodingUserInfoKey(
    rawValue: "Qualtive.loggingController"
  )!
}

extension OSLog {

  fileprivate static let qualtive = OSLog(
    subsystem: Bundle.main.bundleIdentifier ?? "",
    category: "qualtive"
  )
}
