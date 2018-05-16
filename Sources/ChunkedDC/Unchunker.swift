/**
 * Copyright (c) 2018 Threema GmbH / SaltyRTC Contributors
 *
 * Licensed under the Apache License, Version 2.0, <see LICENSE-APACHE file> or
 * the MIT license <see LICENSE-MIT file>, at your option. This file may not be
 * copied, modified, or distributed except according to those terms.
 */

import Foundation

/// All errors that can occur inside the `Unchunker`.
enum UnchunkerError: Error {
    /// Not all chunks for a message have arrived yet
    case messageNotYetComplete
    /// A chunk collector can only collect chunks belonging to the same message
    case inconsistentMessageId
    /// Chunk is smaller than the header length
    case chunkTooSmall
}

/// Delegate that will be called with the assembled message once all chunks arrived.
protocol MessageCompleteDelegate: AnyObject {
    func messageComplete(message: Data)
}

/// A chunk.
struct Chunk {
    let endOfMessage: Bool
    let id: UInt32
    let serial: UInt32
    let data: [UInt8]

    /// Create a new chunk.
    init(endOfMessage: Bool, id: UInt32, serial: UInt32, data: [UInt8]) {
        self.endOfMessage = endOfMessage
        self.id = id
        self.serial = serial
        self.data = data
    }

    /// Parse bytes into a chunk.
    /// Throws an `UnchunkerError` if the chunk is smaller than the header length.
    init(bytes: Data) throws {
        if bytes.count < Common.headerLength {
            throw UnchunkerError.chunkTooSmall
        }

        // Read header
        let options: UInt8 = bytes[0]
        self.endOfMessage = (options & 0x01) == 1
        self.id = (UInt32(bytes[1]) << 24) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 8) | UInt32(bytes[4])
        self.serial = (UInt32(bytes[5]) << 24) | (UInt32(bytes[6]) << 16) | (UInt32(bytes[7]) << 8) | UInt32(bytes[8])

        // Read data
        self.data = [UInt8](bytes[9..<bytes.count])
    }
}

extension Chunk: Comparable {
    static func < (lhs: Chunk, rhs: Chunk) -> Bool {
        if lhs.id == rhs.id {
            return lhs.serial < rhs.serial
        } else {
            return lhs.id < rhs.id
        }
    }

    static func == (lhs: Chunk, rhs: Chunk) -> Bool {
        return lhs.endOfMessage == rhs.endOfMessage
            && lhs.id == rhs.id
            && lhs.serial == rhs.serial
            && lhs.data == rhs.data
    }
}

/// A chunk collector collects chunk belonging to the same message.
///
/// This class is thread safe.
class ChunkCollector {
    private var endArrived: Bool = false
    private var messageLength: Int?
    private var chunks: [Chunk] = []
    private var lastUpdate = Date.init()
    private let serialQueue = DispatchQueue(label: "merge")

    /// Register a new incoming chunk for this message.
    func addChunk(chunk: Chunk) throws {
        try self.serialQueue.sync {
            // Make sure that chunk belongs to the same message
            if !self.chunks.isEmpty && chunk.id != self.chunks[0].id {
                throw UnchunkerError.inconsistentMessageId
            }

            // Store the chunk
            self.chunks.append(chunk)

            // Update internal state
            self.lastUpdate = Date.init()
            if chunk.endOfMessage {
                self.endArrived = true
                self.messageLength = Int(chunk.serial) + 1
            }
        }
    }

    /// Return whether the message is complete, meaning that all chunks of the message arrived.
    func isComplete() -> Bool {
        return self.endArrived
            && self.chunks.count == self.messageLength
    }

    /// Return whether last chunk is older than the specified interval.
    func isOlderThan(interval: TimeInterval) -> Bool {
        let age = Date.init().timeIntervalSince(self.lastUpdate)
        return age > interval
    }

    /// Merge the chunks into a complete message.
    ///
    /// :returns: The assembled message `Data`
    func merge() throws -> Data {
        return try self.serialQueue.sync {
            // Preconditions
            if !self.isComplete() {
                throw UnchunkerError.messageNotYetComplete
            }

            // Sort chunks in-place
            self.chunks.sort()

            // Allocate buffer
            let capacity = self.chunks[0].data.count * self.messageLength!
            var data = Data.init(capacity: capacity)

            // Add chunks to buffer
            for chunk in self.chunks {
                data.append(contentsOf: chunk.data)
            }

            return data
        }
    }
}

/// An Unchunker instance merges multiple chunks into a single `Data`.
class Unchunker {
    let messageComplete: MessageCompleteDelegate

    init(messageCompleteDelegate: MessageCompleteDelegate) {
        self.messageComplete = messageCompleteDelegate
    }
}
