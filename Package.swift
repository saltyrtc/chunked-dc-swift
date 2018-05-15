// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ChunkedDC",
    products: [
        .library(name: "ChunkedDC", targets: ["ChunkedDC"]),
    ],
    targets: [
        .target(
            name: "ChunkedDC",
            path: "Sources"),
        .testTarget(
            name: "ChunkedDCTests",
            dependencies: ["ChunkedDC"]),
    ]
)
