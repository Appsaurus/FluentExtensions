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
        
        // Test Open-ended
        let lessThanModels = try await getFilteredItems(.field("intField", "between", [nil, 15]))
        XCTAssert(lessThanModels.count > 0)
        XCTAssert(lessThanModels.allSatisfy { $0.intField < 15 })
        
        let greaterThanModels = try await getFilteredItems(.field("intField", "between", [15, nil]))
        XCTAssert(greaterThanModels.count > 0)
        XCTAssert(greaterThanModels.allSatisfy { $0.intField > 15 })
        
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

    func testDateOperations() async throws {
        let baseDate = Date()
        let oneYear: TimeInterval = 365 * 24 * 60 * 60
        
        // Test greater than date (should find recent dates)
        let threeYearsAgo = baseDate.addingTimeInterval(-3 * oneYear)
        let recentModels = try await getFilteredItems(.field("dateField", "greaterThan", threeYearsAgo))
        XCTAssert(recentModels.count > 0)
        XCTAssert(recentModels.allSatisfy { $0.dateField > threeYearsAgo })
        
        // Test less than date (should find older dates)
        let fiveYearsAgo = baseDate.addingTimeInterval(-5 * oneYear)
        let olderModels = try await getFilteredItems(.field("dateField", "lessThan", fiveYearsAgo))
        XCTAssert(olderModels.count > 0)
        XCTAssert(olderModels.allSatisfy { $0.dateField < fiveYearsAgo })
        
        // Test date range with between
        let startDate = baseDate.addingTimeInterval(-4 * oneYear)
        let endDate = baseDate.addingTimeInterval(-2 * oneYear)
        let rangeModels = try await getFilteredItems(.field("dateField", "between", [startDate, endDate]))
        XCTAssert(rangeModels.count > 0)
        XCTAssert(rangeModels.allSatisfy { $0.dateField > startDate && $0.dateField < endDate })
        
        // Test optional date field presence
        let nonNullDateModels = try await getFilteredItems(.field("optionalDateField", "isNotNull", true))
        XCTAssertEqual(nonNullDateModels.count, 5)
        
        // Test optional date field range
        let futureDate = baseDate.addingTimeInterval(oneYear)
        let futureDateModels = try await getFilteredItems(
            .and([
                .field("optionalDateField", "isNotNull", true),
                .field("optionalDateField", "greaterThan", futureDate)
            ])
        )
        XCTAssert(futureDateModels.count > 0)
        XCTAssert(futureDateModels.allSatisfy { $0.optionalDateField?.timeIntervalSince(futureDate) ?? 0 > 0 })
        
        // Test complex date conditions
        let complexModels = try await getFilteredItems(
            .or([
                .and([
                    .field("dateField", "greaterThan", threeYearsAgo),
                    .field("optionalDateField", "isNotNull", true)
                ]),
                .field("dateField", "lessThan", fiveYearsAgo)
            ])
        )
        XCTAssert(complexModels.count > 0)
        XCTAssert(complexModels.allSatisfy { model in
            (model.dateField > threeYearsAgo && model.optionalDateField != nil) ||
            model.dateField < fiveYearsAgo
        })
    }
}
