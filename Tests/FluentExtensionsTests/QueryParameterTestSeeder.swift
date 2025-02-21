//
//  QueryParameterTestSeeder.swift
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
@testable import FluentTestModels

class QueryParameterTestSeeder: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await seedModels(on: database)
    }
    
    func revert(on database: Database) async throws {
        // No-op
    }
    
    func seedModels(on database: Database) async throws {
        var kitchenSinks: [KitchenSink] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        // Predefined test values
        let stringArrayValues = [
            ["value1", "value2"],
            ["value1", "value2", "value3"],
            ["value2", "value3"],
            ["value1"],
            []
        ]
        
        let intArrayValues = [
            [1, 2, 3],
            [4, 5],
            [6],
            [],
            [7, 8, 9, 10]
        ]
        
        let boolArrayValues = [
            [true, false],
            [true, true],
            [false, false],
            [true],
            []
        ]
        
        let enumArrayValues = [
            [TestStringEnum.case1, TestStringEnum.case2],
            [TestStringEnum.case2, TestStringEnum.case3],
            [TestStringEnum.case1],
            [],
            [TestStringEnum.case1, TestStringEnum.case2, TestStringEnum.case3]
        ]
        
        for (index, letter) in letters.enumerated() {
            let createUser = KitchenSink()
            createUser.stringField += "_\(letter)"
            createUser.intField = index
            createUser.doubleField = Double(index)
            createUser.optionalStringField = index < 3 ? String(letter) : nil
            createUser.booleanField = index % 2 == 0
            createUser.groupedFields.intField = index
            
            // Assign array values cyclically
            createUser.stringArrayField = stringArrayValues[index % stringArrayValues.count]
            createUser.intArrayField = intArrayValues[index % intArrayValues.count]
            createUser.booleanArrayField = boolArrayValues[index % boolArrayValues.count]
            createUser.stringEnumArray = enumArrayValues[index % enumArrayValues.count]
            
            kitchenSinks.append(createUser)
        }
        try await kitchenSinks.create(on: database)
    }
}
