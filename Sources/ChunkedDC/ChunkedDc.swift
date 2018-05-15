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

/// Chunker instance splits up a `Data` instance into multiple chunks.
///
/// The Chunker is initialized with an ID. For each message to be chunked, a
/// new Chunker instance is required.
struct Chunker {
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
        self.chunkDataSize = chunkSize
    }

    func hasNext() -> Bool {
        let currentIndex = chunkId * chunkDataSize
        let remaining = data.count - Int(currentIndex)
        return remaining >= 1
    }
}
