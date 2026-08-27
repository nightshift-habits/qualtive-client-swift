import Foundation
import Testing

@testable import Qualtive

@Suite
struct EnquiryCodingTests {

  @Test func `should decode with no pages`() throws {
    let result = try decodeEnquiry(pages: [])
    #expect(result.id == 1)
    #expect(result.slug == "enquiry-slug")
    #expect(result.name == "Enquiry Name")
    #expect(result.pages.count == 0)
    #expect(result.submittedPages.isEmpty)
    #expect(result.isUserContactDetailsRequired == false)
    #expect(result.theme.cornerStyle == .rounded)
    #expect(result.container.visibilityMode == .private)
  }

  @Test func `should decode a full enquiry payload`() throws {
    let result = try JSONDecoder()
      .decode(
        Enquiry.self,
        from: jsonData(
          [
            "id": .int64(6290486614556672),
            "slug": "web",
            "name": "Web?",
            "isUserContactDetailsRequired": true,
            "pages": [
              [
                "content": [
                  [
                    "type": "score",
                    "scoreType": "stars5",
                    "leadingText": "Bad",
                    "trailingText": "Good",
                  ],
                  ["type": "title", "text": "Hello"],
                  ["type": "body", "text": "Body text"],
                  [
                    "type": "image",
                    "attachment": ["url": "https://example.com/a.png"],
                  ],
                  [
                    "type": "text",
                    "placeholder": "Write…",
                    "storageTarget": ["type": "attribute", "attribute": "Age"],
                  ],
                  [
                    "type": "select",
                    "options": ["A", "B"],
                    "allowsCustomInput": true,
                  ],
                  ["type": "multiselect", "options": ["X", "Y"]],
                  ["type": "attachments"],
                  [
                    "type": "contactDetails",
                    "title": "Email",
                    "placeholder": "you@example.com",
                  ],
                  ["type": "futureThing", "foo": 1],
                ]
              ]
            ],
            "submittedPages": [
              [
                "conditions": [
                  [
                    "type": "score",
                    "ranges": [["lower": 0, "upper": 50]],
                  ],
                  ["type": "futureCondition"],
                ],
                "content": [
                  ["type": "confirmationText", "text": "Thanks!"],
                  ["type": "name"],
                  ["type": "userInput"],
                  ["type": "userInputScore"],
                  ["type": "link", "text": "Site", "url": "https://example.com"],
                  [
                    "type": "reviewLinks",
                    "links": [
                      [
                        "title": "Google",
                        "url": "https://google.com",
                        "logo": nil,
                        "icon": nil,
                      ]
                    ],
                  ],
                  ["type": "futureSubmitted"],
                ],
              ]
            ],
            "theme": [
              "cornerStyle": "rounded",
              "background": ["type": "predefined", "value": "plain"],
              "font": ["type": "predefined", "value": "default"],
              "isBackgroundAttachmentVisibleInResponses": true,
              "isBackgroundColorVisibleInResponses": false,
            ],
            "container": [
              "id": "ci-test",
              "isWhiteLabel": false,
              "customLogos": [],
              "visibilityMode": "private",
            ],
          ] as TestJSON
        )
      )

    #expect(result.id == 6290486614556672)
    #expect(result.slug == "web")
    #expect(result.name == "Web?")
    #expect(result.isUserContactDetailsRequired)
    #expect(result.pages.count == 1)
    #expect(result.pages[0].content.count == 9)

    if case .score(let score) = result.pages[0].content[0] {
      #expect(score.kind == .stars5)
    } else {
      Issue.record("Expected score")
    }

    if case .text(let text) = result.pages[0].content[4] {
      #expect(text.storageTarget == .attribute("Age"))
    } else {
      Issue.record("Expected text")
    }

    if case .select(let select) = result.pages[0].content[5] {
      #expect(select.allowsCustomInput)
    } else {
      Issue.record("Expected select")
    }

    #expect(result.submittedPages.count == 1)
    #expect(result.submittedPages[0].conditions.count == 1)
    if case .score(let condition) = result.submittedPages[0].conditions[0] {
      #expect(condition.ranges[0].lower == 0)
      #expect(condition.ranges[0].upper == 50)
    } else {
      Issue.record("Expected score condition")
    }
    #expect(result.submittedPages[0].content.count == 6)
    #expect(result.theme.cornerStyle == .rounded)
    #expect(result.theme.isBackgroundColorVisibleInResponses == false)
    #expect(result.container.visibilityMode == .private)
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

  @Test func `should decode body content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "body", "text": "More detail"]
    ])
    if case .body(let content) = result.pages[0].content[0] {
      #expect(content.text == "More detail")
    } else {
      Issue.record("Expected body")
    }
  }

  @Test func `should decode image content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "image", "attachment": ["url": "https://example.com/a.png"]]
    ])
    if case .image(let content) = result.pages[0].content[0] {
      #expect(content.attachment.url == "https://example.com/a.png")
    } else {
      Issue.record("Expected image")
    }
  }

  @Test func `should decode contact details content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "contactDetails", "title": "Email", "placeholder": "you@example.com"]
    ])
    if case .contactDetails(let content) = result.pages[0].content[0] {
      #expect(content.title == "Email")
      #expect(content.placeholder == "you@example.com")
    } else {
      Issue.record("Expected contactDetails")
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
      #expect(content.storageTarget == .text)
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

  @Test func `should decode text storage target attribute`() throws {
    let result = try decodeEnquiryWithContent([
      [
        "type": "text",
        "placeholder": "Age",
        "storageTarget": ["type": "attribute", "attribute": "Age"],
      ]
    ])
    if case .text(let content) = result.pages[0].content[0] {
      #expect(content.storageTarget == .attribute("Age"))
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
      #expect(content.allowsCustomInput == false)
    } else {
      Issue.record("Expected select")
    }
  }

  @Test func `should decode select with custom input`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "select", "options": ["A"], "allowsCustomInput": true]
    ])
    if case .select(let content) = result.pages[0].content[0] {
      #expect(content.allowsCustomInput)
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
            enquiryJSON(
              id: "not-a-number",
              pages: []
            )
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
            enquiryJSON(
              name: 1,
              pages: []
            )
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
            enquiryJSON(
              pages: [
                ["content": [["type": "title"]]]
              ]
            )
          )
        )
    }
  }

  @Test func `should decode smilies3 score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "smilies3"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      #expect(content.kind == .smilies3)
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should decode thumbs score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "thumbs"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      #expect(content.kind == .thumbs)
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should decode nps score content with labels`() throws {
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

  @Test func `should decode nps without labels`() throws {
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

  @Test func `should decode stars5 score content`() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "stars5"]
    ])
    if case .score(let content) = result.pages[0].content[0] {
      #expect(content.kind == .stars5)
    } else {
      Issue.record("Expected score")
    }
  }

  @Test func `should flatten input content into an entry content template`() throws {
    let enquiry = try decodeEnquiryWithContent(
      [
        ["type": "title", "text": "Title"],
        ["type": "body", "text": "Body"],
        ["type": "image", "attachment": ["url": "https://example.com/a.png"]],
        ["type": "score", "scoreType": "smilies5"],
        ["type": "text", "placeholder": "Write"],
        ["type": "select", "options": ["A"]],
        ["type": "multiselect", "options": ["B"]],
        ["type": "attachments"],
        ["type": "contactDetails", "title": "Email"],
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
    let enquiry = try decodeEnquiry(
      pages: [
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
      ]
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

  @Test func `should default unknown theme and container enums`() throws {
    let result = try decodeEnquiry(
      pages: [],
      theme: [
        "cornerStyle": "hexagon",
        "background": ["type": "predefined", "value": "neon"],
        "font": ["type": "predefined", "value": "default"],
      ],
      container: [
        "id": "c",
        "visibilityMode": "secret",
        "customLogos": [
          [
            "size": "round",
            "intendedBackground": "light",
            "primaryColor": "#fff",
            "urlVector": "https://logo.svg",
          ],
          [
            "size": "wide",
            "intendedBackground": "light",
            "primaryColor": "#fff",
            "urlVector": "https://logo.svg",
          ],
        ],
      ]
    )
    #expect(result.theme.cornerStyle == .rounded)
    if case .predefined(let value) = result.theme.background {
      #expect(value == .plain)
    } else {
      Issue.record("Expected predefined background")
    }
    #expect(result.container.visibilityMode == .private)
    #expect(result.container.customLogos.count == 1)
  }
}

private func decodeEnquiryWithContent(_ content: TestJSON) throws -> Enquiry {
  try decodeEnquiry(pages: [["content": content]])
}

private func decodeEnquiry(
  id: TestJSON = 1,
  slug: TestJSON = "enquiry-slug",
  name: TestJSON = "Enquiry Name",
  pages: TestJSON,
  theme: TestJSON? = nil,
  container: TestJSON? = nil
) throws -> Enquiry {
  try JSONDecoder()
    .decode(
      Enquiry.self,
      from: jsonData(
        enquiryJSON(
          id: id,
          slug: slug,
          name: name,
          pages: pages,
          theme: theme,
          container: container
        )
      )
    )
}

func enquiryJSON(
  id: TestJSON = 1,
  slug: TestJSON = "enquiry-slug",
  name: TestJSON = "Enquiry Name",
  pages: TestJSON,
  theme: TestJSON? = nil,
  container: TestJSON? = nil
) -> TestJSON {
  [
    "id": id,
    "slug": slug,
    "name": name,
    "pages": pages,
    "submittedPages": [],
    "theme": theme
      ?? [
        "cornerStyle": "rounded",
        "background": ["type": "predefined", "value": "plain"],
        "font": ["type": "predefined", "value": "default"],
        "isBackgroundAttachmentVisibleInResponses": true,
        "isBackgroundColorVisibleInResponses": true,
      ],
    "container": container
      ?? [
        "id": "ci-test",
        "isWhiteLabel": false,
        "customLogos": [],
        "visibilityMode": "private",
      ],
  ]
}
