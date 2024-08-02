//
//  SQLKitExtensionTests.swift
//
//
//  Created by Brian Strobach on 9/7/21.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import FluentExtensions

@testable import FluentTestModels

class SQLKitExtensionTests: FluentTestModels.TestCase {
    let basePath = "sql-kit-extension-tests"
    let valueA = "StringValue_A"
    let valueB = "StringValue_B"
    let valueC = "StringValue_C"

    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    override func addConfiguration(to app: Application) throws {
        try super.addConfiguration(to: app)
        app.logger.logLevel = .debug
    }

    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterTestSeeder())
    }

    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)

        router.get(basePath) { (request: Request) in
            return try KitchenSink.query(on: request.db)
                .filterByQueryParameters(request: request)
                .all()
        }
    }

    func testLabeledCountsGroupedBy() async throws {
        let counts = try await app.db
            .select()
            .labeledCountsGroupedBy(\KitchenSink.$optionalStringField)
            .get()
        XCTAssert(counts.count > 0)
        for count in counts {
            XCTAssert(count.value > 0)
        }
    }

    func testSum() async throws {
        let sum1 = try await app.db.select().sum(\KitchenSink.$intField).get()
        XCTAssertEqual(sum1, 325)
    }

    // Additional test methods can be added here, following the async/await pattern

    // Example of a test that might involve multiple operations
    func testMultipleOperations() async throws {
        // First operation
        let counts = try await app.db
            .select()
            .labeledCountsGroupedBy(\KitchenSink.$optionalStringField).get()
        XCTAssert(counts.count > 0)

        // Second operation
        let sum = try await app.db.select().sum(\KitchenSink.$intField).get()
        XCTAssertEqual(sum, 325)

        // You can add more operations or assertions as needed
    }

    // Commented out as in the original
    // func testGroupByRollup() async throws {
    //     let rollup = try await app.db
    //         .sqlSelect(from: KitchenSink.sqlTable)
    //         .column("*")
    //         .groupByRollup(\KitchenSink.$intField, \KitchenSink.$stringField).all()
    //     print("Rollup: \(rollup)")
    // }

    // You can add more test methods here as needed
}
