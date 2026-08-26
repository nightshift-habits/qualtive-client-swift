import XCTest

@testable import Qualtive

final class EnquiryCodingTests: XCTestCase {

  func testDecodeNoPages() throws {
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
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.slug, "enquiry-slug")
    XCTAssertEqual(result.name, "Enquiry Name")
    XCTAssertEqual(result.pages.count, 0)
  }

  func testDecodeContentTitle() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "title", "text": "Your thoughts?"]
    ])
    XCTAssertEqual(result.pages[0].content.count, 1)
    switch result.pages[0].content[0] {
    case .title(let content):
      XCTAssertEqual(content.text, "Your thoughts?")
    default:
      XCTFail("Expected title")
    }
  }

  func testDecodeContentScore() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "score", "scoreType": "smilies5"]
    ])
    switch result.pages[0].content[0] {
    case .score:
      break
    default:
      XCTFail("Expected score")
    }
  }

  func testDecodeContentText() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "text", "placeholder": "Write here…"]
    ])
    switch result.pages[0].content[0] {
    case .text(let content):
      XCTAssertEqual(content.placeholder, "Write here…")
    default:
      XCTFail("Expected text")
    }
  }

  func testDecodeContentTextNoPlaceholder() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "text", "placeholder": nil]
    ])
    switch result.pages[0].content[0] {
    case .text(let content):
      XCTAssertNil(content.placeholder)
    default:
      XCTFail("Expected text")
    }
  }

  func testDecodeContentSelect() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "select", "options": ["A", "B", "C"]]
    ])
    switch result.pages[0].content[0] {
    case .select(let content):
      XCTAssertEqual(content.options, ["A", "B", "C"])
    default:
      XCTFail("Expected select")
    }
  }

  func testDecodeContentMultiselect() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "multiselect", "options": ["1", "2", "3"]]
    ])
    switch result.pages[0].content[0] {
    case .multiselect(let content):
      XCTAssertEqual(content.options, ["1", "2", "3"])
    default:
      XCTFail("Expected multiselect")
    }
  }

  func testDecodeContentAttachments() throws {
    let result = try decodeEnquiryWithContent([["type": "attachments"]])
    switch result.pages[0].content[0] {
    case .attachments:
      break
    default:
      XCTFail("Expected attachments")
    }
  }

  func testDecodeContentFutureSkipped() throws {
    let result = try decodeEnquiryWithContent([
      ["type": "future-content-type", "key": 123]
    ])
    XCTAssertEqual(result.pages[0].content.count, 0)
  }

  func testDecodeInvalidRoot() {
    XCTAssertThrowsError(
      try JSONDecoder().decode(Enquiry.self, from: jsonData([1, 2, 3] as TestJSON))
    )
  }

  func testDecodeInvalidId() {
    XCTAssertThrowsError(
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
    )
  }

  func testDecodeInvalidName() {
    XCTAssertThrowsError(
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
    )
  }

  func testDecodeInvalidTitleText() {
    XCTAssertThrowsError(
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
    )
  }

  func testEntryContentTemplateFlattensPages() throws {
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
    XCTAssertEqual(template.count, 3)
    switch template[0] {
    case .title(let content):
      XCTAssertEqual(content.text, "Page 1")
    default:
      XCTFail("Expected title")
    }
    switch template[1] {
    case .score(let content):
      XCTAssertNil(content.value)
    default:
      XCTFail("Expected score")
    }
    switch template[2] {
    case .text(let content):
      XCTAssertNil(content.value)
      XCTAssertEqual(content.definition.placeholder, "More")
    default:
      XCTFail("Expected text")
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
}
