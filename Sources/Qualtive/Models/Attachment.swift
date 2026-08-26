import Foundation

public struct Attachment: Sendable, Codable {

  /// Uniq identifier.
  public let id: UInt64

  public init(id: UInt64) {
    self.id = id
  }

  public enum Upload: Sendable {
    case data(Data, kind: Kind)

    public enum Kind: Sendable {
      case png
      case jpeg

      var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        }
      }
    }
  }
}
