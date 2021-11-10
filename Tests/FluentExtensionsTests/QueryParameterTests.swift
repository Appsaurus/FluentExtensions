//
//  QueryParameterTests.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
@testable import FluentTestModels

class QueryParameterTestSeeder: Migration {
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
            createUser.groupedFields.intField = index
            kitchenSinks.append(createUser)
        }
        return kitchenSinks.create(on: database)
    }
}
class QueryParameterTests: FluentTestModels.TestCase {
    let basePath = "query-parameters"
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

        router.get(basePath) { (request: Request) -> EventLoopFuture<[KitchenSink]> in
            return try KitchenSink.query(on: request.db)
                .filterByQueryParameters(request: request)
                .sorted(on: request)
                .all()
        }
    }


    func testReflect() throws {

        for property in Mirror(reflecting: TestGroupedFieldsModel()).children {
            print("name: \(String(describing: property.label)) type: \(type(of: property.value))")
        }

    }
    func testEqualsFieldQuery() throws {

        try app.test(.GET, "\(basePath)?stringField=eq:\(valueA)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 1)
            XCTAssertEqual(models[0].stringField, valueA)
        }
    }

    func testSubsetQueries() throws {
        let values = [valueA, valueB, valueC]
        try app.test(.GET, "\(basePath)?stringField=in:\(values.joined(separator: ","))") { response in
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

        try app.test(.GET, "\(basePath)?doubleField=eq:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 1)
            models.forEach({XCTAssert($0.doubleField == value)})
        }

        try app.test(.GET, "\(basePath)?doubleField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.doubleField > value)})
        }

        try app.test(.GET, "\(basePath)?doubleField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.doubleField < value)})
        }
    }

    func testIntFilters() throws {
        let value = 10

        try app.test(.GET, "\(basePath)?intField=eq:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 1)
            models.forEach({XCTAssert($0.intField == value)})
        }

        try app.test(.GET, "\(basePath)?intField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.intField > value)})
        }

        try app.test(.GET, "\(basePath)?intField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach({XCTAssert($0.intField < value)})
        }
    }

    func testBooleanEqualityQuery() throws {

        try app.test(.GET, "\(basePath)?booleanField=eq:false") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)

            XCTAssert(models.count == 13)
            models.forEach({XCTAssert($0.booleanField == false)})
        }
    }

    func testIntSort() throws {

        try app.test(.GET, "\(basePath)?sort=intField:asc") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.isSorted((\.intField, <)))
        }

        try app.test(.GET, "\(basePath)?sort=intField:desc") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.isSorted((\.intField, >)))
        }
    }

    func testNestedIntSort() throws {

        try app.test(.GET, "\(basePath)?sort=groupedFields_intField:asc") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.isSorted((\.groupedFields.intField, <)))
        }

        try app.test(.GET, "\(basePath)?sort=groupedFields_intField:desc") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.isSorted((\.groupedFields.intField, >)))
        }
    }

    func testRangeQueryStringParamsParsing() throws {
//        let dateStart: Date = "2016-06-05T16:56:57.019Z"
//        let dateEnd: Date = "2017-06-05T16:56:57.019Z"
//        let dateStringStart = dateStart.iso8601String
//        let dateStringEnd = dateEnd.iso8601String
//        let dateStringRange = "\(dateStringStart)...\(dateStringEnd)"
//        let dateRange = try ClosedRange<Date>(string: dateStringRange)
//        assert(dateRange == dateStart...dateEnd)
    }
}


extension Array {
    func isSorted<Value: Comparable>(_ predicate: (KeyPath<Element, Value>, (Value, Value) throws -> Bool)) -> Bool {
        guard count > 1 else { return true }
        return (try? zip(self, self.dropFirst()).allSatisfy({ (lhs, rhs) in
            return try predicate.1(lhs[keyPath: predicate.0], rhs[keyPath: predicate.0])
        })) == true
    }
}

