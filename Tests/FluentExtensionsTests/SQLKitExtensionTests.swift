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
@testable import FluentTestModels


class SQLKitExtensionTests: FluentTestModels.TestCase {
    let queryParamSortPath = "query-parameters-sort"
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
        migrations.add(QueryParameterSortTestSeeder())
    }

    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)

        router.get(queryParamSortPath) { (request: Request) -> EventLoopFuture<[KitchenSink]> in
            return try KitchenSink.query(on: request.db).filterByQueryParameters(request: request).all()
        }
    }


    func testLabeledCountsGroupedBy() throws {
        let counts = try app.db
            .sqlSelect()
            .labeledCountsGroupedBy(\KitchenSink.$optionalStringField).wait()
        XCTAssert(counts.count > 0)
        for count in counts {
            XCTAssert(count.value > 0)
        }

    }

    func testSum() throws {
        let sum = try app.db.sqlSelect().sum(\KitchenSink.$intField).wait()
        XCTAssertEqual(sum, 325)
    }

    //TODO: Probably need to limit this to MySQL/PostgreSQL
//    func testGroupByRollup() throws {
//
//        let rollup = try app.db
//            .sqlSelect(from: KitchenSink.sqlTable)
//            .column("*")
//            .groupByRollup(\KitchenSink.$intField, \KitchenSink.$stringField).all().wait()
//        print("Rollup: \(rollup)")
//    }
}

