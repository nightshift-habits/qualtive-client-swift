import Foundation

/// Codable JSON value for test fixtures (avoids `JSONSerialization`).
enum TestJSON: Encodable, Equatable {
  case string(String)
  case int(Int)
  case int64(Int64)
  case bool(Bool)
  case null
  case array([TestJSON])
  case object([String: TestJSON])

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .int64(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    case .array(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    }
  }
}

extension TestJSON: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension TestJSON: ExpressibleByIntegerLiteral {
  init(integerLiteral value: Int) {
    self = .int(value)
  }
}

extension TestJSON: ExpressibleByBooleanLiteral {
  init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension TestJSON: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self = .null
  }
}

extension TestJSON: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: TestJSON...) {
    self = .array(elements)
  }
}

extension TestJSON: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (String, TestJSON)...) {
    self = .object(Dictionary(uniqueKeysWithValues: elements))
  }
}
