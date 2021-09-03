//
//  ReflectableMigrationTests.swift
//  
//
//  Created by Brian Strobach on 8/27/21.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import FluentTestUtils
@testable import FluentTestModels

final class ReflectableMigrationTests: FluentTestModelsTests {
    override var useReflectionMigrations: Bool {
        true
    }
}
