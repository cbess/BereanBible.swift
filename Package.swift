// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dbPath = "bsb-interlinear.db"
let package = Package(
    name: "BereanBible",
    platforms: [
        .iOS(.v12),
        .macOS(.v12),
        .watchOS(.v7),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "BereanBible",
            targets: ["BereanBible"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.14.1")
    ],
    targets: [
        .target(
            name: "BereanBible",
            dependencies: [.product(name: "SQLite", package: "SQLite.swift")],
            resources: [.copy(dbPath)]),
        .testTarget(
            name: "BereanBibleTests",
            dependencies: ["BereanBible"],
            resources: [.copy(dbPath)]),
    ]
)
