// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "jjstats",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "jjstats",
            path: "Sources/jjstats"
        ),
    ]
)
