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
        try controller.registerRoutes(routes: router)
    }
    
    // Helper function to create filter URL
    func makeFilterURL(_ condition: TestFilterCondition) throws -> String {
        return "\(basePath)?filter=\(try condition.toURLQueryString())"
    }
    
    func getFilteredItems(_ condition: TestFilterCondition) async throws -> [KitchenSink] {
        let response = try await app.sendRequest(.GET, try makeFilterURL(condition))
        XCTAssertEqual(response.status, .ok)
        return try response.content.decode(Page<KitchenSink>.self).items
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
            .field("booleanField", "eq", true),
            .or([
                .field("intField", "gt", 10),
                .field("doubleField", "lt", 5.0)
            ])
        ]))
        XCTAssert(models.allSatisfy { $0.booleanField && ($0.intField > 10 || $0.doubleField < 5.0) })
    }

    func testMultipleFieldTypes() async throws {
        let models = try await getFilteredItems(.and([
            .field("stringField", "sw", "String"),
            .field("intField", "gte", 10),
            .field("booleanField", "eq", true)
        ]))
        XCTAssert(models.allSatisfy { $0.stringField.starts(with: "String") && $0.intField >= 10 && $0.booleanField })
    }

    func testNestedFields() async throws {
        let models = try await getFilteredItems(.field("groupedFields_intField", "gt", 5))
        XCTAssert(models.allSatisfy { $0.groupedFields.intField > 5 })
    }
    
    
}

// Helper structures to represent filter conditions
enum TestFilterCondition: Encodable {
    case field(_ field: String, _ method: String, _ value: AnyCodable)
    case and([TestFilterCondition])
    case or([TestFilterCondition])
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .field(let field, let method, let value):
            try container.encode(field, forKey: .field)
            try container.encode(method, forKey: .method)
            try container.encode(value, forKey: .value)
        case .and(let conditions):
            try container.encode(conditions, forKey: .and)
        case .or(let conditions):
            try container.encode(conditions, forKey: .or)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case field, method, value, and, or
    }
    
    func toURLQueryString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}
