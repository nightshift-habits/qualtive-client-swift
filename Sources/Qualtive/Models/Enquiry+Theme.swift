import Foundation

extension Enquiry {

  /// Visual theme for an enquiry.
  public struct Theme: Sendable, Decodable {

    /// Background configuration for the enquiry form.
    public let background: Background

    /// Font configuration for the enquiry form.
    public let font: Font

    /// Corner style of UI elements in the form.
    public let cornerStyle: CornerStyle

    /// Whether the background attachment is visible in public responses.
    public let isBackgroundAttachmentVisibleInResponses: Bool

    /// Whether the background color is visible in public responses.
    public let isBackgroundColorVisibleInResponses: Bool

    private enum CodingKeys: String, CodingKey {
      case background
      case font
      case cornerStyle
      case isBackgroundAttachmentVisibleInResponses
      case isBackgroundColorVisibleInResponses
    }

    public init(
      background: Background,
      font: Font,
      cornerStyle: CornerStyle,
      isBackgroundAttachmentVisibleInResponses: Bool = true,
      isBackgroundColorVisibleInResponses: Bool = true
    ) {
      self.background = background
      self.font = font
      self.cornerStyle = cornerStyle
      self.isBackgroundAttachmentVisibleInResponses = isBackgroundAttachmentVisibleInResponses
      self.isBackgroundColorVisibleInResponses = isBackgroundColorVisibleInResponses
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let loggingController =
        (decoder.userInfo[CodingUserInfoKey.loggingController] as? any LoggingControllerType)
        ?? LoggingController()

      self.background = try container.decode(Background.self, forKey: .background)
      self.font = try container.decode(Font.self, forKey: .font)

      let cornerStyleRaw = try container.decode(String.self, forKey: .cornerStyle)
      switch cornerStyleRaw {
      case "rounded":
        self.cornerStyle = .rounded
      case "square":
        self.cornerStyle = .square
      default:
        loggingController.logHintNewVersion()
        self.cornerStyle = .rounded
      }

      self.isBackgroundAttachmentVisibleInResponses =
        try container.decodeIfPresent(
          Bool.self,
          forKey: .isBackgroundAttachmentVisibleInResponses
        ) ?? true
      self.isBackgroundColorVisibleInResponses =
        try container.decodeIfPresent(
          Bool.self,
          forKey: .isBackgroundColorVisibleInResponses
        ) ?? true
    }

    /// Background configuration for an enquiry theme.
    public enum Background: Sendable, Decodable {

      /// Predefined background using a built-in style.
      case predefined(Predefined)

      /// Custom background with optional image and color.
      case custom(Custom)

      private enum CodingKeys: String, CodingKey {
        case type
        case value
        case attachment
        case color
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let loggingController =
          (decoder.userInfo[CodingUserInfoKey.loggingController] as? any LoggingControllerType)
          ?? LoggingController()
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "predefined":
          let valueRaw = try container.decode(String.self, forKey: .value)
          switch valueRaw {
          case "plain":
            self = .predefined(.plain)
          case "sponda":
            self = .predefined(.sponda)
          default:
            loggingController.logHintNewVersion()
            self = .predefined(.plain)
          }
        case "custom":
          let attachment = try container.decodeIfPresent(
            Custom.Attachment.self,
            forKey: .attachment
          )
          let color = try container.decode(Custom.Color.self, forKey: .color)
          self = .custom(.init(attachment: attachment, color: color))
        default:
          throw DecodingError.dataCorruptedError(
            forKey: .type,
            in: container,
            debugDescription: "Unknown background type: \(type)"
          )
        }
      }

      /// Predefined background styles.
      public enum Predefined: Sendable, Equatable {
        case plain
        case sponda
      }

      /// Custom background configuration.
      public struct Custom: Sendable, Equatable {

        public let attachment: Attachment?
        public let color: Color

        public init(attachment: Attachment?, color: Color) {
          self.attachment = attachment
          self.color = color
        }

        public struct Attachment: Sendable, Equatable, Decodable {
          public let id: Int64
          public let contentType: String
          public let url: String

          public init(id: Int64, contentType: String, url: String) {
            self.id = id
            self.contentType = contentType
            self.url = url
          }
        }

        public struct Color: Sendable, Equatable, Decodable {
          public let value: String

          public init(value: String) {
            self.value = value
          }
        }
      }
    }

    /// Font configuration for an enquiry theme.
    public enum Font: Sendable, Decodable {

      /// Predefined font family name (e.g. `"default"`, `"heptaSlab"`).
      case predefined(String)

      /// Custom font loaded from a remote URL.
      case custom(url: String)

      private enum CodingKeys: String, CodingKey {
        case type
        case value
        case url
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "predefined":
          self = .predefined(try container.decode(String.self, forKey: .value))
        case "custom":
          self = .custom(url: try container.decode(String.self, forKey: .url))
        default:
          throw DecodingError.dataCorruptedError(
            forKey: .type,
            in: container,
            debugDescription: "Unknown font type: \(type)"
          )
        }
      }
    }

    /// Corner style of UI elements.
    public enum CornerStyle: Sendable, Equatable {
      case rounded
      case square
    }
  }
}
