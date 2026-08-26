import Foundation

/// Package-internal parse failure used when decoding or validating responses.
struct ParseError: Error, Sendable {

  let debugMessage: String
}
