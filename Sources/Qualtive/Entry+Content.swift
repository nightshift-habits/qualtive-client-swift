import Foundation

extension Entry {

    /// Content for an entry.
    ///
    /// Possible content kinds:
    /// - `title`: Static title that was displayed to the user. Not user interactable.
    /// - `score`: Score/rating input for a single value between 0 and 100.
    /// - `text`: Free-form text input. User can type whatever text he/she wants.
    /// - `select`: Single select/radio button input. User can select one of many possible pre-defined options.
    /// - `multiselect`: Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
    public enum Content {

        /// Static title that was displayed to the user. Is not user interactable.
        case title(TitleContent)

        /// Score/rating input for a single value between 0 and 100.
        case score(ScoreContent)

        /// Free-form text input. User can type whatever text he/she wants.
        case text(TextContent)

        /// Single select/radio button input. User can select one of many possible pre-defined options.
        case select(SelectContent)

        /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
        case multiselect(MultiselectContent)
    }

    /// Static title that was displayed to the user. Not user interactable.
    public struct TitleContent {

        /// Source definition of the content from the question.
        public let definition: Question.TitleContent

        /// Text of the title that was displayed.
        public var text: String

        /// Initialize content from an existing question content.
        /// - Parameter questionContent: The existing question content.
        public init(questionContent: Question.TitleContent) {
            self.definition = questionContent
            self.text = questionContent.text
        }

        /// Initialize content without any/empty question definition.
        /// - Parameter text: Text of the title that was displayed.
        public init(text: String) {
            self.definition = .init()
            self.text = text
        }
    }

    /// Score/rating input for a single value between 0 and 100.
    public struct ScoreContent {

        /// Source definition of the content from the question.
        public let definition: Question.ScoreContent

        /// Selected user value. Set to `nil`, when no value was selected.
        public var value: Score?

        /// Initialize content from an existing question content.
        /// - Parameter questionContent: The existing question content.
        public init(questionContent: Question.ScoreContent) {
            self.definition = questionContent
            self.value = nil
        }

        /// Initialize content without any/empty question definition.
        /// - Parameter value: Selected user value. Set to `nil`, when no value was selected.
        public init(value: Score?) {
            guard (value ?? 0).isValidRange else {
                fatalError("Score value must be between or equal to 0 and 100")
            }
            self.definition = .init()
            self.value = value
        }
    }

    /// Free-form text input. User can type whatever text he/she wants.
    public struct TextContent {

        /// Source definition of the content from the question.
        public let definition: Question.TextContent

        /// Selected user value. Set to `nil`, when no value was selected.
        public var value: String?

        /// Initialize content from an existing question content.
        /// - Parameter questionContent: The existing question content.
        public init(questionContent: Question.TextContent) {
            self.definition = questionContent
            self.value = nil
        }

        /// Initialize content without any/empty question definition.
        /// - Parameter value: Selected user value. Set to `nil`, when no value was selected.
        public init(value: String?) {
            self.definition = .init()
            self.value = value
        }
    }

    /// Single select/radio button input. User can select one of many possible pre-defined options.
    public struct SelectContent {

        /// Source definition of the content from the question.
        public let definition: Question.SelectContent

        /// Selected user value. Set to `nil`, when no option was selected.
        public var value: String?

        /// Initialize content from an existing question content.
        /// - Parameter questionContent: The existing question content.
        public init(questionContent: Question.SelectContent) {
            self.definition = questionContent
            self.value = nil
        }

        /// Initialize content without any/empty question definition.
        /// - Parameter value: Selected user value. Set to `nil`, when no option was selected.
        public init(value: String?) {
            self.definition = .init()
            self.value = value
        }
    }

    /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
    public struct MultiselectContent {

        /// Source definition of the content from the question.
        public let definition: Question.MultiselectContent

        /// Selected user values. Set to empty array, when no option was selected.
        public var values: [String]

        /// Initialize content from an existing question content.
        /// - Parameter questionContent: The existing question content.
        public init(questionContent: Question.MultiselectContent) {
            self.definition = questionContent
            self.values = []
        }

        /// Initialize content without any/empty question definition.
        /// - Parameter values: Selected user values. Set to empty array, when no option was selected.
        public init(values: [String]) {
            self.definition = .init()
            self.values = values
        }
    }
}
