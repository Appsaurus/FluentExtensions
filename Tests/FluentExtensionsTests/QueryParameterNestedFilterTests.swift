//
//  QueryParameterNestedFilterTests.swift
//
//
//  Created by Brian Strobach on 1/15/25.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import Codability
import FluentExtensions
@testable import FluentTestModels


final class AChildren: ModelAlias {
    static var name: String = "children"
    
    let model: TestChildModel = TestChildModel()
    
    
}

final class BChildren: ModelAlias {
    let model: TestChildModel = TestChildModel()
    
    static var name: String = "optionalChildren"
    
    
}

class TestParentController: FluentAdminController<TestParentModel> {
    public override init(config: Config = Config()) {
        super.init(config: config)
        queryParameterFilterOverrides = [
            "optionalChildren": QueryFilterBuilder.Child(\TestChildModel.$optionalParent),
            "children": QueryFilterBuilder.Child(\TestChildModel.$parent)
        ]
    }
}


class TestChildController: FluentAdminController<TestChildModel> {
    public override init(config: Config = Config()) {
        super.init(config: config)
        queryParameterFilterOverrides = [
            "parent": QueryFilterBuilder.Parent(\TestChildModel.$parent),
            "optionalParent": QueryFilterBuilder.Parent(\TestChildModel.$optionalParent)
        ]
    }
}


class QueryParameterNestedFilterTests: FluentTestModels.TestCase {
    
    // Base paths for API endpoints
    let parentBasePath = "parents"
    let childBasePath = "children"
    
    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterNestedTestSeeder())
    }
    
    override func configureTestModelDatabase(_ databases: Databases) {
        
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
        
    }
    
    override func addConfiguration(to app: Application) throws {
        app.logger.logLevel = .debug
        try super.addConfiguration(to: app)
        
    }
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let parentController = TestParentController(config: Controller.Config(baseRoute: [parentBasePath]))
        let childController = TestChildController(config: Controller.Config(baseRoute: [childBasePath]))
        
        try parentController.registerRoutes(routes: router)
        try childController.registerRoutes(routes: router)
    }
    
    // Generic helper function to create filter URL
    func makeFilterURL(basePath: String, _ condition: TestFilterCondition) throws -> String {
        return "\(basePath)?filter=\(try condition.toURLQueryString())"
    }
    
    // Generic helper function to get filtered items
    func getFilteredItems<T: Content>(_ condition: TestFilterCondition, basePath: String) async throws -> [T] {
        let response = try await app.sendRequest(.GET, try makeFilterURL(basePath: basePath, condition))
        XCTAssertEqual(response.status, .ok)
        return try response.content.decode(Page<T>.self).items
    }
    
    // Parent model tests
    func testNestedChildFilter() async throws {
        // Test filtering parents based on child properties
        let condition = TestFilterCondition.field(
            "children",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "eq", "Child A").toURLQueryString())
        )
        
        let parent1ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 1").first()!.requireID()
        let parent2ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 2").first()!.requireID()
        
        let models: [TestParentModel] = try await getFilteredItems(condition, basePath: parentBasePath)
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.id.equalToAny(of: [parent1ID]) })
        
        // Negative test case: ensure Parent 2 is not included
        XCTAssertFalse(models.contains { $0.id == parent2ID })
        XCTAssertEqual(models.count, 1) // Should only return one parent
    }
    
    func testNestedOptionalChildFilter() async throws {
        // Test filtering parents based on optional child properties
        let condition = TestFilterCondition.field(
            "optionalChildren",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "eq", "Optional Child").toURLQueryString())
        )
        
        let parent1ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 1").first()!.requireID()
        let parent2ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 2").first()!.requireID()
        
        let models: [TestParentModel] = try await getFilteredItems(condition, basePath: parentBasePath)
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.id.equalToAny(of: [parent2ID]) })
        
        // Negative test case: ensure Parent 1 is not included
        XCTAssertFalse(models.contains { $0.id == parent1ID })
        XCTAssertEqual(models.count, 1) // Should only return one parent
    }
    
    // Child model tests
    func testParentFilter() async throws {
        // Test filtering children based on parent properties
        let condition = TestFilterCondition.field(
            "parent",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "eq", "Parent 1").toURLQueryString())
        )
        
        let models: [TestChildModel] = try await getFilteredItems(condition, basePath: childBasePath)
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.name.contains("Child A") || $0.name.contains("Optional Child") })
        
        // Negative test case: ensure no children of Parent 2 are included
        XCTAssertFalse(models.contains { $0.name == "Child B" })
        XCTAssertEqual(models.count, 3) // Should return three children (Child A and two Optional Children)
    }
    
    func testOptionalParentFilter() async throws {
        // Test filtering children based on optional parent properties
        let condition = TestFilterCondition.field(
            "optionalParent",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "eq", "Parent 2").toURLQueryString())
        )
        
        let models: [TestChildModel] = try await getFilteredItems(condition, basePath: childBasePath)
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.name.contains("Optional Child") })
        
        // Negative test case: ensure non-optional children are not included
        XCTAssertFalse(models.contains { $0.name == "Child A" || $0.name == "Child B" })
        XCTAssertEqual(models.count, 2) // Should only return two optional children
    }
}

final class QueryParameterNestedTestSeeder: AsyncMigration {
    func prepare(on database: Database) async throws {

        let parent1 = TestParentModel(name: "Parent 1")
        let parent2 = TestParentModel(name: "Parent 2")
        
        try await parent1.create(on: database)
        try await parent2.create(on: database)
        
        let child1 = TestChildModel(name: "Child A", parentID: try parent1.requireID())
        let child2 = TestChildModel(name: "Child B", parentID: try parent2.requireID())
        let child3 = TestChildModel(name: "Optional Child", parentID: try parent1.requireID(),
                                    optionalParentID: try parent2.requireID())
        let child4 = TestChildModel(name: "Optional Child A", parentID: try parent1.requireID(),
                                    optionalParentID: try parent2.requireID())
        
        try await child1.create(on: database)
        try await child2.create(on: database)
        try await child3.create(on: database)
        try await child4.create(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await TestChildModel.query(on: database).delete()
        try await TestParentModel.query(on: database).delete()
    }
}
