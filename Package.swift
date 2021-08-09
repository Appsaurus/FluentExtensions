// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FluentExtensions",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "FluentExtensions",
            targets: ["FluentExtensions"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
		.package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from:"4.0.0")),
		.package(url: "https://github.com/Appsaurus/CodableExtensions", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/Appsaurus/RuntimeExtensions", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/Appsaurus/SwiftTestUtils", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "FluentExtensions",
            dependencies: [.product(name: "Vapor", package: "vapor"),
                           .product(name: "Fluent", package: "fluent"),
                           .product(name: "CodableExtensions", package: "CodableExtensions"),
                           .product(name: "RuntimeExtensions", package: "RuntimeExtensions")]),
        .testTarget(
            name: "FluentExtensionsTests",
            dependencies: [.target(name: "FluentExtensions"),
                           .product(name: "SwiftTestUtils", package: "SwiftTestUtils")]),
    ]
)
