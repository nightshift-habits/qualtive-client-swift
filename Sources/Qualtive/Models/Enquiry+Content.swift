import Foundation

extension Enquiry {

  /// Content for entries created by this enquiry.
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
  }

  /// Static title to display to the user. Not user interactable.
  public struct TitleContent: Sendable, Decodable {

    /// Text of the title to display.
    public let text: String

    public init(text: String = "") {
      self.text = text
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

    public init(placeholder: String? = nil) {
      self.placeholder = placeholder
    }
  }

  /// Single select/radio button input. User can select one of many possible pre-defined options.
  public struct SelectContent: Sendable, Decodable {

    /// Possible options to select.
    public let options: [String]

    public init(options: [String] = []) {
      self.options = options
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
}

/// Decodes a single content object, returning `nil` for unknown or unsupported types.
struct ContentBox: Decodable {

  enum CodingKeys: String, CodingKey {
    case type
    case text
    case scoreType
    case leadingText
    case trailingText
    case placeholder
    case options
  }

  let value: Enquiry.Content?

  init(from decoder: Decoder) throws {
    let loggingController =
      (decoder.userInfo[CodingUserInfoKey.loggingController] as? any LoggingControllerType)
      ?? LoggingController()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "title":
      let text = try container.decode(String.self, forKey: .text)
      value = .title(.init(text: text))
    case "score":
      guard let kind = try Score.Kind(from: container, loggingController: loggingController)
      else {
        value = nil
        return
      }
      value = .score(.init(kind: kind))
    case "text":
      let placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
      value = .text(.init(placeholder: placeholder))
    case "select":
      let options = try container.decode([String].self, forKey: .options)
      value = .select(.init(options: options))
    case "multiselect":
      let options = try container.decode([String].self, forKey: .options)
      value = .multiselect(.init(options: options))
    case "attachments":
      value = .attachments(.init())
    default:
      loggingController.logHintNewVersion()
      value = nil
    }
  }
}

extension Score.Kind {

  fileprivate init?(
    from container: KeyedDecodingContainer<ContentBox.CodingKeys>,
    loggingController: any LoggingControllerType
  ) throws {
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
    default:
      loggingController.logHintNewVersion()
      return nil
    }
  }
}
