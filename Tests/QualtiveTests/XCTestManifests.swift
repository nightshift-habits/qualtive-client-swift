import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(EntryCodingTests.allTests),
        testCase(EntryPostAsyncTests.allTests),
        testCase(EntryPostTests.allTests),
        testCase(QuestionCodingTests.allTests),
        testCase(QuestionFetchAsyncTests.allTests),
        testCase(QuestionFetchTests.allTests),
    ]
}
#endif
