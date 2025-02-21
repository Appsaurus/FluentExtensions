//
//  QueryParameterFilterPostgreSQLTests.swift
//
//
//  Created by Brian Strobach on 2/21/25.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import Codability
import FluentExtensions
import XCTVaporExtensions
@testable import FluentTestModels

class QueryParameterFilterPostgreSQLTests: FluentTestModels.TestCase {
    
    let basePath = "kitchen-sinks"
    
    
    //Skipping by blacklisting all testable enviornemnts until database can be setup locally
    override var validInvocationEnvironments: [Environment] {
        return []
    }

    
    override func configureTestModelDatabase(_ databases: Databases) {
        //TODO: Setup test PostgreSQL database, just skipping for now
    }
    
    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterTestSeeder())
    }
    
    func getFilteredKitchenSinks(_ condition: TestFilterCondition) async throws -> [KitchenSink] {
        try await self.getFilteredItems(basePath: basePath, condition)
    }
    
    func testPostgresStringArrayOperations() async throws {
        // Test contains all for string array
        let containsAllStrings = try await getFilteredKitchenSinks(.field("stringArrayField", "ca", ["value1", "value2"]))
        XCTAssert(containsAllStrings.count > 0)
        XCTAssert(containsAllStrings.allSatisfy {
            $0.stringArrayField.contains("value1") && $0.stringArrayField.contains("value2")
        })
        
        // Test contains any for string array
        let containsAnyStrings = try await getFilteredKitchenSinks(.field("stringArrayField", "cany", ["value1", "nonexistent"]))
        XCTAssert(containsAnyStrings.count > 0)
        XCTAssert(containsAnyStrings.allSatisfy { $0.stringArrayField.contains("value1") })
    }
    
    func testPostgresIntArrayOperations() async throws {
        // Test contains all for int array
        let containsAllInts = try await getFilteredKitchenSinks(.field("intArrayField", "ca", [1, 2]))
        XCTAssert(containsAllInts.count > 0)
        XCTAssert(containsAllInts.allSatisfy {
            $0.intArrayField.contains(1) && $0.intArrayField.contains(2)
        })
        
        // Test empty array
        let emptyIntArray = try await getFilteredKitchenSinks(.field("intArrayField", "ca", []))
        XCTAssert(emptyIntArray.count > 0)
        XCTAssert(emptyIntArray.allSatisfy { $0.intArrayField.isEmpty })
    }
    
    func testPostgresBooleanArrayOperations() async throws {
        // Test contains all for boolean array
        let containsAllBools = try await getFilteredKitchenSinks(.field("booleanArrayField", "ca", [true, false]))
        XCTAssert(containsAllBools.count > 0)
        XCTAssert(containsAllBools.allSatisfy {
            $0.booleanArrayField.contains(true) && $0.booleanArrayField.contains(false)
        })
    }
    
    func testPostgresEnumArrayOperations() async throws {
        // Test contains all for enum array
        let containsAllEnums = try await getFilteredKitchenSinks(.field("stringEnumArray", "ca", [TestStringEnum.case1, TestStringEnum.case2]))
        XCTAssert(containsAllEnums.count > 0)
        XCTAssert(containsAllEnums.allSatisfy {
            $0.stringEnumArray.contains(.case1) && $0.stringEnumArray.contains(.case2)
        })
        
        // Test complex enum array condition
        let complexEnumArray = try await getFilteredKitchenSinks(.and([
            .field("stringEnumArray", "cany", [TestStringEnum.case1]),
            .field("booleanField", "eq", true)
        ]))
        XCTAssert(complexEnumArray.count > 0)
        XCTAssert(complexEnumArray.allSatisfy {
            $0.stringEnumArray.contains(.case1) && $0.booleanField
        })
    }

    func testPostgresArrayContainsAll() async throws {
        // Test contains all for string array
        let containsAllStrings = try await getFilteredKitchenSinks(.field("stringArrayField", "ca", ["value1", "value2"]))
        XCTAssert(containsAllStrings.count > 0)
        XCTAssert(containsAllStrings.allSatisfy {
            $0.stringArrayField.contains("value1") && $0.stringArrayField.contains("value2")
        })
    }
    
    func testPostgresArrayContainsSome() async throws {
        // Test contains any for string array
        let containsAnyStrings = try await getFilteredKitchenSinks(.field("stringArrayField", "cany", ["value1", "nonexistent"]))
        XCTAssert(containsAnyStrings.count > 0)
        XCTAssert(containsAnyStrings.allSatisfy { $0.stringArrayField.contains("value1") })
    }
    
    func testPostgresArrayIsContainedBy() async throws {
        // Test array is contained by
        let isContainedBy = try await getFilteredKitchenSinks(.field("intArrayField", "cb", [1, 2, 3, 4, 5]))
        XCTAssert(isContainedBy.count > 0)
        XCTAssert(isContainedBy.allSatisfy { Set($0.intArrayField).isSubset(of: [1, 2, 3, 4, 5]) })
    }
}
