import XCTest
import QualtiveTests

var tests = [XCTestCaseEntry]()
tests += QualtiveTests.allTests()
XCTMain(tests)
