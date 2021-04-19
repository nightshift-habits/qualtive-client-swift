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
}
