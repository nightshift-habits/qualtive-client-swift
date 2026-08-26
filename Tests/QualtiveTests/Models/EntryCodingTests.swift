import Foundation
import Testing

@testable import Qualtive

@Suite
struct EntryCodingTests {

  @Test func `should decode`() throws {
    let result = try JSONDecoder()
      .decode(
        Entry.self,
        from: jsonData(["id": 123] as TestJSON)
      )
    #expect(result.id == 123)
  }

  @Test func `should throw when decoding invalid data`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Entry.self, from: jsonData([1] as TestJSON))
    }
  }

  @Test func `should throw when decoding an invalid id`() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Entry.self, from: jsonData(["id": "a"] as TestJSON))
    }
  }
}
