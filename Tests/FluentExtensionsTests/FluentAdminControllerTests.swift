//
//  FluentAdminControllerTests.swift
//
//
//  Created by Brian Strobach on 8/18/24.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerTests: FluentTestModels.TestCase {
    let basePath = "kitchen-sinks"
    
    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterTestSeeder())
    }
    
    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<KitchenSink>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
        
        for route in app.routes.all {
            debugPrint(route.path.string)
        }
    }
    
    func testCreate() throws {
        let newKitchenSink = KitchenSink(stringField: "New Item", intField: 100, doubleField: 100.5, booleanField: true)
        
        try app.test(.POST, basePath, beforeRequest: { req in
            try req.content.encode(newKitchenSink)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let createdModel = try response.content.decode(KitchenSink.self)
            XCTAssertNotNil(createdModel.id)
            XCTAssertEqual(createdModel.stringField, newKitchenSink.stringField)
            XCTAssertEqual(createdModel.intField, newKitchenSink.intField)
            XCTAssertEqual(createdModel.doubleField, newKitchenSink.doubleField)
            XCTAssertEqual(createdModel.booleanField, newKitchenSink.booleanField)
        })
    }
    
    func testRead() throws {
        try app.test(.GET, "\(basePath)/1") { response in
            XCTAssertEqual(response.status, .ok)
            let model = try response.content.decode(KitchenSink.self)
            XCTAssertEqual(model.id, 1)
            XCTAssertEqual(model.stringField, "StringValue_A")
        }
    }
    
    func testUpdate() throws {
        let updatedFields = KitchenSink(stringField: "Updated Item", intField: 200, doubleField: 200.5, booleanField: false)
        
        try app.test(.PUT, "\(basePath)/1", beforeRequest: { req in
            try req.content.encode(updatedFields)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedModel = try response.content.decode(KitchenSink.self)
            XCTAssertEqual(updatedModel.id, 1)
            XCTAssertEqual(updatedModel.stringField, updatedFields.stringField)
            XCTAssertEqual(updatedModel.intField, updatedFields.intField)
            XCTAssertEqual(updatedModel.doubleField, updatedFields.doubleField)
            XCTAssertEqual(updatedModel.booleanField, updatedFields.booleanField)
        })
    }
    
    func testDelete() throws {
        try app.test(.DELETE, "\(basePath)/1") { response in
            XCTAssertEqual(response.status, .ok)
        }
        
        try app.test(.GET, "\(basePath)/1") { response in
            XCTAssertEqual(response.status, .notFound)
        }
    }
    
    func testReadAll() throws {
        try app.test(.GET, "\(basePath)/all") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssertEqual(models.count, 26) // Assuming 26 items were seeded (A-Z)
        }
    }
    
    func testEqualsFieldQuery() throws {
        try app.test(.GET, "\(basePath)?stringField=eq:StringValue_A") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 1)
            XCTAssertEqual(models[0].stringField, "StringValue_A")
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
    
    func testSort() throws {
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
}

//extension Array {
//    func isSorted<Value: Comparable>(_ predicate: (KeyPath<Element, Value>, (Value, Value) throws -> Bool)) -> Bool {
//        guard count > 1 else { return true }
//        return (try? zip(self, self.dropFirst()).allSatisfy { try predicate.1($0[keyPath: predicate.0], $1[keyPath: predicate.0]) }) == true
//    }
//}
