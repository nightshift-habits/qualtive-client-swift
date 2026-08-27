import Foundation

extension Enquiry {

  /// Container (workspace) details for an enquiry.
  public struct Container: Sendable, Decodable {

    /// Identifier of the container.
    public let id: String

    /// `true` if the container may hide Qualtive branding.
    public let isWhiteLabel: Bool

    /// Custom logos for the container.
    public let customLogos: [CustomLogo]

    /// Visibility mode of responses.
    public let visibilityMode: VisibilityMode

    private enum CodingKeys: String, CodingKey {
      case id
      case isWhiteLabel
      case customLogos
      case visibilityMode
    }

    public init(
      id: String,
      isWhiteLabel: Bool = false,
      customLogos: [CustomLogo] = [],
      visibilityMode: VisibilityMode
    ) {
      self.id = id
      self.isWhiteLabel = isWhiteLabel
      self.customLogos = customLogos
      self.visibilityMode = visibilityMode
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let loggingController =
        (decoder.userInfo[CodingUserInfoKey.loggingController] as? any LoggingControllerType)
        ?? LoggingController()

      self.id = try container.decode(String.self, forKey: .id)
      self.isWhiteLabel = try container.decodeIfPresent(Bool.self, forKey: .isWhiteLabel) ?? false

      self.customLogos = try container.decodeSkippingUnknownIfPresent(
        [CustomLogo].self,
        forKey: .customLogos
      )

      let visibilityRaw = try container.decode(String.self, forKey: .visibilityMode)
      switch visibilityRaw {
      case "public":
        self.visibilityMode = .public
      case "private":
        self.visibilityMode = .private
      default:
        loggingController.logHintNewVersion()
        self.visibilityMode = .private
      }
    }

    /// Custom logo variant for a container.
    public struct CustomLogo: Sendable, Equatable, Decodable {
      public let size: Size
      public let intendedBackground: IntendedBackground
      public let primaryColor: String
      public let urlVector: String

      public init(
        size: Size,
        intendedBackground: IntendedBackground,
        primaryColor: String,
        urlVector: String
      ) {
        self.size = size
        self.intendedBackground = intendedBackground
        self.primaryColor = primaryColor
        self.urlVector = urlVector
      }

      public enum Size: Sendable, Equatable {
        case wide
        case square
      }

      public enum IntendedBackground: Sendable, Equatable {
        case light
        case dark
      }

      private enum CodingKeys: String, CodingKey {
        case size
        case intendedBackground
        case primaryColor
        case urlVector
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sizeRaw = try container.decode(String.self, forKey: .size)
        let backgroundRaw = try container.decode(String.self, forKey: .intendedBackground)

        let size: Size?
        switch sizeRaw {
        case "wide": size = .wide
        case "square": size = .square
        default: size = nil
        }

        let intendedBackground: IntendedBackground?
        switch backgroundRaw {
        case "light": intendedBackground = .light
        case "dark": intendedBackground = .dark
        default: intendedBackground = nil
        }

        guard let size, let intendedBackground else {
          try throwUnknownAPIValue(decoder)
        }

        self.init(
          size: size,
          intendedBackground: intendedBackground,
          primaryColor: try container.decode(String.self, forKey: .primaryColor),
          urlVector: try container.decode(String.self, forKey: .urlVector)
        )
      }
    }

    /// Visibility mode of the container.
    public enum VisibilityMode: Sendable, Equatable {
      case `public`
      case `private`
    }
  }
}
