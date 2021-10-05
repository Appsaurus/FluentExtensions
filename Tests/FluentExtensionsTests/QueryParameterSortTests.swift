//
//  QueryParameterSortTests.swift
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


class QueryParameterSortTestSeeder: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        seedModels(on: database)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture({}())
    }

    func seedModels(on database: Database) -> EventLoopFuture<Void> {
        var kitchenSinks: [KitchenSink] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for (index, letter) in letters.enumerated() {
            let createUser = KitchenSink()
            createUser.stringField += "_\(letter)"
            createUser.intField = index
            createUser.doubleField = Double(index)
            createUser.optionalStringField = index < 3 ? String(letter) : nil
            createUser.booleanField = index % 2 == 0
            kitchenSinks.append(createUser)
        }
        return kitchenSinks.create(on: database)
    }
}
class QueryParameterSortTests: FluentTestModels.TestCase {
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


    func testEqualsFieldQuery() throws {

        try app.test(.GET, "\(queryParamSortPath)?stringField=eq:\(valueA)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 1)
            XCTAssertEqual(models[0].stringField, valueA)
        }
    }

    func testSubsetQueries() throws {
        let values = [valueA, valueB, valueC]
        try app.test(.GET, "\(queryParamSortPath)?stringField=in:\(values.joined(separator: ","))") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 3)
            XCTAssertEqual(models[0].stringField, valueA)
            XCTAssertEqual(models[1].stringField, valueB)
            XCTAssertEqual(models[2].stringField, valueC)
        }
    }

    func testDoubleFilters() throws {
        let value = 10.0

        try app.test(.GET, "\(queryParamSortPath)?doubleField=eq:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 1)
            models.forEach({XCTAssert($0.doubleField == value)})
        }

        try app.test(.GET, "\(queryParamSortPath)?doubleField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.doubleField > value)})
        }

        try app.test(.GET, "\(queryParamSortPath)?doubleField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.doubleField < value)})
        }
    }

    func testIntFilters() throws {
        let value = 10

        try app.test(.GET, "\(queryParamSortPath)?intField=eq:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 1)
            models.forEach({XCTAssert($0.intField == value)})
        }

        try app.test(.GET, "\(queryParamSortPath)?intField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.intField > value)})
        }

        try app.test(.GET, "\(queryParamSortPath)?intField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.intField < value)})
        }
    }

    func testBooleanEqualityQuery() throws {

        try app.test(.GET, "\(queryParamSortPath)?booleanField=eq:false") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 13)
            models.forEach({XCTAssert($0.booleanField == false)})
        }
    }
}

