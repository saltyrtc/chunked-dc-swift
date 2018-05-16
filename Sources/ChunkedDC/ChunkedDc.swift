import Foundation

/// Commonly used constants.
struct Common {
    static let headerLength: UInt32 = 9
}

/// A chunk.
struct Chunk {
    let endOfMessage: Bool
    let id: UInt32
    let serial: UInt32
    let data: [UInt8]
}

/// All errors that can occur inside the `Chunker`.
enum ChunkerError: Error {
    /// The chunk size must be at least 10 bytes.
    case chunkSizeTooSmall

    /// The data to be chunked must not be empty.
    case dataEmpty
}

/// A `Chunker` splits up a `Data` instance into multiple chunks.
///
/// The `Chunker` is initialized with an ID. For each message to be chunked, a
/// new `Chunker` instance is required.
///
/// This type implements `Sequence` and `IteratorProtocol`, so it can be
/// iterated over (but only once, after which it has been consumed).
class Chunker: Sequence, IteratorProtocol {
    private let id: UInt32
    private let data: Data
    private let chunkDataSize: UInt32
    private var chunkId: UInt32 = 0

    init(id: UInt32, data: Data, chunkSize: UInt32) throws {
        if chunkSize < Common.headerLength + 1 {
            throw ChunkerError.chunkSizeTooSmall
        }
        if data.isEmpty {
            throw ChunkerError.dataEmpty
        }
        self.id = id
        self.data = data
        self.chunkDataSize = chunkSize - Common.headerLength
    }

    func hasNext() -> Bool {
        let currentIndex = chunkId * chunkDataSize
        let remaining = data.count - Int(currentIndex)
        return remaining >= 1
    }

    func next() -> [UInt8]? {
        if !self.hasNext() {
            return nil
        }

        // Allocate chunk buffer
        let currentIndex = Int(self.chunkId * self.chunkDataSize)
        let remaining = self.data.count - currentIndex
        let effectiveChunkDataSize = Swift.min(remaining, Int(self.chunkDataSize))
        var chunk = [UInt8](repeating: 0, count: effectiveChunkDataSize + Int(Common.headerLength))

        // Write options
        let options: UInt8 = remaining > effectiveChunkDataSize ? 0 : 1
        chunk[0] = options

        // Write id
        chunk[1] = UInt8((self.id >> 24) & 0xff)
        chunk[2] = UInt8((self.id >> 16) & 0xff)
        chunk[3] = UInt8((self.id >> 8) & 0xff)
        chunk[4] = UInt8(self.id & 0xff)

        // Write serial
        let serial: UInt32 = self.nextSerial()
        chunk[5] = UInt8((serial >> 24) & 0xff)
        chunk[6] = UInt8((serial >> 16) & 0xff)
        chunk[7] = UInt8((serial >> 8) & 0xff)
        chunk[8] = UInt8(serial & 0xff)

        // Write chunk data
        for i in 0..<effectiveChunkDataSize {
            chunk[i + 9] = self.data[currentIndex + i]
        }

        return chunk
    }

    func makeIterator() -> Chunker {
        return self
    }

    /// Return and post-increment the id of the next block
    private func nextSerial() -> UInt32 {
        let serial = self.chunkId
        self.chunkId += 1
        return serial
    }
}
