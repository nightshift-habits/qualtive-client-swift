import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(EntryCodingTests.allTests),
        testCase(EntryPostTests.allTests),
        testCase(QuestionCodingTests.allTests),
        testCase(QuestionFetchTests.allTests),
    ]
}
#endif
