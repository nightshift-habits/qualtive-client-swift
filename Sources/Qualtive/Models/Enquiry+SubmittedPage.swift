import Foundation

extension Enquiry {

  /// Thank-you / submitted page, optionally gated by score conditions.
  public struct SubmittedPage: Sendable, Decodable {

    /// Content shown on the submitted page.
    public let content: [Content]

    /// Conditions that must match for this submitted page to be shown.
    public let conditions: [Condition]

    private enum CodingKeys: String, CodingKey {
      case content
      case conditions
    }

    public init(content: [Content], conditions: [Condition] = []) {
      self.content = content
      self.conditions = conditions
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.content = try container.decodeSkippingUnknownIfPresent(
        [Content].self,
        forKey: .content
      )
      self.conditions = try container.decodeSkippingUnknownIfPresent(
        [Condition].self,
        forKey: .conditions
      )
    }

    /// Content block on a submitted page.
    public enum Content: Sendable, Decodable {
      case title(Title)
      case body(Body)
      case image(Image)
      case confirmationText(ConfirmationText)
      case name
      case userInput
      case userInputScore
      case link(Link)
      case reviewLinks(ReviewLinks)

      public struct Title: Sendable, Equatable {
        public let text: String
        public init(text: String) { self.text = text }
      }

      public struct Body: Sendable, Equatable {
        public let text: String
        public init(text: String) { self.text = text }
      }

      public struct Image: Sendable, Equatable {
        public let attachment: ContentAttachment
        public let linkURL: String?
        public init(attachment: ContentAttachment, linkURL: String? = nil) {
          self.attachment = attachment
          self.linkURL = linkURL
        }
      }

      public struct ConfirmationText: Sendable, Equatable {
        public let text: String
        public init(text: String) { self.text = text }
      }

      public struct Link: Sendable, Equatable {
        public let text: String
        public let url: String
        public init(text: String, url: String) {
          self.text = text
          self.url = url
        }
      }

      public struct ReviewLinks: Sendable, Equatable {
        public let links: [Link]
        public init(links: [Link]) { self.links = links }

        public struct Link: Sendable, Equatable, Decodable {
          public let title: String
          public let url: String
          public let logo: Logo?
          public let icon: Icon?

          public init(title: String, url: String, logo: Logo? = nil, icon: Icon? = nil) {
            self.title = title
            self.url = url
            self.logo = logo
            self.icon = icon
          }

          public struct Logo: Sendable, Equatable, Decodable {
            public let urlVector: String
            public let urlVectorDark: String
            public init(urlVector: String, urlVectorDark: String) {
              self.urlVector = urlVector
              self.urlVectorDark = urlVectorDark
            }
          }

          public struct Icon: Sendable, Equatable, Decodable {
            public let urlRaster: String
            public let urlRasterDark: String
            public init(urlRaster: String, urlRasterDark: String) {
              self.urlRaster = urlRaster
              self.urlRasterDark = urlRasterDark
            }
          }
        }
      }

      private enum CodingKeys: String, CodingKey {
        case type
        case text
        case attachment
        case linkURL
        case url
        case links
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "title":
          self = .title(.init(text: try container.decode(String.self, forKey: .text)))
        case "body":
          self = .body(.init(text: try container.decode(String.self, forKey: .text)))
        case "image":
          self = .image(
            .init(
              attachment: try container.decode(ContentAttachment.self, forKey: .attachment),
              linkURL: try container.decodeIfPresent(String.self, forKey: .linkURL)
            )
          )
        case "confirmationText":
          self = .confirmationText(.init(text: try container.decode(String.self, forKey: .text)))
        case "name":
          self = .name
        case "userInput":
          self = .userInput
        case "userInputScore":
          self = .userInputScore
        case "link":
          self = .link(
            .init(
              text: try container.decode(String.self, forKey: .text),
              url: try container.decode(String.self, forKey: .url)
            )
          )
        case "reviewLinks":
          self = .reviewLinks(
            .init(links: try container.decode([ReviewLinks.Link].self, forKey: .links))
          )
        default:
          try throwUnknownAPIValue(decoder)
        }
      }
    }

    /// Condition that must match for this submitted page to be shown.
    public enum Condition: Sendable, Decodable {
      case score(Score)

      public struct Score: Sendable, Equatable {
        public let ranges: [Range]
        public init(ranges: [Range]) { self.ranges = ranges }

        public struct Range: Sendable, Equatable, Decodable {
          public let lower: Int?
          public let upper: Int?
          public init(lower: Int?, upper: Int?) {
            self.lower = lower
            self.upper = upper
          }
        }
      }

      private enum CodingKeys: String, CodingKey {
        case type
        case ranges
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "score":
          self = .score(
            .init(ranges: try container.decode([Score.Range].self, forKey: .ranges))
          )
        default:
          try throwUnknownAPIValue(decoder)
        }
      }
    }
  }
}
