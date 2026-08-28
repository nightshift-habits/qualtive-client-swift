# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- Optional workspace slug on `Collection` (between container and enquiry) and `AttachmentController.create`, sent as the `X-Workspace` header.
- Full enquiry fetch model: `theme`, `container`, `submittedPages` (with score conditions), and `isUserContactDetailsRequired`.
- Page content types `body`, `image`, and `contactDetails`; select `allowsCustomInput`; text `storageTarget`; and score `stars5`.
- Optional `previewToken` on `EnquiryController.fetch` for unpublished drafts.
- Per-post `PostOptions` for `metadataCollection` and `userTrackingConsent`.
- Attachment uploads from a local file URL, and arbitrary MIME types (not only PNG/JPEG).

### Fixed

- Text fields with `storageTarget` `.attribute` are posted as attributes, not as text content.

### Changed

- Dropped CocoaPods support. Swift Package Manager is the only supported installation method. 1.5.0 remains the last CocoaPods release.
- Upgraded to Swift 6.0 tools.
- Raised minimum platforms to iOS 15, iPadOS 15, macOS 12, tvOS 15, and watchOS 8.
- Networking APIs are async-only. Completion-handler variants were removed.
- Breaking redesign: `Question` → `Enquiry`, controller-based public API, and Codable networking. See README.

## 1.5.0

### Added

- Privacy Manifest
- Collecting time zone when posting feedback. This is used to show dates in the user's own time zone.

### Changed

- Preparation for Swift 6 and strict concurrency checking.
- Removed legacy Linux tests map
- Upgraded to Swift 5.10 tools

## 1.4.1

### Fixed

- Attribute key for app identifier.

## 1.4.0

### Added

- Async variants for all functions having a completion closure.
- Support for WKWebView's to be registered for web Qualtive form takeover. This feature allows apps to present Qualtive forms natively from a web view. 

## 1.3.0

### Added

 - Support for translated questions.
 - Support for different kinds of scores.
 - Added attribute ”App Identifier”.

## 1.2.2

### Fixed

- Access control for some question content.
- Missing platform attribute.

## 1.2.1

### Fixed

- Attachments upload.

## 1.2.0

### Added

 - Support for attachments.

## 1.1.0

### Added

 - Support for custom attributes when posting.

## 1.0.0

### Added

 - Initial release.
