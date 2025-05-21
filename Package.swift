// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FolderWatch",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/aus-der-Technik/FileMonitor.git", from: "1.0.0"),
        .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0"),
        .package(url: "https://github.com/tomieq/Env", exact: "1.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FolderWatch",
            dependencies: [
                .product(name: "FileMonitor", package: "FileMonitor"),
                .product(name: "SwiftGD", package: "SwiftGD"),
                .product(name: "Env", package: "Env")
            ]),
    ]
)
