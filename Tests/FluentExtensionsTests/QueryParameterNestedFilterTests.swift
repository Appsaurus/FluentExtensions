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
    
    var model: TestChildModel = TestChildModel()
    
    
}

final class BChildren: ModelAlias {
    var model: TestChildModel = TestChildModel()
    
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

class QueryParameterNestedFilterTests: FluentTestModels.TestCase {
    
    // Your base path for API endpoints
    let basePath = "parents"
    
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
    
        let controller = TestParentController(config: Controller.Config(baseRoute: [basePath]))
        try controller.registerRoutes(routes: router)
    }
    
    // Helper function to create filter URL
    func makeFilterURL(_ condition: TestFilterCondition) throws -> String {
        return "\(basePath)?filter=\(try condition.toURLQueryString())"
    }
    
    func getFilteredItems(_ condition: TestFilterCondition) async throws -> [TestParentModel] {
        let response = try await app.sendRequest(.GET, try makeFilterURL(condition))
        XCTAssertEqual(response.status, .ok)
        return try response.content.decode(Page<TestParentModel>.self).items
    }
    
    func testNestedChildFilter() async throws {
        // Test filtering parents based on child properties
        let condition = TestFilterCondition.field(
            "children",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "eq", "Child A").toURLQueryString())
        )
        
        let parent1ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 1").first()!.requireID()
        
        let models = try await getFilteredItems(condition)
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.id.equalToAny(of: [parent1ID]) })

    }
    
    func testNestedOptionalChildFilter() async throws {
        // Test filtering parents based on optional child properties
        let condition = TestFilterCondition.field(
            "optionalChildren",
            "filter",
            AnyCodable(try TestFilterCondition.field("name", "sw", "Optional").toURLQueryString())
        )
        
        let parent2ID = try await TestParentModel.query(on: request.db).filter(\.$name == "Parent 2").first()!.requireID()
        
        let models = try await getFilteredItems(.and([condition]))
        XCTAssertFalse(models.isEmpty)
        XCTAssert(models.allSatisfy { $0.id.equalToAny(of: [parent2ID]) })

    }
}

class QueryParameterNestedTestSeeder: AsyncMigration {
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
