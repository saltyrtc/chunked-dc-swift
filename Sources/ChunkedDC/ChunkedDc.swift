/**
 * Copyright (c) 2018 Threema GmbH / SaltyRTC Contributors
 *
 * Licensed under the Apache License, Version 2.0, <see LICENSE-APACHE file> or
 * the MIT license <see LICENSE-MIT file>, at your option. This file may not be
 * copied, modified, or distributed except according to those terms.
 */

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
