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
import Codability
import VaporExtensions

@testable import FluentTestModels

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
        router.get(basePath) { (request: Request) async throws -> [KitchenSink] in
            try await KitchenSink.query(on: request.db)
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
            models.forEach { XCTAssert($0.doubleField == value) }
        }
        
        try app.test(.GET, "\(basePath)?doubleField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach { XCTAssert($0.doubleField > value) }
        }
        
        try app.test(.GET, "\(basePath)?doubleField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach { XCTAssert($0.doubleField < value) }
        }
    }
    
    func testIntFilters() throws {
        let value = 10
        
        try app.test(.GET, "\(basePath)?intField=eq:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 1)
            models.forEach { XCTAssert($0.intField == value) }
        }
        
        try app.test(.GET, "\(basePath)?intField=gt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach { XCTAssert($0.intField > value) }
        }
        
        try app.test(.GET, "\(basePath)?intField=lt:\(value)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            models.forEach { XCTAssert($0.intField < value) }
        }
    }
    
    func testBooleanEqualityQuery() throws {
        try app.test(.GET, "\(basePath)?booleanField=eq:false") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 13)
            models.forEach { XCTAssert($0.booleanField == false) }
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
}


extension Array {
    func isSorted<Value: Comparable>(_ predicate: (KeyPath<Element, Value>, (Value, Value) throws -> Bool)) -> Bool {
        guard count > 1 else { return true }
        return (try? zip(self, self.dropFirst()).allSatisfy { try predicate.1($0[keyPath: predicate.0], $1[keyPath: predicate.0]) }) == true
    }
}
