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
        for (index, letter) in letters.enumerated() {
            let createUser = KitchenSink()
            createUser.stringField += "_\(letter)"
            createUser.intField = index
            createUser.doubleField = Double(index)
            createUser.optionalStringField = index < 3 ? String(letter) : nil
            createUser.booleanField = index % 2 == 0
            createUser.groupedFields.intField = index
            kitchenSinks.append(createUser)
        }
        try await kitchenSinks.create(on: database)
    }
}
