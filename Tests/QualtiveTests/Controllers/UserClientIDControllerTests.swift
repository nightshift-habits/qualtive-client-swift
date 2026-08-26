import XCTest

@testable import Qualtive

final class UserClientIDControllerTests: XCTestCase {

  func testCreatesAndPersistsClientId() {
    let suite = "UserClientIDControllerTests.creates.\(UUID().uuidString)"
    defer { UserDefaults().removePersistentDomain(forName: suite) }

    let controller = UserClientIDController(storageKey: "test-cid", suiteName: suite)
    let first = controller.clientId()
    let second = controller.clientId()

    XCTAssertFalse(first.isEmpty)
    XCTAssertEqual(first, second)
    XCTAssertEqual(UserDefaults(suiteName: suite)!.string(forKey: "test-cid"), first)
  }

  func testReusesExistingClientId() {
    let suite = "UserClientIDControllerTests.reuses.\(UUID().uuidString)"
    defer { UserDefaults().removePersistentDomain(forName: suite) }

    UserDefaults(suiteName: suite)!.set("existing-id", forKey: "test-cid")
    let controller = UserClientIDController(storageKey: "test-cid", suiteName: suite)

    XCTAssertEqual(controller.clientId(), "existing-id")
  }
}
