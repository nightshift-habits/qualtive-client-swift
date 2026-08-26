import Foundation

/// Custom and standard attributes attached to a posted entry.
public struct Attributes: Sendable, Hashable, ExpressibleByDictionaryLiteral {

  /// Typed attribute key. Custom keys can be created from any string.
  public struct Key: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral,
    CustomStringConvertible
  {

    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    public var description: String { rawValue }

    public static let platform = Key("Platform")
    public static let os = Key("OS")
    public static let osVersion = Key("OS Version")
    public static let deviceModel = Key("Device Model")
    public static let deviceType = Key("Device Type")
    public static let appId = Key("App ID")
    public static let appVersion = Key("App Version")
    public static let appBuild = Key("App Build")
    public static let language = Key("Language")
    public static let region = Key("Region")
  }

  private var storage: [String: String]

  /// Creates attributes from a string dictionary.
  public init(_ dictionary: [String: String] = [:]) {
    self.storage = dictionary
  }

  /// Creates attributes from typed key-value pairs.
  public init(_ dictionary: [Key: String]) {
    var storage: [String: String] = [:]
    storage.reserveCapacity(dictionary.count)
    for (key, value) in dictionary {
      storage[key.rawValue] = value
    }
    self.storage = storage
  }

  public init(dictionaryLiteral elements: (Key, String)...) {
    var storage: [String: String] = [:]
    storage.reserveCapacity(elements.count)
    for (key, value) in elements {
      storage[key.rawValue] = value
    }
    self.storage = storage
  }

  /// Underlying string dictionary, suitable for JSON encoding.
  public var dictionary: [String: String] { storage }

  public subscript(key: Key) -> String? {
    get { storage[key.rawValue] }
    set { storage[key.rawValue] = newValue }
  }

  public subscript(key: String) -> String? {
    get { storage[key] }
    set { storage[key] = newValue }
  }

  /// Merges another set of attributes. Values in `other` replace existing keys.
  public mutating func merge(_ other: Attributes) {
    storage.merge(other.storage) { _, new in new }
  }

  /// Returns a copy with another set of attributes merged in.
  public func merging(_ other: Attributes) -> Attributes {
    var copy = self
    copy.merge(other)
    return copy
  }
}

extension Attributes: Encodable {

  public func encode(to encoder: Encoder) throws {
    try storage.encode(to: encoder)
  }
}
