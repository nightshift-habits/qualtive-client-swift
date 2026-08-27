import Foundation

/// Package-internal parse failure used when decoding or validating responses.
struct ParseError: Error, Sendable {

  let debugMessage: String
}

/// Thrown while decoding a list item that should be skipped (unknown API type).
struct UnknownAPIValueError: Error, Sendable {}

func throwUnknownAPIValue(_ decoder: Decoder) throws -> Never {
  decoder.loggingController.logHintNewVersion()
  throw UnknownAPIValueError()
}

extension Decoder {

  var loggingController: any LoggingControllerType {
    (userInfo[CodingUserInfoKey.loggingController] as? any LoggingControllerType)
      ?? LoggingController()
  }
}

extension KeyedDecodingContainer {

  /// Decodes an array, skipping items that throw `UnknownAPIValueError`.
  func decodeSkippingUnknown<T: Decodable>(
    _ type: [T].Type,
    forKey key: Key
  ) throws -> [T] {
    var unkeyed = try nestedUnkeyedContainer(forKey: key)
    var values: [T] = []
    while !unkeyed.isAtEnd {
      let nested = try unkeyed.superDecoder()
      do {
        values.append(try T(from: nested))
      } catch is UnknownAPIValueError {
        continue
      }
    }
    return values
  }

  /// Decodes an array, skipping items that throw `UnknownAPIValueError`.
  ///
  /// Missing or null keys decode as an empty array.
  func decodeSkippingUnknownIfPresent<T: Decodable>(
    _ type: [T].Type,
    forKey key: Key
  ) throws -> [T] {
    guard contains(key), try !decodeNil(forKey: key) else { return [] }
    return try decodeSkippingUnknown(type, forKey: key)
  }
}
