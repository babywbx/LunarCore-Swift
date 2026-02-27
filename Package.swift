// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LunarCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LunarCore",
            targets: ["LunarCore"]
        ),
    ],
    targets: [
        .target(
            name: "LunarCore"
        ),
        .executableTarget(
            name: "GenerateData",
            dependencies: ["LunarCore"]
        ),
        .testTarget(
            name: "LunarCoreTests",
            dependencies: ["LunarCore"],
            exclude: ["Fixtures"]
        ),
    ]
)
