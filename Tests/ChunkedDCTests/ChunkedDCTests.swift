import XCTest
@testable import ChunkedDC

final class ChunkerTests: XCTestCase {

    func testInitChunkSize() {
        let data = Data.init(bytes: [1, 2, 3, 4, 5, 6, 7, 8])
        XCTAssertThrowsError(try Chunker(
            id: 0, data: data, chunkSize: Common.headerLength
        )){ error in
            guard let thrownError = error as? ChunkerError else {
                XCTFail("Threw wrong type of error")
                return
            }
            switch thrownError {
            case .chunkSizeTooSmall:
                return
            default:
                XCTFail("Threw wrong error")
            }
        }
        XCTAssertNoThrow(try Chunker(
            id: 0, data: data, chunkSize: Common.headerLength + 1
        ))
    }

    func testInitData() {
        XCTAssertThrowsError(try Chunker(
            id: 0, data: Data.init(bytes: []), chunkSize: 42
        )) { error in
            guard let thrownError = error as? ChunkerError else {
                XCTFail("Threw wrong type of error")
                return
            }
            switch thrownError {
            case .dataEmpty:
                return
            default:
                XCTFail("Threw wrong error")
            }
        }
        XCTAssertNoThrow(try Chunker(
            id: 0, data: Data.init(bytes: [1]), chunkSize: 42
        ))
    }

    func testHasNext() {
        let chunker = try! Chunker(
            id: 0, data: Data.init(bytes: [1, 2, 3]), chunkSize: Common.headerLength + 1
        )
        XCTAssert(chunker.hasNext())
    }

    static var allTests = [
        ("testInitChunkSize", testInitChunkSize),
        ("testInitData", testInitData),
    ]

}
