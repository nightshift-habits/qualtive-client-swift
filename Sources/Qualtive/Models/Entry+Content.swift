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
  public enum Content: Sendable, Encodable {

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

    /// Attachments/files input.
    case attachments(AttachmentsContent)

    private enum CodingKeys: String, CodingKey {
      case type
      case text
      case value
      case values
      case scoreType
      case leadingText
      case trailingText
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case .title(let content):
        try container.encode("title", forKey: .type)
        try container.encode(content.text, forKey: .text)
      case .score(let content):
        try container.encode("score", forKey: .type)
        try container.encodeIfPresent(content.value, forKey: .value)
        switch content.definition.kind {
        case .smilies5:
          try container.encode("smilies5", forKey: .scoreType)
        case .smilies3:
          try container.encode("smilies3", forKey: .scoreType)
        case .thumbs:
          try container.encode("thumbs", forKey: .scoreType)
        case .nps(let leadingText, let trailingText):
          try container.encode("nps", forKey: .scoreType)
          try container.encode(leadingText, forKey: .leadingText)
          try container.encode(trailingText, forKey: .trailingText)
        }
      case .text(let content):
        try container.encode("text", forKey: .type)
        try container.encodeIfPresent(content.value, forKey: .value)
      case .select(let content):
        try container.encode("select", forKey: .type)
        try container.encodeIfPresent(content.value, forKey: .value)
      case .multiselect(let content):
        try container.encode("multiselect", forKey: .type)
        try container.encode(content.values, forKey: .values)
      case .attachments(let content):
        try container.encode("attachments", forKey: .type)
        try container.encode(content.values, forKey: .values)
      }
    }
  }

  /// Static title that was displayed to the user. Not user interactable.
  public struct TitleContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.TitleContent

    /// Text of the title that was displayed.
    public var text: String

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.TitleContent) {
      self.definition = enquiryContent
      self.text = enquiryContent.text
    }

    /// Initialize content without any/empty enquiry definition.
    /// - Parameter text: Text of the title that was displayed.
    public init(text: String) {
      self.definition = .init()
      self.text = text
    }
  }

  /// Score/rating input for a single value between 0 and 100.
  public struct ScoreContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.ScoreContent

    /// Selected user value. Set to `nil`, when no value was selected.
    public var value: Score?

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.ScoreContent) {
      self.definition = enquiryContent
      self.value = nil
    }

    /// Initialize content without any/empty enquiry definition.
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
  public struct TextContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.TextContent

    /// Selected user value. Set to `nil`, when no value was selected.
    public var value: String?

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.TextContent) {
      self.definition = enquiryContent
      self.value = nil
    }

    /// Initialize content without any/empty enquiry definition.
    /// - Parameter value: Selected user value. Set to `nil`, when no value was selected.
    public init(value: String?) {
      self.definition = .init()
      self.value = value
    }
  }

  /// Single select/radio button input. User can select one of many possible pre-defined options.
  public struct SelectContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.SelectContent

    /// Selected user value. Set to `nil`, when no option was selected.
    public var value: String?

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.SelectContent) {
      self.definition = enquiryContent
      self.value = nil
    }

    /// Initialize content without any/empty enquiry definition.
    /// - Parameter value: Selected user value. Set to `nil`, when no option was selected.
    public init(value: String?) {
      self.definition = .init()
      self.value = value
    }
  }

  /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
  public struct MultiselectContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.MultiselectContent

    /// Selected user values. Set to empty array, when no option was selected.
    public var values: [String]

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.MultiselectContent) {
      self.definition = enquiryContent
      self.values = []
    }

    /// Initialize content without any/empty enquiry definition.
    /// - Parameter values: Selected user values. Set to empty array, when no option was selected.
    public init(values: [String]) {
      self.definition = .init()
      self.values = values
    }
  }

  /// Attachments/files input.
  public struct AttachmentsContent: Sendable {

    /// Source definition of the content from the enquiry.
    public let definition: Enquiry.AttachmentsContent

    /// Selected user values. Set to empty array, when no option was selected.
    public var values: [Attachment]

    /// Initialize content from an existing enquiry content.
    /// - Parameter enquiryContent: The existing enquiry content.
    public init(enquiryContent: Enquiry.AttachmentsContent) {
      self.definition = enquiryContent
      self.values = []
    }

    /// Initialize content without any/empty enquiry definition.
    /// - Parameter values: Selected user values. Set to empty array, when no option was selected.
    public init(values: [Attachment]) {
      self.definition = .init()
      self.values = values
    }
  }
}
