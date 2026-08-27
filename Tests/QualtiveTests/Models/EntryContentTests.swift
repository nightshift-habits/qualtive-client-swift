import Foundation
import Testing

@testable import Qualtive

@Suite
struct EntryContentTests {

  @Test func `should initialize an entry from an id`() {
    #expect(Entry(id: 99).id == 99)
  }

  @Test func `should encode title content`() throws {
    let encoded = try encode(.title(.init(text: "Hello")))
    #expect(encoded.type == "title")
    #expect(encoded.text == "Hello")
  }

  @Test func `should encode smilies3 score content`() throws {
    let encoded = try encode(
      .score(.init(enquiryContent: .init(kind: .smilies3)))
    )
    #expect(encoded.type == "score")
    #expect(encoded.scoreType == "smilies3")
    #expect(encoded.value == nil)
  }

  @Test func `should encode a numeric score value`() throws {
    let encoded = try encode(.score(.init(value: 0)))
    #expect(encoded.type == "score")
    #expect(encoded.scoreType == "smilies5")
    #expect(encoded.intValue == 0)
  }

  @Test func `should encode nps score content`() throws {
    var content = Entry.Content.score(
      .init(enquiryContent: .init(kind: .nps(leadingText: "Low", trailingText: "High")))
    )
    if case .score(var score) = content {
      score.value = 90
      content = .score(score)
    }
    let encoded = try encode(content)
    #expect(encoded.type == "score")
    #expect(encoded.scoreType == "nps")
    #expect(encoded.leadingText == "Low")
    #expect(encoded.trailingText == "High")
    #expect(encoded.intValue == 90)
  }

  @Test func `should encode thumbs score type`() throws {
    let encoded = try encode(
      .score(.init(enquiryContent: .init(kind: .thumbs)))
    )
    #expect(encoded.scoreType == "thumbs")
  }

  @Test func `should encode stars5 score type`() throws {
    let encoded = try encode(
      .score(.init(enquiryContent: .init(kind: .stars5)))
    )
    #expect(encoded.scoreType == "stars5")
    #expect(encoded.leadingText == nil)
    #expect(encoded.trailingText == nil)
  }

  @Test func `should encode attachment values`() throws {
    let encoded = try encode(.attachments(.init(values: [Attachment(id: 7)])))
    #expect(encoded.type == "attachments")
    #expect(encoded.attachmentIds == [7])
  }

  @Test func `should initialize select content from an enquiry`() {
    let content = Entry.SelectContent(
      enquiryContent: .init(options: ["A", "B"])
    )
    #expect(content.definition.options == ["A", "B"])
    #expect(content.value == nil)
  }

  @Test func `should initialize multiselect content from an enquiry`() {
    let content = Entry.MultiselectContent(
      enquiryContent: .init(options: ["1"])
    )
    #expect(content.definition.options == ["1"])
    #expect(content.values.isEmpty)
  }

  @Test func `should initialize attachments content from an enquiry`() {
    let content = Entry.AttachmentsContent(enquiryContent: .init())
    #expect(content.values.isEmpty)
  }
}

private struct EncodedContent: Decodable {
  let type: String
  let text: String?
  let value: FlexibleValue?
  let values: [FlexibleValue]?
  let scoreType: String?
  let leadingText: String?
  let trailingText: String?

  var intValue: UInt8? {
    if case .int(let value) = value { return value }
    return nil
  }

  var attachmentIds: [UInt64] {
    values?
      .compactMap { value in
        if case .attachment(let id) = value { return id }
        return nil
      } ?? []
  }

  enum FlexibleValue: Decodable {
    case int(UInt8)
    case string(String)
    case attachment(UInt64)

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let value = try? container.decode(UInt8.self) {
        self = .int(value)
        return
      }
      if let value = try? container.decode(String.self) {
        self = .string(value)
        return
      }
      let attachment = try container.decode(Attachment.self)
      self = .attachment(attachment.id)
    }
  }
}

private func encode(_ content: Entry.Content) throws -> EncodedContent {
  try JSONDecoder().decode(EncodedContent.self, from: JSONEncoder().encode(content))
}
