// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FluentExtensions",
    platforms: [
        .macOS(.v12),
//        .iOS(.v13),
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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent.git", from:"4.0.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from:"1.0.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.1.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from:"4.0.0"),
        .package(url: "https://github.com/Appsaurus/Swiftest.git", from: "1.0.0"),
//        .package(url: "https://github.com/Appsaurus/VaporExtensions.git", from: "1.0.5"),
        .package(url: "https://github.com/Appsaurus/VaporExtensions.git", from: "1.2.0"),
		.package(url: "https://github.com/Appsaurus/CodableExtensions", from: "1.1.0"),
        .package(url: "https://github.com/Appsaurus/RuntimeExtensions", branch: "1.1.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit", exact: "0.2.0"),

    ],
    targets: [
        .target(
            name: "FluentExtensions",
            dependencies: [.product(name: "Vapor", package: "vapor"),
                           .product(name: "Fluent", package: "fluent"),
                           .product(name: "FluentSQL", package: "fluent-kit"),
                           .product(name: "SQLKit", package: "sql-kit"),
                           .product(name: "Swiftest", package: "Swiftest"),
                           .product(name: "VaporExtensions", package: "VaporExtensions"),
                           .product(name: "CodableExtensions", package: "CodableExtensions"),
                           .product(name: "RuntimeExtensions", package: "RuntimeExtensions"),
                           .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit")
                          ]),
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
