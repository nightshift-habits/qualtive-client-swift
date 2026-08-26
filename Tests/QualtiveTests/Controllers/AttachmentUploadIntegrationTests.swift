import Foundation
import Testing

@testable import Qualtive

@Suite
struct AttachmentUploadIntegrationTests {

  @Test func `should upload a png attachment`() async throws {
    let png = try onePixelPNG()
    let attachment = try await AttachmentController()
      .create(
        from: .data(png, kind: .png),
        to: "ci-test"
      )

    #expect(attachment.id > 0)
  }

  @Test func `should post an entry with an uploaded attachment`() async throws {
    let png = try onePixelPNG()
    let attachment = try await AttachmentController()
      .create(
        from: .data(png, kind: .png),
        to: "ci-test"
      )

    let entry = try await PostController()
      .post(
        to: "ci-test/swift",
        content: [
          .score(.init(value: 50)),
          .attachments(.init(values: [attachment])),
        ]
      )

    #expect(entry.id > 0)
  }

  @Test func `should throw on connection error`() async {
    let attachmentController = AttachmentController(
      networkController: NetworkController(
        baseURL: URL(string: "https://does-not-exists-qualtive.io/")!
      )
    )
    await #expect {
      _ = try await attachmentController.create(
        from: .data(Data(), kind: .png),
        to: "ci-test"
      )
    } throws: { error in
      guard let error = error as? AttachmentController.UploadError,
        case .network(.connection) = error
      else {
        return false
      }
      return true
    }
  }
}

private func onePixelPNG() throws -> Data {
  let url = try #require(Bundle.module.url(forResource: "1px", withExtension: "png"))
  return try Data(contentsOf: url)
}
