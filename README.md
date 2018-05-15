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
