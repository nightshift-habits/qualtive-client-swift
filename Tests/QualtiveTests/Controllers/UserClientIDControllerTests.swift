import Foundation
import Testing

@testable import Qualtive

@Suite
struct UserClientIDControllerTests {

  @Test func `should create and persist a client id`() {
    let defaultsSuite = "UserClientIDControllerTests.creates.\(UUID().uuidString)"
    defer { UserDefaults().removePersistentDomain(forName: defaultsSuite) }

    let controller = UserClientIDController(storageKey: "test-cid", suiteName: defaultsSuite)
    let first = controller.clientId()
    let second = controller.clientId()

    #expect(!first.isEmpty)
    #expect(first == second)
    #expect(UserDefaults(suiteName: defaultsSuite)!.string(forKey: "test-cid") == first)
  }

  @Test func `should reuse an existing client id`() {
    let defaultsSuite = "UserClientIDControllerTests.reuses.\(UUID().uuidString)"
    defer { UserDefaults().removePersistentDomain(forName: defaultsSuite) }

    UserDefaults(suiteName: defaultsSuite)!.set("existing-id", forKey: "test-cid")
    let controller = UserClientIDController(storageKey: "test-cid", suiteName: defaultsSuite)

    #expect(controller.clientId() == "existing-id")
  }
}
