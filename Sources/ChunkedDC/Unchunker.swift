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
}

/// Delegate that will be called with the assembled message once all chunks arrived.
protocol MessageCompleteDelegate: AnyObject {
    func messageComplete(message: Data)
}

/// A chunk collector collects chunk belonging to the same message.
class ChunkCollector {
    private var endArrived: Bool = false
    private var messageLength: Int?
    private var chunks: [Chunk] = []
    private var lastUpdate = Date.init()

    /// Register a new incoming chunk for this message.
    func addChunk(chunk: Chunk) {
        self.chunks.append(chunk)
        self.lastUpdate = Date.init()
        if chunk.endOfMessage {
            self.endArrived = true
            self.messageLength = Int(chunk.serial) + 1
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
}

/// An Unchunker instance merges multiple chunks into a single `Data`.
class Unchunker {
    let messageComplete: MessageCompleteDelegate

    init(messageCompleteDelegate: MessageCompleteDelegate) {
        self.messageComplete = messageCompleteDelegate
    }
}
