// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FluentExtensions",
    products: [
        .library(
            name: "FluentExtensions",
            targets: ["FluentExtensions"]),
    ],
    dependencies: [
		.package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0")),
		.package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from:"3.0.0")),
		.package(url: "https://github.com/Appsaurus/CodableExtensions", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/Appsaurus/RuntimeExtensions", .upToNextMajor(from: "0.1.0")),
		.package(url: "https://github.com/Appsaurus/FluentTestUtils", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "FluentExtensions",
            dependencies: ["Vapor", "Fluent", "CodableExtensions", "RuntimeExtensions"]),
        .testTarget(
            name: "FluentExtensionsTests",
            dependencies: ["FluentExtensions", "FluentTestUtils"]),
    ]
)
