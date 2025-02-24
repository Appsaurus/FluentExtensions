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
        
        // Base date for testing (current date)
        let baseDate = Date()
        let oneYear: TimeInterval = 365 * 24 * 60 * 60 // One year in seconds
        
        for (index, letter) in letters.enumerated() {
            let model = KitchenSink()
            model.stringField += "_\(letter)"
            model.intField = index
            model.doubleField = Double(index)
            model.optionalStringField = index < 3 ? String(letter) : nil
            model.booleanField = index % 2 == 0
            model.groupedFields.intField = index
            
            // Assign array values cyclically
            model.stringArrayField = stringArrayValues[index % stringArrayValues.count]
            model.intArrayField = intArrayValues[index % intArrayValues.count]
            model.booleanArrayField = boolArrayValues[index % boolArrayValues.count]
            model.stringEnumArray = enumArrayValues[index % enumArrayValues.count]
            
            // Add dates going backwards in time (1 year per index)
            model.dateField = baseDate.addingTimeInterval(-oneYear * Double(index))
            
            // Optional dates: first 5 entries get dates (2 years after their dateField)
            model.optionalDateField = index < 5 ?
                model.dateField.addingTimeInterval(2 * oneYear) : nil
            
            kitchenSinks.append(model)
        }
        try await kitchenSinks.create(on: database)
    }
}
