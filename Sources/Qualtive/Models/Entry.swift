import Foundation

/// Feedback entry
///
/// Can also be called response or post in some places.
public struct Entry: Sendable, Decodable {

  /// Uniq id and reference to the entry.
  public let id: UInt64

  public init(id: UInt64) {
    self.id = id
  }
}
