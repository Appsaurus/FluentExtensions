//
//  QueryParameterNestedSiblingFilterTests.swift
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

let basePath = "classes"
class TestClassController: FluentAdminController<TestClassModel> {
    
    public override init(config: Config = Config(baseRoute: [basePath])) {
        super.init(config: config)
        parameterFilterConfig.nestedBuilders = [
            "students": QueryParameterFilter.Siblings(\TestClassModel.$students)
        ]
    }
}

class QueryParameterSiblingFilterTests: FluentAdminControllerTestCase {
    
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = TestClassController()
        controller.siblingCRUDRoutes(router.grouped(basePath),
                                     relationshipName: "students",
                                     through: \.$students,
                                     siblingController: FluentAdminController<TestStudentModel>())
        try router.register(controller)
        
    }
    
    // Helper function to create filter URL
    func makeFilterURL(_ condition: TestFilterCondition) throws -> String {
        return "\(basePath)?filter=\(try condition.toURLQueryString())"
    }
    
    func getFilteredItems(_ condition: TestFilterCondition) async throws -> [TestClassModel] {
        let response = try await app.sendRequest(.GET, try makeFilterURL(condition))
        XCTAssertEqual(response.status, .ok)
        return try response.content.decode(Page<TestClassModel>.self).items
    }
    
    func testNestedSiblingFilter() async throws {
        // Test filtering students based on their classes
        let testUUID = AnyCodable(FluentAdminControllerTestCase.student1UUID.uuidString)
        let condition = TestFilterCondition.field(
            "students",
            "filter",
            AnyCodable(try TestFilterCondition.field("id", "eq", testUUID).toURLQueryString())
        )
        
        
        let classes = try await getFilteredItems(condition)
        XCTAssertTrue(classes.count == 1)
        // Verify that filtered students are enrolled in the specified class
        XCTAssert(try classes.first?.requireID() == FluentAdminControllerTestCase.classUUID)
        
        
    }
}



