import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import Codability
import FluentExtensions
@testable import FluentTestModels

class QueryParameterFilterTests: FluentTestModels.TestCase {
    
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
        
        let controller = FluentAdminController<KitchenSink> {
            $0.baseRoute = [basePath]
        }
        try router.register(controller)
    }
    
    func getFilteredItems(_ condition: TestFilterCondition) async throws -> [KitchenSink] {
        return try await self.getFilteredItems(basePath: basePath, condition)
    }
    
    func testSimpleEqualityFilter() async throws {
        let models = try await getFilteredItems(.field("stringField", "eq", "StringValue_A"))
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models[0].stringField, "StringValue_A")
    }
    
    func testLogicalOperators() async throws {
        // Test AND condition
        let lowerBound = 5
        let upperBound = 15
        let andModels = try await getFilteredItems(.and([
            .field("intField", "gt", AnyCodable(lowerBound)),
            .field("intField", "lt", AnyCodable(upperBound))
        ]))
        XCTAssertEqual(andModels.count, upperBound - lowerBound - 1)
        XCTAssert(andModels.allSatisfy { $0.intField > lowerBound && $0.intField < upperBound })
        
        // Test OR condition
        let orModels = try await getFilteredItems(.or([
            .field("stringField", "eq", "StringValue_A"),
            .field("stringField", "eq", "StringValue_B")
        ]))
        XCTAssertEqual(orModels.count, 2)
        XCTAssert(orModels.allSatisfy { $0.stringField == "StringValue_A" || $0.stringField == "StringValue_B" })
    }
    
    func testNestedLogicalOperators() async throws {
        let models = try await getFilteredItems(.and([
            .field("booleanField", "eq", false),
            .or([
                .field("intField", "gt", 10),
                .field("doubleField", "lt", 5.0)
            ])
        ]))
        XCTAssert(models.count > 0)
        XCTAssert(models.allSatisfy { $0.booleanField == false && ($0.intField > 10 || $0.doubleField < 5.0) })
    }
    
    func testMultipleFieldTypes() async throws {
        let models = try await getFilteredItems(.and([
            .field("stringField", "sw", "String"),
            .field("intField", "gte", 10),
            .field("booleanField", "eq", true)
        ]))
        XCTAssert(models.count > 0)
        XCTAssert(models.allSatisfy { $0.stringField.starts(with: "String") && $0.intField >= 10 && $0.booleanField })
    }
    
//    func testStringInputResiliency() async throws {
//        let models = try await getFilteredItems(.and([
//            .field("intField", "gte", "10"),
//            .field("booleanField", "eq", "false")
//        ]), basePath: basePath)
//        XCTAssert(models.count > 0)
//        XCTAssert(models.allSatisfy { $0.intField >= 10 && $0.booleanField == false })
//    }
//
//    func testStringInputResiliency2() async throws {
//        let response = try await app.sendRequest(.GET, "\(basePath)?filter=\(#"{"field":"booleanField","method":"eq","value":"true"}"#)")
//        XCTAssertEqual(response.status, .ok)
//        let models = try response.content.decode(Page<KitchenSink>.self).items
//        XCTAssert(models.count > 0)
//        XCTAssert(models.allSatisfy { $0.booleanField == false })
//    }
    
    
    
    func testNestedFields() async throws {
        let models = try await getFilteredItems(.field("groupedFields_intField", "gt", 5))
        XCTAssert(models.count > 0)
        XCTAssert(models.allSatisfy { $0.groupedFields.intField > 5 })
    }
    
    func testStringOperations() async throws {
        // Test contains
        let containsModels = try await getFilteredItems(.field("stringField", "ct", "Value"))
        XCTAssert(containsModels.count > 0)
        XCTAssert(containsModels.allSatisfy { $0.stringField.contains("Value") })
        
        // Test endsWith
        let endsWithModels = try await getFilteredItems(.field("stringField", "ew", "_A"))
        XCTAssert(endsWithModels.count > 0)
        XCTAssert(endsWithModels.allSatisfy { $0.stringField.hasSuffix("_A") })
        
        // Test notEndsWith
        let notEndsWithModels = try await getFilteredItems(.field("stringField", "new", "_A"))
        XCTAssert(notEndsWithModels.count > 0)
        XCTAssert(notEndsWithModels.allSatisfy { !$0.stringField.hasSuffix("_A") })
    }

    func testRangeOperations() async throws {
        // Test between
        let betweenModels = try await getFilteredItems(.field("intField", "between", [5, 15]))
        XCTAssert(betweenModels.count > 0)
        XCTAssert(betweenModels.allSatisfy { $0.intField > 5 && $0.intField < 15 })
        
        // Test betweenInclusive
        let betweenInclusiveModels = try await getFilteredItems(.field("intField", "betweenInclusive", [5, 15]))
        XCTAssert(betweenInclusiveModels.count > 0)
        XCTAssert(betweenInclusiveModels.allSatisfy { $0.intField >= 5 && $0.intField <= 15 })
    }
    
    func testNullChecks() async throws {
        // Test empty
        let emptyModels = try await getFilteredItems(.field("optionalStringField", "isNull", true))
        XCTAssert(emptyModels.count == 10)
        
        // Test notEmpty
        let notEmptyModels = try await getFilteredItems(.field("optionalStringField", "isNotNull", true))
        XCTAssert(notEmptyModels.count == 3)
    }

}
