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

extension KitchenSink: Parameter {
//    public static var parameter: String {
//        "id"
//    }
}

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
        router.get(basePath, KitchenSink.pathComponent) { (req: Request, kitchenSink: KitchenSink) -> Future<KitchenSink> in
            return req.toFuture(kitchenSink)
        }

        for route in app.routes.all {
            debugPrint(route.path.string)
        }

    }

    func testModelParameterRoute() throws {
        let id = try KitchenSink.query(on: app.db).first().assertExists().wait().requireID()
        try app.test(.GET, "\(basePath)/\(id)") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(id, try response.content.decode(KitchenSink.self).requireID())
        }
    }

    func testSubsetQueries() throws {

    }

//    func applyFilter(for property: PropertyInfo, to query: QueryBuilder<M.Database, M>, on request: Request) throws {
//        let parameter: String = property.name
//        if let queryFilter = try? request.stringKeyPathFilter(for: property.name, at: parameter) {
//            let _ = try? query.filter(queryFilter)
////            if property.type == Bool.self {
////                let _ = try? query.filterAsBool(queryFilter)
////            }
////            else  {
////                let _ = try? query.filter(queryFilter)
////            }
//        }
//    }
}


