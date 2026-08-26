import Foundation
import Testing

@testable import Qualtive

@Suite
struct EnquiryCodingTests {

  @Test func `should decode with no pages`() throws {
    let result = try JSONDecoder()
      .decode(
        Enquiry.self,
        from: jsonData(
          [
            "id": 1,
            "slug": "enquiry-slug",
            "name": "Enquiry Name",
            "pages": [],
          ] as TestJSON
        )
      )
    #expect(result.id == 1)
    #expect(result.slug == "enquiry-slug")
    #expect(result.name == "Enquiry Name")
    #expect(result.pages.count == 0)
  }

  @Test func `should decode title content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "title", "text": "Your thoughts?"]
    ])
    #expect(result.pages[0].content.count == 1)
    if case .title(let content) = result.pages[0].content[0] {
      #expect(content.text == "Your thoughts?")
    } else {
      Issue.record("Expected title")
    }
  }

  @Test func `should decode score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "smilies5"]
    ])
    if case .score = result.pages[0].content[0] {
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should decode text content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "text", "placeholder": "Write here…"]
    ])
    if case .text(let content) = result.pages[0].content[0] {
      #expect(content.placeholder == "Write here…")
    } else {
      Issue.record("Expected text")
    }
  }

  @Test func `should decode text content with no placeholder`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "text", "placeholder": nil]
    ])
    if case .text(let content) = result.pages[0].content[0] {
      #expect(content.placeholder == nil)
    } else {
      Issue.record("Expected text")
    }
  }

  @Test func `should decode select content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "select", "options": ["A", "B", "C"]]
    ])
    if case .select(let content) = result.pages[0].content[0] {
      #expect(content.options == ["A", "B", "C"])
    } else {
      Issue.record("Expected select")
    }
  }

  @Test func `should decode multiselect content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "multiselect", "options": ["1", "2", "3"]]
    ])
    if case .multiselect(let content) = result.pages[0].content[0] {
      #expect(content.options == ["1", "2", "3"])
    } else {
      Issue.record("Expected multiselect")
    }
  }

  @Test func `should decode attachments content`() throws {
    let result = try decodeEnquiryWithContent([["type": "attachments"]])
    if case .attachments = result.pages[0].content[0] {
    } else {
      Issue.record("Expected attachments")
    }
  }

  @Test func `should skip future content types`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "future-content-type", "key": 123]
    ])
    #expect(result.pages[0].content.count == 0)
  }

  @Test func `should throw when decoding an invalid root`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Enquiry.self, from: jsonData([1, 2, 3] as TestJSON))
    }
  }

  @Test func `should throw when decoding an invalid id`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder()
        .decode(
          Enquiry.self,
          from: jsonData(
            [
              "id": "not-a-number",
              "slug": "slug",
              "name": "Name",
              "pages": [],
            ] as TestJSON
          )
        )
    }
  }

  @Test func `should throw when decoding an invalid name`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder()
        .decode(
          Enquiry.self,
          from: jsonData(
            [
              "id": 1,
              "slug": "slug",
              "name": 1,
              "pages": [],
            ] as TestJSON
          )
        )
    }
  }

  @Test func `should throw when decoding invalid title text`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder()
        .decode(
          Enquiry.self,
          from: jsonData(
            [
              "id": 1,
              "slug": "slug",
              "name": "Name",
              "pages": [
                ["content": [["type": "title"]]]
              ],
            ] as TestJSON
          )
        )
    }
  }

  @Test func `should decode smilies3 score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "smilies3"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      if case .smilies3 = content.kind {
      } else {
        Issue.record("Expected smilies3")
      }
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should decode thumbs score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "thumbs"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      if case .thumbs = content.kind {
      } else {
        Issue.record("Expected thumbs")
      }
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should decode nps score content`() throws {
    let result = try decodeEnquiryWithContent([
      [
        "type": "score",
        "scoreType": "nps",
        "leadingText": "Low",
        "trailingText": "High",
      ]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      if case .nps(let leadingText, let trailingText) = content.kind {
        #expect(leadingText == "Low")
        #expect(trailingText == "High")
      } else {
        Issue.record("Expected nps")
      }
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should default nps labels when missing`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "nps"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      if case .nps(let leadingText, let trailingText) = content.kind {
        #expect(leadingText == "")
        #expect(trailingText == "")
      } else {
        Issue.record("Expected nps")
      }
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should flatten all content kinds into an entry content template`() throws {
    let enquiry = try decodeEnquiryWithContent(
      [
        ["type": "title", "text": "Title"],
        ["type": "score", "scoreType": "smilies5"],
        ["type": "text", "placeholder": "Write"],
        ["type": "select", "options": ["A"]],
        ["type": "multiselect", "options": ["B"]],
        ["type": "attachments"],
      ] as TestJSON
    )
    let template = enquiry.entryContentTemplate()
    #expect(template.count == 6)
    if case .select(let content) = template[3] {
      #expect(content.definition.options == ["A"])
    } else {
      Issue.record("Expected select")
    }
    if case .multiselect(let content) = template[4] {
      #expect(content.definition.options == ["B"])
    } else {
      Issue.record("Expected multiselect")
    }
    if case .attachments(let content) = template[5] {
      #expect(content.values.isEmpty)
    } else {
      Issue.record("Expected attachments")
    }
  }

  @Test func `should initialize a page from content`() {
    let page = Enquiry.Page(content: [.title(.init(text: "Hi"))])
    #expect(page.content.count == 1)
  }

  @Test func `should flatten pages into an entry content template`() throws {
    let enquiry = try JSONDecoder()
      .decode(
        Enquiry.self,
        from: jsonData(
          [
            "id": 1,
            "slug": "slug",
            "name": "Name",
            "pages": [
              [
                "content": [
                  ["type": "title", "text": "Page 1"],
                  ["type": "score", "scoreType": "smilies5"],
                ]
              ],
              [
                "content": [
                  ["type": "text", "placeholder": "More"]
                ]
              ],
            ],
          ] as TestJSON
        )
      )

    let template = enquiry.entryContentTemplate()
    #expect(template.count == 3)
    if case .title(let content) = template[0] {
      #expect(content.text == "Page 1")
    } else {
      Issue.record("Expected title")
    }
    if case .score(let content) = template[1] {
      #expect(content.value == nil)
    } else {
      Issue.record("Expected score")
    }
    if case .text(let content) = template[2] {
      #expect(content.value == nil)
      #expect(content.definition.placeholder == "More")
    } else {
      Issue.record("Expected text")
    }
  }
}

private func decodeEnquiryWithContent(_ content: TestJSON) throws -> Enquiry {
  try JSONDecoder()
    .decode(
      Enquiry.self,
      from: jsonData(
        [
          "id": 1,
          "slug": "enquiry-slug",
          "name": "Enquiry Name",
          "pages": [
            ["content": content]
          ],
        ] as TestJSON
      )
    )
}
