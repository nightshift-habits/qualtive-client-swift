import Foundation

public struct Attachment: Sendable, Codable {

  /// Uniq identifier.
  public let id: UInt64

  public init(id: UInt64) {
    self.id = id
  }

  /// MIME type for an uploaded attachment.
  ///
  /// Any MIME string is accepted (for example `application/pdf`, `video/mp4`, `image/jpeg`).
  public struct ContentType: Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible
  {

    public let mimeType: String

    public init(_ mimeType: String) {
      self.mimeType = mimeType
    }

    public init(stringLiteral value: String) {
      self.init(value)
    }

    public var description: String { mimeType }

    /// Convenience for `image/png`.
    public static let png = ContentType("image/png")

    /// Convenience for `image/jpeg`.
    public static let jpeg = ContentType("image/jpeg")
  }

  public enum Upload: Sendable {
    /// Bytes already in memory. Prefer `file` for large payloads such as video.
    case data(Data, contentType: ContentType)

    /// Local file URL. Streamed from disk; the full file is not buffered in memory.
    case file(URL, contentType: ContentType)
  }
}
