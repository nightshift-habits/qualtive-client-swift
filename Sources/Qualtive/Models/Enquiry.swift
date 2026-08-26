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

  /// Creates a default/empty array of entry content; ready to be filled out by the user.
  ///
  /// Flattens all pages into a single content array. It is safe to assume the length of
  /// the returned array equals the total number of mapped content items across pages.
  public func entryContentTemplate() -> [Entry.Content] {
    pages.flatMap { page in
      page.content.map { content in
        switch content {
        case .title(let content): return Entry.Content.title(.init(enquiryContent: content))
        case .score(let content): return Entry.Content.score(.init(enquiryContent: content))
        case .text(let content): return Entry.Content.text(.init(enquiryContent: content))
        case .select(let content): return Entry.Content.select(.init(enquiryContent: content))
        case .multiselect(let content):
          return Entry.Content.multiselect(.init(enquiryContent: content))
        case .attachments(let content):
          return Entry.Content.attachments(.init(enquiryContent: content))
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
      let boxes = try container.decode([ContentBox].self, forKey: .content)
      self.content = boxes.compactMap(\.value)
    }
  }
}
