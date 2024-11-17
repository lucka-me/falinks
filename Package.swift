// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Falinks",
    platforms: [ .macOS(.v15) ],
    products: [
        .executable(
            name: "falinks",
            targets: [ "Command" ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/mapbox/turf-swift.git", from: "2.8.0"),
        .package(url: "https://github.com/lucka-me/sphere-geometry-swift.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Generator",
            dependencies: [
                .product(name: "SphereGeometry", package: "sphere-geometry-swift"),
                .product(name: "Turf", package: "turf-swift"),
                .target(name: "OverpassKit"),
                .target(name: "SphereCoverer"),
            ]
        ),
        .target(name: "OverpassKit"),
        .target(
            name: "SphereCoverer",
            dependencies: [
                .product(name: "SphereGeometry", package: "sphere-geometry-swift"),
                .product(name: "Turf", package: "turf-swift"),
            ],
            path: "Sources/Coverer"
        ),
        .executableTarget(
            name: "Command",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "Generator")
            ]
        ),
    ]
)
