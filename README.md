# Binary Chunking for Swift

[![CircleCI][circle-ci-badge]][circle-ci]
[![Maintainability][codeclimate-badge]][codeclimate]
[![Swift][swift-badge]][github]
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache%202.0-blue.svg)](https://github.com/saltyrtc/chunked-dc-swift)
[![Join our chat on Gitter](https://badges.gitter.im/saltyrtc/Lobby.svg)](https://gitter.im/saltyrtc/Lobby)

This library allows you to split up large binary messages into multiple chunks
of a certain size.

When converting data to chunks, a 9 byte header is prepended to each chunk.
This allows you to send the chunks to the receiver in any order.

While the library was written for use with WebRTC DataChannels, it can also be
used outside of that scope.

The full specification for the chunking format can be found
[here](https://github.com/saltyrtc/saltyrtc-meta/blob/master/Chunking.md).


## Generating an Xcode Project

Open the project directory on the command line, then run

    $ swift package generate-xcodeproj


## Usage

### Chunking

Create a new chunker:

```swift
let data = Data(bytes: [1, 2, 3, 4, 5, 6, 7, 8])
let chunker = try Chunker(id: 42, data: data, chunkSize: 12)
```

The `id` field contains the message id. You probably want to use an
incrementing counter to make sure that every message has its own message id.

The `chunkSize  should include the 9 byte header. Therefore it must be at
least 10 (resulting in 1 byte of data per chunk).

Now you can iterate over the chunks in the chunker.

```swift
for chunk in chunker {
    print!("Chunk is \(chunk)")
}
```

This will result in 3 chunks:

    Chunk is [0, 0, 0, 0, 42, 0, 0, 0, 0, 1, 2, 3]
    Chunk is [0, 0, 0, 0, 42, 0, 0, 0, 1, 4, 5, 6]
    Chunk is [1, 0, 0, 0, 42, 0, 0, 0, 2, 7, 8]

### Unchunking

Create an unchunker:

```swift
let unchunker = Unchunker()
```

The unchunker will notify you when a message is complete using a delegate:

```swift
class MessagePrintingDelegate: MessageCompleteDelegate {
    func messageComplete(message: Data) {
        print("Message is complete: \([UInt8](message))")
    }
}

// ...

unchunker.delegate = MessagePrintingDelegate()
```

For every chunk you receive, add it to the unchunker. You may also add chunks out-of-order.

```swift
try unchunker.addChunk(bytes: Data([0, 0,0,0,42, 0,0,0,0, 1,2,3]))
try unchunker.addChunk(bytes: Data([0, 0,0,0,42, 0,0,0,2, 7,8]))
try unchunker.addChunk(bytes: Data([0, 0,0,0,42, 0,0,0,1, 4,5,6]))
```

As soon as the message is complete, your delegate will be notified synchronously.

    Message is complete: [1, 2, 3, 4, 5, 6, 7, 8]

### Cleanup

Because the `Unchunker` instance needs to keep track of arrived chunks, it's
possible that incomplete messages add up and use a lot of memory without ever
being freed.

To avoid this, simply call the `Unchunker.gc(maxAge: TimeInterval)` method
regularly. It will remove all incomplete messages that haven't been updated for
more than the specified number of seconds. The method will return the number of
removed chunks.

```swift
let removedChunks = unchunker.gc(maxAge: 10.0)
```


## License

Licensed under either of

 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
   http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or
   http://opensource.org/licenses/MIT) at your option.

### Contributing

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall
be dual licensed as above, without any additional terms or conditions.


<!-- Badges -->
[circle-ci]: https://circleci.com/gh/saltyrtc/chunked-dc-swift/tree/master
[circle-ci-badge]: https://circleci.com/gh/saltyrtc/chunked-dc-swift/tree/master.svg?style=shield
[codeclimate]: https://codeclimate.com/github/saltyrtc/chunked-dc-swift/maintainability
[codeclimate-badge]: https://api.codeclimate.com/v1/badges/9e26eed055c83e7f3cc3/maintainability
[github]: https://github.com/saltyrtc/chunked-dc-swift
[swift-badge]: https://img.shields.io/badge/swift-4%2B-blue.svg?maxAge=3600
