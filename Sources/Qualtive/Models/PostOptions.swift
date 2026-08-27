import Foundation

/// Per-post options for `PostController`.
///
/// - Parameters:
///   - metadataCollection: Whether to attach device/app attributes. Defaults to
///     `MetadataCollection.nonPersonal`.
///   - userTrackingConsent: Whether a persisted client id may be stored/sent. Defaults to
///     `UserTrackingConsent.granted`.
public struct PostOptions: Sendable, Equatable {

  /// Whether to attach device and app attributes.
  public var metadataCollection: MetadataCollection

  /// Whether a persisted client id may be stored and sent.
  public var userTrackingConsent: UserTrackingConsent

  public init(
    metadataCollection: MetadataCollection = .nonPersonal,
    userTrackingConsent: UserTrackingConsent = .granted
  ) {
    self.metadataCollection = metadataCollection
    self.userTrackingConsent = userTrackingConsent
  }
}

/// How much non-user metadata may be attached for a single post.
///
/// Independent of `UserTrackingConsent`, which only controls a persisted client id.
public enum MetadataCollection: Sendable, Equatable {
  /// Device and app attributes (for example `Platform`, `OS Version`).
  case nonPersonal

  /// No automatic metadata.
  case none
}

/// Whether the user has consented to a persisted client id for a single post.
///
/// `denied` means no client id is stored or sent. Device/app metadata is controlled separately
/// by `MetadataCollection`.
public enum UserTrackingConsent: Sendable, Equatable {
  case granted
  case denied
}
