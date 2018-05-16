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
        let _ = chunker.next()
        XCTAssert(chunker.hasNext())
        let _ = chunker.next()
        XCTAssert(chunker.hasNext())
        let _ = chunker.next()
        XCTAssert(!chunker.hasNext())
    }

    func testNext() {
        let chunker = try! Chunker(
            id: 42, data: Data.init(bytes: [1, 2, 3, 4, 5, 6, 7, 8]), chunkSize: 12
        )

        let chunk1 = chunker.next()
        XCTAssertEqual(chunk1, [0, 0,0,0,42, 0,0,0,0, 1,2,3])

        let chunk2 = chunker.next()
        XCTAssertEqual(chunk2, [0, 0,0,0,42, 0,0,0,1, 4,5,6])

        let chunk3 = chunker.next()
        XCTAssertEqual(chunk3, [1, 0,0,0,42, 0,0,0,2, 7,8])

        let chunk4 = chunker.next()
        XCTAssertNil(chunk4)
    }

    func testIterator() {
        let chunker = try! Chunker(
            id: 42, data: Data.init(bytes: [1, 2, 3, 4, 5, 6, 7, 8]), chunkSize: 12
        )
        var chunks1 = [[UInt8]]();
        var chunks2 = [[UInt8]]();
        for chunk in chunker {
            chunks1.append(chunk)
        }
        for chunk in chunker {
            chunks2.append(chunk)
        }
        XCTAssertEqual(chunks1.count, 3)
        XCTAssertEqual(chunks2.count, 0)
    }

    static var allTests = [
        ("testInitChunkSize", testInitChunkSize),
        ("testInitData", testInitData),
        ("testHasNext", testHasNext),
        ("testNext", testNext),
        ("testIterator", testIterator),
    ]

}
