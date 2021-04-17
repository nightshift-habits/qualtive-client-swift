import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(EntryTests.allTests),
        testCase(QuestionTests.allTests),
    ]
}
#endif
