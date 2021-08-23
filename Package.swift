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
        .library(
            name: "FluentTestUtils",
            targets: ["FluentTestUtils"]),
        .library(
            name: "FluentTestModels",
            targets: ["FluentTestModels"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
		.package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from:"4.0.0")),
        .package(url: "https://github.com/Appsaurus/VaporExtensions.git", .branch("vapor-4")),
		.package(url: "https://github.com/Appsaurus/CodableExtensions", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/Appsaurus/RuntimeExtensions", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", .upToNextMajor(from:"4.0.0")),
    ],
    targets: [
        .target(
            name: "FluentExtensions",
            dependencies: [.product(name: "Vapor", package: "vapor"),
                           .product(name: "Fluent", package: "fluent"),
                           .product(name: "CodableExtensions", package: "CodableExtensions"),
                           .product(name: "RuntimeExtensions", package: "RuntimeExtensions")]),
        .target(
            name: "FluentTestUtils",
            dependencies: [.product(name: "Fluent", package: "fluent"),
                           .product(name: "CodableExtensions", package: "CodableExtensions"),
                           .product(name: "RuntimeExtensions", package: "RuntimeExtensions"),
                           .product(name: "VaporTestUtils", package: "VaporExtensions")]),

        .target(
            name: "FluentTestModels",
            dependencies: [.target(name: "FluentTestUtils"),
                           .target(name: "FluentExtensions")]),
        .testTarget(
            name: "FluentExtensionsTests",
            dependencies: [.target(name: "FluentTestModels"),
                           .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")]),
    ]
)
