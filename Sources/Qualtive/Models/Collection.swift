import Foundation

/// Company / container identifier.
public struct ContainerId: Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {

  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String { rawValue }
}

/// Enquiry identifier or slug.
public struct EnquiryId: Sendable, Hashable, ExpressibleByStringLiteral,
  ExpressibleByIntegerLiteral,
  CustomStringConvertible
{

  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ value: some BinaryInteger) {
    self.rawValue = String(value)
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public init(integerLiteral value: Int64) {
    self.rawValue = String(value)
  }

  public var description: String { rawValue }
}

/// Reference to an enquiry in a container on qualtive.io.
///
/// Create from a `"container-id/enquiry-id"` string, or from typed ids:
/// `Collection(containerId: "my-company", enquiryId: "my-enquiry")`.
public struct Collection: Sendable, Hashable, ExpressibleByStringLiteral {

  /// Company / container identifier.
  public let containerId: ContainerId

  /// Enquiry identifier or slug.
  public let enquiryId: EnquiryId

  /// Creates a collection reference.
  public init(containerId: ContainerId, enquiryId: EnquiryId) {
    self.containerId = containerId
    self.enquiryId = enquiryId
  }

  /// Creates a collection from `"container-id/enquiry-id"`.
  ///
  /// - Important: Fatals if the string does not contain exactly one `/` separator.
  public init(stringLiteral value: String) {
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    guard components.count == 2 else {
      fatalError(
        "Collection string must be formatted as \"container-id/enquiry-id\", got: \(value)"
      )
    }
    self.containerId = ContainerId(String(components[0]))
    self.enquiryId = EnquiryId(String(components[1]))
  }
}
