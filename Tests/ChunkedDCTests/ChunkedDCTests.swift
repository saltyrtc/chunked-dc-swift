import XCTest
@testable import ChunkedDC

final class ChunkTests: XCTestCase {
    func testEquality() {
        let c1 = Chunk(endOfMessage: true, id: 0, serial: 1, data: [])
        let c2 = Chunk(endOfMessage: true, id: 0, serial: 1, data: [])
        let c3 = Chunk(endOfMessage: true, id: 0, serial: 1, data: [1])
        let c4 = Chunk(endOfMessage: true, id: 1, serial: 1, data: [])

        XCTAssertEqual(c1, c1)
        XCTAssertEqual(c2, c2)
        XCTAssertEqual(c3, c3)
        XCTAssertEqual(c4, c4)

        XCTAssertEqual(c1, c2)

        XCTAssertNotEqual(c1, c3)
        XCTAssertNotEqual(c1, c4)
        XCTAssertNotEqual(c2, c3)
        XCTAssertNotEqual(c2, c4)
        XCTAssertNotEqual(c3, c4)
        XCTAssertNotEqual(c4, c3)
    }

    func testComparison() {
        let c1 = Chunk(endOfMessage: true, id: 1, serial: 1, data: [])
        let c2 = Chunk(endOfMessage: true, id: 1, serial: 2, data: [])
        let c3 = Chunk(endOfMessage: true, id: 0, serial: 3, data: [])
        XCTAssertLessThan(c1, c2)
        XCTAssertGreaterThan(c2, c3)
        XCTAssertLessThan(c3, c1)
    }

    func testParseValid() {
        let c1 = try! Chunk(bytes: Data.init([0, 0,0,0,42, 0,0,0,0, 1,2,3]))
        let c2 = try! Chunk(bytes: Data.init([0, 0,0,0,42, 0,0,0,1, 4,5,6]))
        let c3 = try! Chunk(bytes: Data.init([1, 1,2,3,42, 2,3,4,5, 7,8]))
        let c4 = try! Chunk(bytes: Data.init([0, 0,0,0,00, 0,0,0,0]))

        XCTAssert(!c1.endOfMessage)
        XCTAssert(!c2.endOfMessage)
        XCTAssert( c3.endOfMessage)
        XCTAssert(!c4.endOfMessage)

        XCTAssertEqual(c1.id, 42)
        XCTAssertEqual(c2.id, 42)
        XCTAssertEqual(c3.id, 16909098)
        XCTAssertEqual(c4.id, 0)

        XCTAssertEqual(c1.serial, 0)
        XCTAssertEqual(c2.serial, 1)
        XCTAssertEqual(c3.serial, 33752069)
        XCTAssertEqual(c4.serial, 0)

        XCTAssertEqual(c1.data, [1,2,3])
        XCTAssertEqual(c2.data, [4,5,6])
        XCTAssertEqual(c3.data, [7,8])
        XCTAssertEqual(c4.data, [])
    }

    func testParseTooShort() {
        XCTAssertThrowsError(try Chunk(bytes: Data([0,0,0,0,0,0,0,0]))) { error in
            guard let thrownError = error as? UnchunkerError else {
                XCTFail("Threw wrong type of error")
                return
            }
            switch thrownError {
            case .chunkTooSmall:
                return
            default:
                XCTFail("Threw wrong error")
            }
        }
    }

    static var allTests = [
        ("equality", testEquality),
        ("comparison", testComparison),
        ("parseValid", testParseValid),
        ("parseTooShort", testParseTooShort),
    ]
}

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
        ("initChunkSize", testInitChunkSize),
        ("initData", testInitData),
        ("hasNext", testHasNext),
        ("next", testNext),
        ("iterator", testIterator),
    ]

}

final class UnchunkerTests: XCTestCase {

    func testCollectorIsComplete() {
        let collector = ChunkCollector.init()
        XCTAssert(!collector.isComplete())
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 13, serial: 0, data: []))
        XCTAssert(!collector.isComplete())
        try! collector.addChunk(chunk: Chunk(endOfMessage: true, id: 13, serial: 2, data: []))
        XCTAssert(!collector.isComplete())
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 13, serial: 1, data: []))
        XCTAssert(collector.isComplete())
    }

    func testCollectorIsOlderThan() {
        let collector = ChunkCollector.init()
        let startDate = Date.init()
        XCTAssert(!collector.isOlderThan(interval: 0.2), "Initially the collector should not be old")
        while Date.init().timeIntervalSince(startDate) < 0.2 {
            /* busy loop */
        }
        XCTAssert(collector.isOlderThan(interval: 0.2), "Collector should be older than 0.2s")
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 13, serial: 0, data: []))
        XCTAssert(!collector.isOlderThan(interval: 0.2), "Collector lastUpdate should have been updated")
    }

    func testMerge() {
        let collector = ChunkCollector.init()
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 42, serial: 0, data: [1,2,3]))
        try! collector.addChunk(chunk: Chunk(endOfMessage: true, id: 42, serial: 2, data: [7,8]))
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 42, serial: 1, data: [4,5,6]))
        let assembled: Data? = try? collector.merge()
        XCTAssertEqual(assembled, Data.init([1,2,3,4,5,6,7,8]))
    }

    func testMergeFails() {
        let collector = ChunkCollector.init()
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 42, serial: 0, data: [1,2,3]))
        try! collector.addChunk(chunk: Chunk(endOfMessage: true, id: 42, serial: 2, data: [7,8]))

        // Chunk with serial 1 is missing, therefore merging should fail

        XCTAssertThrowsError(try collector.merge()){ error in
            guard let thrownError = error as? UnchunkerError else {
                XCTFail("Threw wrong type of error")
                return
            }
            switch thrownError {
            case .messageNotYetComplete:
                return
            default:
                XCTFail("Threw wrong error")
            }
        }
    }

    func testIdValidation() {
        let collector = ChunkCollector.init()
        try! collector.addChunk(chunk: Chunk(endOfMessage: false, id: 42, serial: 0, data: [1,2,3]))
        XCTAssertThrowsError(try
            collector.addChunk(chunk: Chunk(endOfMessage: true, id: 23, serial: 1, data: [4,5]))
        ){ error in
            guard let thrownError = error as? UnchunkerError else {
                XCTFail("Threw wrong type of error")
                return
            }
            switch thrownError {
            case .inconsistentMessageId:
                return
            default:
                XCTFail("Threw wrong error")
            }
        }
    }

    static var allTests = [
        ("collectorIsComplete", testCollectorIsComplete),
        ("collectorIsOlderThan", testCollectorIsOlderThan),
        ("merge", testMerge),
        ("mergeFails", testMergeFails),
        ("idValidation", testIdValidation),
    ]
}
