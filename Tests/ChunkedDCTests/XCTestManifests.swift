import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ChunkTests.allTests),
        testCase(ChunkerTests.allTests),
        testCase(UnchunkerTests.allTests),
    ]
}
#endif
