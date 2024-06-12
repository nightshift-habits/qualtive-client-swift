import Foundation

extension Question {

    /// Content for entries created by this question.
    ///
    /// Possible content kinds:
    /// - `title`: Static title to display to the user. Not user interactable.
    /// - `score`: Score/rating input for a single value between 0 and 100.
    /// - `text`: Free-form text input. User can type whatever text he/she wants.
    /// - `select`: Single select/radio button input. User can select one of many possible pre-defined options.
    /// - `multiselect`: Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
    /// - `attachments`: Attachments/files input.
    public enum Content: Sendable {

        /// Static title to display to the user. Not user interactable.
        case title(TitleContent)

        /// Score/rating input for a single value between 0 and 100.
        case score(ScoreContent)

        /// Free-form text input. User can type whatever text he/she wants.
        case text(TextContent)

        /// Single select/radio button input. User can select one of many possible pre-defined options.
        case select(SelectContent)

        /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
        case multiselect(MultiselectContent)

        /// Attachments/files input.
        case attachments(AttachmentsContent)

        init?(json: [String: Any]) throws {
            guard let type = json["type"] as? String else {
                throw ParseError(debugMessage: "Type is not string")
            }

            switch type {
            case "title":
                self = .title(try .init(json: json))
            case "score":
                guard let subcontent = try ScoreContent(json: json) else {
                    return nil
                }
                self = .score(subcontent)
            case "text":
                self = .text(try .init(json: json))
            case "select":
                self = .select(try .init(json: json))
            case "multiselect":
                self = .multiselect(try .init(json: json))
            case "attachments":
                self = .attachments(try .init(json: json))
            default:
                logHintNewVersion()
                return nil
            }
        }
    }

    /// Static title to display to the user. Not user interactable.
    public struct TitleContent: Sendable {

        /// Text of the title to display.
        public let text: String

        init(json: [String: Any]) throws {
            guard let text = json["text"] as? String else {
                throw ParseError(debugMessage: "Text is not string")
            }

            self.text = text
        }

        init() {
            self.text = ""
        }
    }

    /// Score/rating input for a single value between 0 and 100.
    public struct ScoreContent: Sendable {

        /// Kind/type of score to display for a user.
        public let kind: Score.Kind

        init?(json: [String: Any]) throws {
            guard let kind = try Score.Kind(json: json) else {
                return nil
            }

            self.kind = kind
        }

        init() {
            self.kind = .smilies5
        }
    }

    /// Free-form text input. User can type whatever text he/she wants.
    public struct TextContent: Sendable {

        /// Placeholder to display in the text input.
        public let placeholder: String?

        init(json: [String: Any]) throws {
            self.placeholder = json["placeholder"] as? String
        }

        init() {
            self.placeholder = nil
        }
    }

    /// Single select/radio button input. User can select one of many possible pre-defined options.
    public struct SelectContent: Sendable {

        /// Possible options to select.
        public let options: [String]

        init(json: [String: Any]) throws {
            guard let options = json["options"] as? [String] else {
                throw ParseError(debugMessage: "Select options is not array of strings")
            }

            self.options = options
        }

        init() {
            self.options = []
        }
    }

    /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
    public struct MultiselectContent: Sendable {

        /// Possible options to select.
        public let options: [String]

        init(json: [String: Any]) throws {
            guard let options = json["options"] as? [String] else {
                throw ParseError(debugMessage: "Multiselect options is not array of strings")
            }

            self.options = options
        }

        init() {
            self.options = []
        }
    }

    /// Attachments/files input.
    public struct AttachmentsContent: Sendable {

        init(json: [String: Any]) throws {}

        init() {}
    }
}
