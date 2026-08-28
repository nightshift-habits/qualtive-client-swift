# Qualtive Client Library for Swift

## Installation

### Using Swift Package Manager

Add the following to your Package.swift:
```
dependencies: [
  .package(url: "https://github.com/nightshift-habits/qualtive-client-swift.git", from: "2.0.0"),
]
```

If you are using Xcode, you can use ”Add Package Dependency…” from the menu bar and specify the following:
```
https://github.com/nightshift-habits/qualtive-client-swift.git
```

## Usage

First of all, make sure you have created an enquiry on [qualtive.io](https://qualtive.io). Each feedback entry is posted to a so called collection (container ID + enquiry ID or slug) which can be found on the enquiry page.

Optionally include a workspace slug between the container and enquiry (`"container/workspace/enquiry"`). When omitted, the user API uses the container's default workspace.

To post a feedback entry, use `PostController`. For example:

```swift
import Qualtive

let entry = try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .score(.init(value: 75)), // Must be equal or between 0 and 100
    .text(.init(value: "Hello world!")),
  ]
)
```

With a workspace:

```swift
try await PostController().post(
  to: "my-company/my-department/my-enquiry",
  content: [
    .score(.init(value: 75)),
  ]
)
```

If you want to get the enquiry and its content specified at qualtive.io, use `EnquiryController`. For example:

```swift
do {
  let enquiry = try await EnquiryController().fetch(
    collection: "my-company/my-enquiry"
  )
  print(enquiry)
} catch {
  // TODO: handle error
}
```

To post a feedback entry with complex content, use the content-property. For example:

```swift
try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .score(.init(value: 75)),
    .title(.init(text: "What are your thoughts on this feature?")),
    .text(.init(value: "It's awesome!")),
  ]
)
```

You can also build empty content from a fetched enquiry:

```swift
let enquiry = try await EnquiryController().fetch(
  collection: "my-company/my-enquiry"
)
var content = enquiry.entryContentTemplate()
// fill in user values on `content`, then post
```

### Controllers

The public API is split into focused controllers you can also inject via protocols for tests or custom UI:

- `EnquiryController` / `EnquiryControllerType` — fetch enquiry definitions
- `PostController` / `PostControllerType` — post entries
- `AttachmentController` / `AttachmentControllerType` — upload attachments

Default inits wire production networking. For custom UI later, pass these into your views.

### User data

If users can login on your site, you can include a user property describing the user. For example:

```swift
try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .score(.init(value: 75)),
  ],
  user: User(
    id: "user-123", // Authorized user id. Used to list feedback from the same user.
    name: "John", // User friendly name. Can be the users full name or username. Optional.
    email: "john@gmail.com", // Reachable email adress. Optional.
  )
)
```

### Advanced

You can also include custom attributes that will be shown up on qualtive.io. For example:

```swift
try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .score(.init(value: 75)),
  ],
  customAttributes: [
    "Age": "32",
    .language: "en",
  ]
)
```

`Attributes` is dictionary-backed and expressible by dictionary literal, with typed keys such as `.platform`, `.os`, and `.appId`.

Privacy options apply to that post only. By default, non-personal device/app attributes are attached and a per-device client id is stored. You can turn either off:

```swift
try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .text(.init(value: "Hello")),
  ],
  options: PostOptions(
    metadataCollection: .none,
    userTrackingConsent: .denied
  )
)
```

Attachments (for example from the photo picker or a file URL) upload first, then reference the returned id:

```swift
let image = try await AttachmentController().create(
  from: .data(pngData, contentType: .png),
  to: "my-company",
  workspaceId: "my-department"
)
let video = try await AttachmentController().create(
  from: .file(fileURL, contentType: "video/mp4"),
  to: "my-company"
)
try await PostController().post(
  to: "my-company/my-enquiry",
  content: [
    .attachments(.init(values: [image, video])),
  ]
)
```

Any MIME type is accepted. Prefer `.file` for large payloads so the bytes are streamed from disk.

## Supported platforms

The following platforms are officially supported:

- iOS 15+
- iPadOS 15+
- macOS 12+
- tvOS 15+ (API only)
- watchOS 8+ (API only)

This library should also be able to run on Linux and other Swift-supported platforms, but these are not offically supported.
