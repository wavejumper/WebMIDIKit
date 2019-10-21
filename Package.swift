// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebMIDIKit",
    platforms: [
        .macOS(.v10_13), .iOS(.v12),
    ],
    products: [
        .library(
            name: "WebMIDIKit",
            targets: ["WebMIDIKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WebMIDIKit",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "WebMIDIKitTests",
            dependencies: [],
            path: "Tests"),
    ]
)
