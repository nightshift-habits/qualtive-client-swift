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

/// Workspace slug.
public struct WorkspaceId: Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {

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
/// Create from a `"container-id/enquiry-id"` or `"container-id/workspace-id/enquiry-id"`
/// string, or from typed ids:
/// `Collection(containerId: "my-company", enquiryId: "my-enquiry")`.
public struct Collection: Sendable, Hashable, ExpressibleByStringLiteral {

  /// Company / container identifier.
  public let containerId: ContainerId

  /// Optional workspace slug sent as `X-Workspace`.
  public let workspaceId: WorkspaceId?

  /// Enquiry identifier or slug.
  public let enquiryId: EnquiryId

  /// Creates a collection reference.
  public init(containerId: ContainerId, workspaceId: WorkspaceId? = nil, enquiryId: EnquiryId) {
    self.containerId = containerId
    self.workspaceId = workspaceId
    self.enquiryId = enquiryId
  }

  /// Creates a collection from `"container-id/enquiry-id"` or
  /// `"container-id/workspace-id/enquiry-id"`.
  ///
  /// - Important: Fatals if the string does not contain exactly one or two `/` separators.
  public init(stringLiteral value: String) {
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    switch components.count {
    case 2:
      self.containerId = ContainerId(String(components[0]))
      self.workspaceId = nil
      self.enquiryId = EnquiryId(String(components[1]))
    case 3:
      self.containerId = ContainerId(String(components[0]))
      self.workspaceId = WorkspaceId(String(components[1]))
      self.enquiryId = EnquiryId(String(components[2]))
    default:
      fatalError(
        "Collection string must be formatted as \"container-id/enquiry-id\" or \"container-id/workspace-id/enquiry-id\", got: \(value)"
      )
    }
  }
}
