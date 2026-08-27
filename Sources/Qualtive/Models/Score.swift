import Foundation

/// Score value for a score/rating input.
public typealias Score = UInt8

extension Score {

  /// Valid range of the score. Score must be a value between or equal to `0` and `100`.
  public static let validRange: ClosedRange<Score> = (0...100)

  /// `true` if the score is inside the valid range, else, `false`. See `validRange`.
  public var isValidRange: Bool {
    (0...100).contains(self)
  }

  /// Kind/type of score to display for a user
  ///
  /// Possible kinds:
  /// - `smilies5`: 5 user options displayed as smilies
  /// - `smilies3`: 3 user options displayed as smilies
  /// - `thumbs`: 2 user options displayed as up and down thumbs
  /// - `nps`: 11 user options displayed as a range of numbers starting with 0 and ending on 10
  /// - `stars5`: 5 user options displayed as stars
  public enum Kind: Sendable, Equatable {

    /// 5 user options displayed as smilies
    case smilies5

    /// 3 user options displayed as smilies
    case smilies3

    /// 2 user options displayed as up and down thumbs
    case thumbs

    /// 11 user options displayed as a range of numbers starting with 0 and ending on 10
    case nps(leadingText: String, trailingText: String)

    /// 5 user options displayed as stars
    case stars5
  }
}
