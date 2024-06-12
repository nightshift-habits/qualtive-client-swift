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
    public enum Kind: Sendable {

        /// 5 user options displayed as smilies
        case smilies5

        /// 3 user options displayed as smilies
        case smilies3

        /// 2 user options displayed as up and down thumbs
        case thumbs

        /// 11 user options displayed as a range of numbers starting with 0 and ending on 10
        case nps(leadingText: String, trailingText: String)

        init?(json root: [String: Any]) throws {
            guard let type = root["scoreType"] as? String else {
                throw ParseError(debugMessage: "Score type is not a string")
            }

            switch type {
            case "smilies5":
                self = .smilies5
            case "smilies3":
                self = .smilies3
            case "thumbs":
                self = .thumbs
            case "nps":
                self = .nps(
                    leadingText: root["leadingText"] as? String ?? "",
                    trailingText: root["trailingText"] as? String ?? ""
                )
            default:
                logHintNewVersion()
                return nil
            }
        }

        var json: [String: Any] {
            switch self {
            case .smilies5:
                return ["scoreType": "smilies5"]
            case .smilies3:
                return ["scoreType": "smilies3"]
            case .thumbs:
                return ["scoreType": "thumbs"]
            case .nps(let leadingText, let trailingText):
                return ["scoreType": "nps", "leadingText": leadingText, "trailingText": trailingText]
            }
        }
    }
}

