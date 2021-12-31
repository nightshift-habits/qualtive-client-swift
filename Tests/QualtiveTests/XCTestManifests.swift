import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(EntryCodingTests.allTests),
        testCase(EntryPostTests.allTests),
        testCase(QuestionTests.allTests),
    ]
}
#endif
