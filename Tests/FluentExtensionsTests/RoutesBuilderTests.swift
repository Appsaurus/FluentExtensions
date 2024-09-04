//
//  RoutesBuilderTests.swift
//
//
//  Created by Brian Strobach on 9/7/21.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import VaporExtensions
@testable import FluentTestModels

class RoutesBuilderTests: FluentTestModels.TestCase {
    let valueA = "StringValue_A"
    let valueB = "StringValue_B"
    let valueC = "StringValue_C"
    let basePath = "kitchen-sink"

    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    override func addConfiguration(to app: Application) throws {
        try super.addConfiguration(to: app)
        app.logger.logLevel = .error
    }

    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterTestSeeder())
    }

    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        router.get(basePath, KitchenSink.pathComponent) { (req: Request, kitchenSink: KitchenSink) async throws -> KitchenSink in
            return kitchenSink
        }
    }

    func testModelParameterRoute() async throws {
        let id = try await KitchenSink.query(on: app.db).first().assertExists().requireID()
        let response = try await app.sendRequest(.GET, "\(basePath)/\(id)")
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(id, try response.content.decode(KitchenSink.self).requireID())
    }
}


