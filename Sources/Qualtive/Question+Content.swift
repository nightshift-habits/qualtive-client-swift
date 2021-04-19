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
    public enum Content {

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

        init?(json: [String: Any]) throws {
            guard let type = json["type"] as? String else {
                throw ParseError(debugMessage: "Type is not string")
            }

            switch type {
            case "title": self = .title(try .init(json: json))
            case "score": self = .score(try .init(json: json))
            case "text": self = .text(try .init(json: json))
            case "select": self = .select(try .init(json: json))
            case "multiselect": self = .multiselect(try .init(json: json))
            default:
                logHintNewVersion()
                return nil
            }
        }
    }

    /// Static title to display to the user. Not user interactable.
    public struct TitleContent {

        /// Text of the title to display.
        let text: String

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
    public struct ScoreContent {

        init(json: [String: Any]) throws {}

        init() {}
    }

    /// Free-form text input. User can type whatever text he/she wants.
    public struct TextContent {

        /// Placeholder to display in the text input.
        let placeholder: String?

        init(json: [String: Any]) throws {
            self.placeholder = json["placeholder"] as? String
        }

        init() {
            self.placeholder = nil
        }
    }

    /// Single select/radio button input. User can select one of many possible pre-defined options.
    public struct SelectContent {

        /// Possible options to select.
        let options: [String]

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
    public struct MultiselectContent {

        /// Possible options to select.
        let options: [String]

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
}
