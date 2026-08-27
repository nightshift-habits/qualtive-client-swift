import Foundation

/// Enquiry defined on Qualtive describing how an entry's content should be structured.
public struct Enquiry: Sendable, Decodable {

  /// Numeric identifier of the enquiry.
  public let id: Int64

  /// Slug of the enquiry. Can be used in place of the numeric id when fetching.
  public let slug: String

  /// Name of the enquiry.
  public let name: String

  /// Pages and content structure of the enquiry.
  public let pages: [Page]

  /// Thank-you / submitted pages, optionally gated by score conditions.
  public let submittedPages: [SubmittedPage]

  /// Theme of the enquiry. Controls appearance properties.
  public let theme: Theme

  /// Details about the container the enquiry belongs to.
  public let container: Container

  /// `true` if the user must provide contact details before submitting.
  public let isUserContactDetailsRequired: Bool

  private enum CodingKeys: String, CodingKey {
    case id
    case slug
    case name
    case pages
    case submittedPages
    case theme
    case container
    case isUserContactDetailsRequired
  }

  public init(
    id: Int64,
    slug: String,
    name: String,
    pages: [Page],
    submittedPages: [SubmittedPage] = [],
    theme: Theme,
    container: Container,
    isUserContactDetailsRequired: Bool = false
  ) {
    self.id = id
    self.slug = slug
    self.name = name
    self.pages = pages
    self.submittedPages = submittedPages
    self.theme = theme
    self.container = container
    self.isUserContactDetailsRequired = isUserContactDetailsRequired
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int64.self, forKey: .id)
    self.slug = try container.decode(String.self, forKey: .slug)
    self.name = try container.decode(String.self, forKey: .name)
    self.pages = try container.decode([Page].self, forKey: .pages)
    self.submittedPages =
      try container.decodeIfPresent([SubmittedPage].self, forKey: .submittedPages) ?? []
    self.theme = try container.decode(Theme.self, forKey: .theme)
    self.container = try container.decode(Container.self, forKey: .container)
    self.isUserContactDetailsRequired =
      try container.decodeIfPresent(Bool.self, forKey: .isUserContactDetailsRequired) ?? false
  }

  /// Creates a default/empty array of entry content; ready to be filled out by the user.
  ///
  /// Flattens all pages into a single content array. Static page content that is not part
  /// of an entry (`body`, `image`, `contactDetails`) is omitted.
  public func entryContentTemplate() -> [Entry.Content] {
    pages.flatMap { page in
      page.content.compactMap { content -> Entry.Content? in
        switch content {
        case .title(let content): return .title(.init(enquiryContent: content))
        case .score(let content): return .score(.init(enquiryContent: content))
        case .text(let content): return .text(.init(enquiryContent: content))
        case .select(let content): return .select(.init(enquiryContent: content))
        case .multiselect(let content): return .multiselect(.init(enquiryContent: content))
        case .attachments(let content): return .attachments(.init(enquiryContent: content))
        case .body, .image, .contactDetails:
          return nil
        }
      }
    }
  }

  public struct Page: Sendable, Decodable {

    public let content: [Content]

    private enum CodingKeys: String, CodingKey {
      case content
    }

    public init(content: [Content]) {
      self.content = content
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.content = try container.decodeSkippingUnknown([Content].self, forKey: .content)
    }
  }
}
