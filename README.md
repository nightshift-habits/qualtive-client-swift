# Qualtive Client Library for Swift

## Installation

### Using Swift Package Manager

Add the following to your Package.swift:
```
dependencies: [
  .package(name: "Qualtive", url: "https://github.com/nightshift-habits/qualtive-client-swift.git", from: "1.0.0"),
]
```

If you are using Xcode, you can use ”Add Package Dependency…” from the menu bar and specify the following:
```
https://github.com/nightshift-habits/qualtive-client-swift.git
```

### Using CocoaPods

Add the following to your Podifle and then run `pod install` in the terminal:
```
pod 'Qualtive', '~> 1'
```

## Usage

First of all, make sure you have created a question on [qualtive.io](https://qualtive.io). Each feedback entry is posted to a so called collection (ID) which can be found in the question page.

To post a feedback entry, use the `Entry.post`-method. For example:

```swift
import Qualtive

Qualtive.Entry.post(
  to: ("my-company", "my-question"),
  content: [
    .score(.init(value: 75)), // Must be equal or between 0 and 100
    .text(.init(value: "Hello world!")),
  ]
)
```

If you want to get the question and it's content specified at qualtive.io, use the `Question.fetch`-method. For example:

```swift
Qualtive.Question.fetch(collection: ("my-company", "my-question")) { result in
  switch result {
  case .failure(let error):
    break // TODO: handle error
  case .success(let question):
    print(question)
  }
}
```

To post a feedback entry with complex content, use the content-property. For example:

```swift
Qualtive.Entry.post(
  to: ("my-company", "my-question"), 
  content: [
    .score(.init(value: 75)),
    .title(.init(value: "What are your thoughts on this feature?")),
    .text(.init(value: "It's awesome!")),
  }
)
```

### User data

If users can login on your site, you can include a user property describing the user. For example:

```swift
Qualtive.Entry.post(
  to: ("my-company", "my-question"), 
  content: [
    .score(.init(value: 75)),
  ],
  user: Qualtive.User(
    id: "user-123", // Authorized user id. Used to list feedback from the same user.
    name: "John", // User friendly name. Can be the users full name or username. Optional.
    email: "john@gmail.com", // Reachable email adress. Optional.
  )
)
```

### Advanced

You can also include custom attributes that will be shown up on qualtive.io. For example:

```swift
Qualtive.Entry.post(
  to: ("my-company", "my-question"),
  content: [
    .score(.init(value: 75)),
  ],
  customAttributes: [
    "Age": "32",
  ]
)
```

## Supported platforms

The following platforms are officially supported:

- iOS
- iPadOS
- macOS
- tvOS
- watchOS

This library should also be able to run on Linux and other Swift-supported platforms, but these are not offically supported.
