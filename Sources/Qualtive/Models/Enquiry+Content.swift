import Foundation

extension Enquiry {

  /// Content for entries created by this enquiry.
  ///
  /// Possible content kinds:
  /// - `title`: Static title to display to the user. Not user interactable.
  /// - `body`: Static body text to display to the user. Not user interactable.
  /// - `image`: Static image to display to the user. Not user interactable.
  /// - `score`: Score/rating input for a single value between 0 and 100.
  /// - `text`: Free-form text input. User can type whatever text he/she wants.
  /// - `select`: Single select/radio button input. User can select one of many possible pre-defined options.
  /// - `multiselect`: Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
  /// - `attachments`: Attachments/files input.
  /// - `contactDetails`: Contact details input if not given automatically.
  public enum Content: Sendable, Decodable {

    /// Static title to display to the user. Not user interactable.
    case title(TitleContent)

    /// Static body text to display to the user. Not user interactable.
    case body(BodyContent)

    /// Static image to display to the user. Not user interactable.
    case image(ImageContent)

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

    /// Contact details input if not given automatically.
    case contactDetails(ContactDetailsContent)
  }

  /// Static title to display to the user. Not user interactable.
  public struct TitleContent: Sendable, Decodable {

    /// Text of the title to display.
    public let text: String

    public init(text: String = "") {
      self.text = text
    }
  }

  /// Static body text to display to the user. Not user interactable.
  public struct BodyContent: Sendable, Decodable {

    /// Text of the body to display.
    public let text: String

    public init(text: String = "") {
      self.text = text
    }
  }

  /// Static image to display to the user. Not user interactable.
  public struct ImageContent: Sendable, Decodable {

    /// Remote image attachment.
    public let attachment: ContentAttachment

    public init(attachment: ContentAttachment) {
      self.attachment = attachment
    }
  }

  /// Score/rating input for a single value between 0 and 100.
  public struct ScoreContent: Sendable {

    /// Kind/type of score to display for a user.
    public let kind: Score.Kind

    public init(kind: Score.Kind = .smilies5) {
      self.kind = kind
    }
  }

  /// Free-form text input. User can type whatever text he/she wants.
  public struct TextContent: Sendable, Decodable {

    /// Placeholder to display in the text input.
    public let placeholder: String?

    /// Where the text input is stored when posting.
    public let storageTarget: StorageTarget

    public init(
      placeholder: String? = nil,
      storageTarget: StorageTarget = .text
    ) {
      self.placeholder = placeholder
      self.storageTarget = storageTarget
    }

    /// Where text input is stored when posting.
    public enum StorageTarget: Sendable, Equatable, Decodable {

      /// Stored as entry text content.
      case text

      /// Stored as a custom attribute.
      case attribute(String)

      private enum CodingKeys: String, CodingKey {
        case type
        case attribute
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
          self = .text
        case "attribute":
          self = .attribute(try container.decode(String.self, forKey: .attribute))
        default:
          throw DecodingError.dataCorruptedError(
            forKey: .type,
            in: container,
            debugDescription: "Unknown storageTarget type: \(type)"
          )
        }
      }
    }
  }

  /// Single select/radio button input. User can select one of many possible pre-defined options.
  public struct SelectContent: Sendable, Decodable {

    /// Possible options to select.
    public let options: [String]

    /// When `true`, the user may enter a custom value instead of a predefined option.
    public let allowsCustomInput: Bool

    public init(options: [String] = [], allowsCustomInput: Bool = false) {
      self.options = options
      self.allowsCustomInput = allowsCustomInput
    }
  }

  /// Multi-select/checkbox buttons input. User can select on or many of possible pre-defined options.
  public struct MultiselectContent: Sendable, Decodable {

    /// Possible options to select.
    public let options: [String]

    public init(options: [String] = []) {
      self.options = options
    }
  }

  /// Attachments/files input.
  public struct AttachmentsContent: Sendable, Decodable {

    public init() {}
  }

  /// Contact details input if not given automatically.
  public struct ContactDetailsContent: Sendable, Decodable {

    /// Title shown above the contact details field.
    public let title: String

    /// Placeholder shown in the contact details field.
    public let placeholder: String?

    public init(title: String = "", placeholder: String? = nil) {
      self.title = title
      self.placeholder = placeholder
    }
  }

  /// Remote attachment referenced by enquiry content.
  public struct ContentAttachment: Sendable, Decodable, Equatable {

    /// Remote URL to the attachment.
    public let url: String

    public init(url: String) {
      self.url = url
    }
  }
}

extension Enquiry.Content {

  fileprivate enum CodingKeys: String, CodingKey {
    case type
    case text
    case scoreType
    case leadingText
    case trailingText
    case placeholder
    case options
    case allowsCustomInput
    case storageTarget
    case attachment
    case title
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "title":
      let text = try container.decode(String.self, forKey: .text)
      self = .title(.init(text: text))
    case "body":
      let text = try container.decode(String.self, forKey: .text)
      self = .body(.init(text: text))
    case "image":
      let attachment = try container.decode(Enquiry.ContentAttachment.self, forKey: .attachment)
      self = .image(.init(attachment: attachment))
    case "score":
      guard let kind = try Score.Kind(from: container) else {
        try throwUnknownAPIValue(decoder)
      }
      self = .score(.init(kind: kind))
    case "text":
      let placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
      let storageTarget =
        try container.decodeIfPresent(
          Enquiry.TextContent.StorageTarget.self,
          forKey: .storageTarget
        ) ?? .text
      self = .text(.init(placeholder: placeholder, storageTarget: storageTarget))
    case "select":
      let options = try container.decode([String].self, forKey: .options)
      let allowsCustomInput =
        try container.decodeIfPresent(Bool.self, forKey: .allowsCustomInput) ?? false
      self = .select(.init(options: options, allowsCustomInput: allowsCustomInput))
    case "multiselect":
      let options = try container.decode([String].self, forKey: .options)
      self = .multiselect(.init(options: options))
    case "attachments":
      self = .attachments(.init())
    case "contactDetails":
      let title = try container.decode(String.self, forKey: .title)
      let placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
      self = .contactDetails(.init(title: title, placeholder: placeholder))
    default:
      try throwUnknownAPIValue(decoder)
    }
  }
}

extension Score.Kind {

  fileprivate init?(from container: KeyedDecodingContainer<Enquiry.Content.CodingKeys>) throws {
    let type = try container.decode(String.self, forKey: .scoreType)
    switch type {
    case "smilies5":
      self = .smilies5
    case "smilies3":
      self = .smilies3
    case "thumbs":
      self = .thumbs
    case "nps":
      self = .nps(
        leadingText: try container.decodeIfPresent(String.self, forKey: .leadingText) ?? "",
        trailingText: try container.decodeIfPresent(String.self, forKey: .trailingText) ?? ""
      )
    case "stars5":
      self = .stars5
    default:
      return nil
    }
  }
}
